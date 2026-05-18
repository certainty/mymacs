;;; org-tsk.el --- TSK ranking algorithm for Org agenda -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Ports the tsk CLI ranking algorithm to org-mode headings.  Provides
;; scored agenda views (agenda, today, all, archived) and interactive
;; commands for boosting and marking tasks as "today".
;;
;; Depends on writing-gtd.el being loaded first.
;;
;;; Code:

(require 'org)
(require 'org-agenda)
(require 'cl-lib)
(require 'cl-macs)
(require 'subr-x)

;;; Configuration

(defgroup org-tsk nil
  "TSK ranking algorithm for Org agenda."
  :prefix "org-tsk-"
  :group 'org-agenda)

(defcustom org-tsk-weight-urgency 10.0
  "Weight for deadline urgency in composite score."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-weight-importance 5.0
  "Weight for importance (priority A) in composite score."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-weight-boost 3.0
  "Weight for boost value in composite score."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-weight-age 1.0
  "Weight for task age in composite score."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-urgency-starts-at 14
  "Days before deadline when urgency starts rising."
  :type 'integer
  :group 'org-tsk)

(defcustom org-tsk-urgency-full-at 1
  "Days before deadline when urgency is nearly 1.0."
  :type 'integer
  :group 'org-tsk)

(defcustom org-tsk-overdue-coefficient 0.1
  "Urgency coefficient per day overdue."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-schedule-visible-at 14
  "Days before scheduled date when tasks start appearing."
  :type 'integer
  :group 'org-tsk)

(defcustom org-tsk-boost-half-life 3.0
  "Days for a boost to decay to half strength."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-boost-increment 1.0
  "Score added per boost action."
  :type 'float
  :group 'org-tsk)

(defcustom org-tsk-age-horizon 90
  "Days until age contribution saturates at 1.0."
  :type 'integer
  :group 'org-tsk)

(defcustom org-tsk-viewport 30
  "Maximum tasks shown in ranked section of agenda."
  :type 'integer
  :group 'org-tsk)

(defcustom org-tsk-active-states '("INBOX" "NEXT" "TODO" "WAIT" "BLOCKED" "PROJ")
  "TODO keywords considered active (appear in agenda)."
  :type '(repeat string)
  :group 'org-tsk)

(defcustom org-tsk-done-states '("DONE" "CANCELLED")
  "TODO keywords considered terminal (appear in archive view)."
  :type '(repeat string)
  :group 'org-tsk)

;;; Score cache

(defvar org-tsk--score-cache (make-hash-table :test 'equal :weakness 'key)
  "Cache of heading -> score.  Cleared on agenda rebuild.")

(defun org-tsk--clear-cache ()
  "Clear the score cache."
  (clrhash org-tsk--score-cache))

;;; Scoring engine

(defun org-tsk--sigmoid (x k midpoint)
  "Logistic sigmoid: 1 / (1 + e^(k*(x - midpoint)))."
  (/ 1.0 (+ 1.0 (exp (* k (- x midpoint))))))

(defun org-tsk--compute-urgency (deadline)
  "Compute urgency score based on DEADLINE time value."
  (let* ((now (float-time))
         (due (float-time deadline))
         (days (/ (- due now) 86400.0)))
    (if (> days 0)
        (let* ((midpoint (/ (+ org-tsk-urgency-starts-at org-tsk-urgency-full-at) 2.0))
               (k (/ (log 99.0) (- org-tsk-urgency-starts-at midpoint))))
          (org-tsk--sigmoid days k midpoint))
      (let ((days-overdue (/ (- now due) 86400.0)))
        (* days-overdue org-tsk-overdue-coefficient)))))

(defun org-tsk--compute-importance ()
  "Compute importance score: 1.0 if priority A, else 0.0."
  (if (equal (org-entry-get (point) "PRIORITY") "A") 1.0 0.0))

(defun org-tsk--compute-boost ()
  "Compute boost score from BOOST_VALUE and BOOST_UPDATED properties."
  (let ((value (org-entry-get (point) "BOOST_VALUE"))
        (updated (org-entry-get (point) "BOOST_UPDATED")))
    (if (and value updated)
        (let* ((bv (string-to-number value))
               (ts (org-parse-time-string updated))
               (updated-time (float-time (encode-time ts)))
               (elapsed-days (/ (- (float-time) updated-time) 86400.0))
               (lambda (/ (log 2.0) org-tsk-boost-half-life)))
          (* bv (exp (* (- lambda) elapsed-days))))
      0.0)))

(defun org-tsk--compute-age ()
  "Compute age score from CAPTURED property.  Saturates at org-tsk-age-horizon."
  (let ((captured (or (org-entry-get (point) "CAPTURED")
                     (org-entry-get (point) "CREATED"))))
    (if captured
        (let* ((ts (org-parse-time-string captured))
               (captured-time (float-time (encode-time ts)))
               (age-days (/ (- (float-time) captured-time) 86400.0)))
          (min 1.0 (/ age-days org-tsk-age-horizon)))
      0.0)))

(defun org-tsk--schedule-multiplier ()
  "Compute schedule multiplier.  Suppresses future-scheduled tasks."
  (let ((scheduled (org-entry-get (point) "SCHEDULED")))
    (if (and scheduled (string-match org-ts-regexp scheduled))
        (let* ((ts (org-parse-time-string scheduled))
               (sched-time (float-time (encode-time ts)))
               (days (/ (- sched-time (float-time)) 86400.0)))
          (if (> days 0)
              (let* ((midpoint (/ org-tsk-schedule-visible-at 2.0))
                     (k (/ (log 99.0) (- org-tsk-schedule-visible-at midpoint))))
                (org-tsk--sigmoid days k midpoint))
            1.0))
      1.0)))

(defun org-tsk-compute-score ()
  "Compute the composite TSK score for the heading at point."
  (let* ((deadline (org-entry-get (point) "DEADLINE"))
         (urgency (if (and deadline (string-match org-ts-regexp deadline))
                      (org-tsk--compute-urgency (encode-time (org-parse-time-string deadline)))
                    0.0))
         (importance (org-tsk--compute-importance))
         (boost (org-tsk--compute-boost))
         (age (org-tsk--compute-age))
         (sched-mult (org-tsk--schedule-multiplier))
         (composite (+ (* org-tsk-weight-urgency urgency)
                       (* org-tsk-weight-importance importance)
                       (* org-tsk-weight-boost boost)
                       (* org-tsk-weight-age age))))
    (* sched-mult composite)))

(defun org-tsk-score-for-marker (marker)
  "Compute TSK score for heading at MARKER, using cache."
  (let ((cached (gethash marker org-tsk--score-cache)))
    (or cached
        (org-with-point-at marker
          (let ((score (org-tsk-compute-score)))
            (puthash marker score org-tsk--score-cache)
            score)))))

(defun org-tsk-compare-by-score (a b)
  "Compare two agenda entries by TSK score, descending."
  (let* ((ma (get-text-property 0 'org-marker a))
         (mb (get-text-property 0 'org-marker b))
         (sa (if ma (org-tsk-score-for-marker ma) 0.0))
         (sb (if mb (org-tsk-score-for-marker mb) 0.0)))
    (cond ((> sa sb) +1)
          ((< sa sb) -1)
          (0))))

;;; Interactive commands

(defun +tsk-boost ()
  "Boost the task at point.  Increments BOOST_VALUE and updates BOOST_UPDATED."
  (interactive)
  (let ((marker (or (get-text-property (point) 'org-hd-marker)
                    (get-text-property (point) 'org-marker))))
    (if marker
        (org-with-point-at marker
          (let ((current (or (org-entry-get (point) "BOOST_VALUE") "0")))
            (org-entry-put (point) "BOOST_VALUE"
                          (number-to-string (+ org-tsk-boost-increment
                                               (string-to-number current))))
            (org-entry-put (point) "BOOST_UPDATED"
                          (format-time-string "[%Y-%m-%d %a %H:%M]")
                          )
            (save-buffer)))
      (when (derived-mode-p 'org-mode)
        (let ((current (or (org-entry-get (point) "BOOST_VALUE") "0")))
          (org-entry-put (point) "BOOST_VALUE"
                        (number-to-string (+ org-tsk-boost-increment
                                             (string-to-number current))))
          (org-entry-put (point) "BOOST_UPDATED"
                        (format-time-string "[%Y-%m-%d %a %H:%M]")
                        )
          (save-buffer))))
  (when (derived-mode-p 'org-agenda-mode)
    (org-agenda-redo)))

(defun +tsk-today-toggle ()
  "Toggle the :today: tag on the current item."
  (interactive)
  (if (derived-mode-p 'org-agenda-mode)
      (let ((marker (or (get-text-property (point) 'org-hd-marker)
                        (get-text-property (point) 'org-marker))))
        (unless marker (user-error "No Org item at point"))
        (org-with-point-at marker
          (org-toggle-tag "today" 'toggle)
          (save-buffer))
        (org-agenda-redo))
    (org-toggle-tag "today" 'toggle)
    (save-buffer)))

;;; Agenda views

(defun org-tsk--active-states-match ()
  "Build org-match string for active TODO states."
  (mapconcat (lambda (s) (concat "TODO=\"" s "\"")) org-tsk-active-states "|"))

(defun org-tsk--done-states-match ()
  "Build org-match string for done TODO states."
  (mapconcat (lambda (s) (concat "TODO=\"" s "\"")) org-tsk-done-states "|"))

(defun org-tsk--setup-agenda-commands ()
  "Append TSK agenda commands to `org-agenda-custom-commands'."
  (let ((todo-skip-done '(org-agenda-skip-entry-if 'todo 'done))
        (todo-skip-if-scheduled '(org-agenda-skip-entry-if 'scheduled 'deadline)))
    (add-to-list
     'org-agenda-custom-commands
     '("t" "TSK Agenda"
       ((tags-todo "+today"
         ((org-agenda-overriding-header "Today\n")
          (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
          (org-agenda-sorting-strategy '(user-defined-down))
          (org-agenda-cmp-user-defined #'org-tsk-compare-by-score)
          (org-agenda-max-entries org-tsk-viewport)
          (org-agenda-prefix-format "  ")))
        (agenda ""
         ((org-agenda-overriding-header "\nOverdue / Due\n")
          (org-agenda-entry-types '(:deadline))
          (org-agenda-span 1)
          (org-agenda-sorting-strategy '(user-defined-down))
          (org-agenda-cmp-user-defined #'org-tsk-compare-by-score)
          (org-agenda-prefix-format "  ")))
        (tags-todo (org-tsk--active-states-match)
         ((org-agenda-overriding-header "\nRanked\n")
          (org-agenda-skip-function
           '(or (org-agenda-skip-entry-if 'todo 'done)
                (org-agenda-skip-entry-if 'regexp ":today:")))
          (org-agenda-sorting-strategy '(user-defined-down))
          (org-agenda-cmp-user-defined #'org-tsk-compare-by-score)
          (org-agenda-max-entries org-tsk-viewport)
          (org-agenda-prefix-format "  "))))))

    (add-to-list
     'org-agenda-custom-commands
     '("T" "TSK Today"
       ((tags-todo "+today"
         ((org-agenda-overriding-header "Today\n")
          (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
          (org-agenda-sorting-strategy '(user-defined-down))
          (org-agenda-cmp-user-defined #'org-tsk-compare-by-score)
          (org-agenda-prefix-format "  "))))))

    (add-to-list
     'org-agenda-custom-commands
     '("ta" "TSK All"
       ((todo (mapconcat #'identity org-tsk-active-states "|")
         ((org-agenda-overriding-header "All Active\n")
          (org-agenda-sorting-strategy '(user-defined-down))
          (org-agenda-cmp-user-defined #'org-tsk-compare-by-score)
          (org-agenda-prefix-format "  "))))))

    (add-to-list
     'org-agenda-custom-commands
     '("tr" "TSK Archive"
       ((todo (mapconcat #'identity org-tsk-done-states "|")
         ((org-agenda-overriding-header "Archive\n")
          (org-agenda-prefix-format "  "))))))))

(defun +tsk-agenda ()
  "Show the TSK agenda view."
  (interactive)
  (org-tsk--clear-cache)
  (org-agenda nil "t"))

(defun +tsk-today ()
  "Show the TSK Today view."
  (interactive)
  (org-tsk--clear-cache)
  (org-agenda nil "T"))

(defun +tsk-all ()
  "Show all active tasks sorted by TSK score."
  (interactive)
  (org-tsk--clear-cache)
  (org-agenda nil "ta"))

(defun +tsk-archived ()
  "Show completed and cancelled tasks."
  (interactive)
  (org-agenda nil "tr"))

;;; Keybindings

(with-eval-after-load 'core-keys
  (keymap-set '+org "t" #'+tsk-agenda)
  (keymap-set '+org "T" #'+tsk-today)
  (keymap-set '+org "b" #'+tsk-boost))

;;; Initialization

(org-tsk--setup-agenda-commands)

(add-hook 'org-agenda-redo-functions #'org-tsk--clear-cache)

(provide 'org-tsk)
;;; org-tsk.el ends here