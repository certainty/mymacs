;;; taskwarrior.el --- Persistent Taskwarrior task list -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0"))
;;; Commentary:
;; A persistent, markable Taskwarrior interface built on tabulated-list-mode.
;;; Code:

(require 'ansi-color)
(require 'calendar)
(require 'cl-lib)
(require 'subr-x)
(require 'tabulated-list)
(require 'taskwarrior-core)
(require 'transient)

(defgroup taskwarrior-list nil
  "Persistent Taskwarrior task lists."
  :group 'taskwarrior)

(defcustom taskwarrior-list-default-report "ready"
  "Report shown by `taskwarrior-list'."
  :type 'string
  :group 'taskwarrior-list)

(defcustom taskwarrior-list-task-reports
  '("active" "all" "blocked" "blocking" "completed" "list" "long"
    "ls" "minimal" "newest" "next" "overdue" "ready" "recurring"
    "unblocked" "waiting")
  "Reports that display tasks and support task operations.
Unknown reports are read-only unless added to this list."
  :type '(repeat string)
  :group 'taskwarrior-list)

(defconst taskwarrior-list-read-only-reports
  '("calendar" "stats" "summary" "timesheet")
  "Built-in reports that are displayed read-only.
Other graph and metadata reports are also read-only by default.")

(defface taskwarrior-list-highlight-face
  '((t :inherit success :weight semi-bold))
  "Face for tasks carrying one of `taskwarrior-list-highlight-tags'."
  :group 'taskwarrior-list)

(defcustom taskwarrior-list-highlight-tags '("next")
  "Tags whose tasks should use `taskwarrior-list-highlight-face'.
Tag names may optionally include Taskwarrior's leading plus sign."
  :type '(repeat string)
  :group 'taskwarrior-list)

(defcustom taskwarrior-list-columns
  '(("ID" "id" 5 t)
    ("Urg" "urgency" 6 t)
    ("Project" "project" 16 t)
    ("Due" "due" 12 t)
    ("Tags" "tags" 18 t)
    ("Description" "description" 0 t))
  "Columns displayed in Taskwarrior list buffers.
Each entry is (HEADER FIELD WIDTH SORT), where FIELD is a key in the
Taskwarrior JSON export.  WIDTH zero means use the remaining space."
  :type '(repeat (list (string :tag "Header")
                       (string :tag "JSON field")
                       (integer :tag "Width")
                       (boolean :tag "Sortable")))
  :group 'taskwarrior-list)

(defconst taskwarrior-list-buffer-name "*Taskwarrior*"
  "Name of the persistent Taskwarrior list buffer.")

(defconst taskwarrior-list-detail-buffer-name "*Taskwarrior Task*"
  "Name of the Taskwarrior detail buffer.")

(defconst taskwarrior-report-buffer-name "*Taskwarrior Report*"
  "Name of the read-only Taskwarrior report buffer.")

(defcustom taskwarrior-list-popup-height 0.33
  "Fraction of the frame height used by Taskwarrior popup windows."
  :type 'number
  :group 'taskwarrior-list)

(defvar-local taskwarrior-list-report nil)
(defvar-local taskwarrior-list-filters nil)
(defvar-local taskwarrior-list--tasks nil)
(defvar-local taskwarrior-list--tasks-by-uuid nil)
(defvar-local taskwarrior-list--marks nil)
(defvar-local taskwarrior-list--context nil)
(defvar-local taskwarrior-list-calendar-source-buffer nil)
(defvar-local taskwarrior-list-calendar-field nil)
(defvar-local taskwarrior-list--information-uuid nil)
(defvar-local taskwarrior-report-name nil)
(defvar-local taskwarrior-report-filters nil)

(defun taskwarrior-list--popup-action ()
  "Return the display action for Taskwarrior popup windows."
  `((display-buffer-reuse-window display-buffer-at-bottom)
    (window-height . ,taskwarrior-list-popup-height)
    (window-parameters
     (no-other-window . t)
     (no-delete-other-windows . t))))

(defconst taskwarrior-list--display-regexp
  "\\*Taskwarrior\\(?: Report\\| Task\\)?\\*"
  "Regexp matching Taskwarrior list and report buffers.")

(defun taskwarrior-list--install-display-rule ()
  "Put the Taskwarrior popup rule before catch-all rules."
  (setq display-buffer-alist
        (cons (cons taskwarrior-list--display-regexp
                    (taskwarrior-list--popup-action))
              (cl-remove-if
               (lambda (entry)
                 (equal (car entry) taskwarrior-list--display-regexp))
               display-buffer-alist))))

(defun taskwarrior-list--pop-to-buffer (buffer)
  "Display and select Taskwarrior BUFFER in its popup window."
  (taskwarrior-list--install-display-rule)
  (pop-to-buffer buffer (taskwarrior-list--popup-action)))

(defun taskwarrior-list--format-filter (filters)
  "Format FILTERS for display."
  (if filters
      (mapconcat (lambda (filter)
                   (if (string-match-p "[[:space:]'\"\\\\]" filter)
                       (shell-quote-argument filter)
                     filter))
                 filters " ")
    "none"))

(defun taskwarrior-list--task-report-p (report)
  "Return non-nil when REPORT supports task-list operations."
  (member report taskwarrior-list-task-reports))

(defun taskwarrior-list--report-candidates ()
  "Return built-in and configured Taskwarrior report names."
  (delete-dups
   (append (taskwarrior-reports)
           taskwarrior-list-task-reports
           taskwarrior-list-read-only-reports
           '("burndown.daily" "burndown.monthly" "burndown.weekly"
             "ghistory.annual" "ghistory.monthly"
             "history.annual" "history.daily" "history.monthly"
             "history.weekly"))))

(defun taskwarrior-list--report-annotation (report)
  "Annotate REPORT with its Taskwarrior UI capability."
  (format "  %s" (if (taskwarrior-list--task-report-p report)
                      "tasks"
                    "read-only")))

(defun taskwarrior-list--current-report ()
  "Return the report associated with the current Taskwarrior buffer."
  (if (derived-mode-p 'taskwarrior-report-mode)
      taskwarrior-report-name
    taskwarrior-list-report))

(defun taskwarrior-list--read-report ()
  "Prompt for a Taskwarrior report with a capability annotation."
  (let ((completion-extra-properties
         '(:annotation-function taskwarrior-list--report-annotation)))
    (completing-read "Taskwarrior report: "
                     (taskwarrior-list--report-candidates)
                     nil nil nil nil
                     (taskwarrior-list--current-report))))

(defun taskwarrior-list--mode-line-status ()
  "Return the current Taskwarrior view state for the mode line."
  (format " report:%s filter:%s context:%s tasks:%d marked:%d"
          taskwarrior-list-report
          (taskwarrior-list--format-filter taskwarrior-list-filters)
          (or taskwarrior-list--context "none")
          (length taskwarrior-list--tasks)
          (hash-table-count taskwarrior-list--marks)))

(defun taskwarrior-list--column-format ()
  "Build `tabulated-list-format' from `taskwarrior-list-columns'."
  (vconcat
   (list (list "M" 1 nil))
   (mapcar (lambda (column)
             (list (nth 0 column) (nth 2 column) (nth 3 column)))
           taskwarrior-list-columns)))

(defun taskwarrior-list--date-display (value)
  "Return a compact display string for Taskwarrior date VALUE."
  (if (and (stringp value)
           (string-match "\\`\\([0-9]\\{4\\}\\)\\([0-9]\\{2\\}\\)\\([0-9]\\{2\\}\\)T" value))
      (format "%s-%s-%s" (match-string 1 value)
              (match-string 2 value) (match-string 3 value))
    (format "%s" (or value ""))))

(defun taskwarrior-list--field-display (task field)
  "Format FIELD from TASK for display in the task table."
  (let ((value (gethash field task)))
    (cond
     ((null value) "")
     ((equal field "tags")
      (if (listp value) (string-join value ",") (format "%s" value)))
     ((member field '("due" "scheduled" "wait" "until" "entry" "modified"))
      (taskwarrior-list--date-display value))
     ((numberp value)
      (if (floatp value) (format "%.1f" value) (number-to-string value)))
     ((stringp value) (replace-regexp-in-string "[\n\r]+" " " value))
     (t (format "%s" value)))))

(defun taskwarrior-list--highlighted-p (task)
  "Return non-nil when TASK has a configured highlight tag."
  (let ((tags (gethash "tags" task)))
    (and (listp tags)
         (cl-some (lambda (configured-tag)
                    (member (string-remove-prefix "+" configured-tag) tags))
                  taskwarrior-list-highlight-tags))))

(defun taskwarrior-list--entry (task)
  "Build a tabulated list entry for TASK."
  (let ((uuid (gethash "uuid" task)))
    (unless (and (stringp uuid) (not (string-empty-p uuid)))
      (error "Taskwarrior exported a task without a UUID"))
    (let ((columns
           (vconcat
            (list (if (gethash uuid taskwarrior-list--marks) "*" ""))
            (mapcar (lambda (column)
                      (taskwarrior-list--field-display task (nth 1 column)))
                    taskwarrior-list-columns))))
      (when (taskwarrior-list--highlighted-p task)
        (setq columns
              (vconcat
               (mapcar (lambda (column)
                         (propertize column 'face
                                     'taskwarrior-list-highlight-face))
                       columns))))
      (list uuid columns))))

(defun taskwarrior-list--reload ()
  "Reload the current Taskwarrior report and rebuild table entries."
  (setq taskwarrior-list--tasks
        (taskwarrior-tasks taskwarrior-list-report taskwarrior-list-filters)
        taskwarrior-list--tasks-by-uuid (make-hash-table :test 'equal)
        taskwarrior-list--context (taskwarrior-current-context))
  (dolist (task taskwarrior-list--tasks)
    (puthash (gethash "uuid" task) task taskwarrior-list--tasks-by-uuid))
  (let (stale-marks)
    (maphash (lambda (uuid _marked)
               (unless (gethash uuid taskwarrior-list--tasks-by-uuid)
                 (push uuid stale-marks)))
             taskwarrior-list--marks)
    (dolist (uuid stale-marks)
      (remhash uuid taskwarrior-list--marks)))
  (setq tabulated-list-entries
        (mapcar #'taskwarrior-list--entry taskwarrior-list--tasks))
  (force-mode-line-update))

(defun taskwarrior-list-refresh ()
  "Refresh the current Taskwarrior list, preserving the current task."
  (interactive)
  (setq taskwarrior-list--information-uuid nil)
  (taskwarrior-list--reload)
  (tabulated-list-print t))

(defun taskwarrior-list--uuid-at-point ()
  "Return the task UUID at point or signal a user error."
  (or (tabulated-list-get-id)
      (user-error "No task at point")))

(defun taskwarrior-list--selected-uuids ()
  "Return marked task UUIDs, or the UUID at point when none are marked."
  (let (uuids)
    (maphash (lambda (uuid _marked) (push uuid uuids))
             taskwarrior-list--marks)
    (or (nreverse uuids) (list (taskwarrior-list--uuid-at-point)))))

(defun taskwarrior-list--task-description (uuid)
  "Return a short description for task UUID."
  (let ((task (gethash uuid taskwarrior-list--tasks-by-uuid)))
    (format "%s  %s" (or (gethash "id" task) uuid)
            (or (gethash "description" task) ""))))

(defun taskwarrior-list--confirm (uuids command arguments)
  "Ask to run COMMAND with ARGUMENTS on UUIDS."
  (yes-or-no-p
   (format "%s %d task%s%s with: task <UUID%s> %s%s? "
           (capitalize command) (length uuids)
           (if (= (length uuids) 1) "" "s")
           (if (= (length uuids) 1)
               (format " (%s)" (taskwarrior-list--task-description (car uuids)))
             "")
           (if (= (length uuids) 1) "" "s") command
           (if arguments
               (concat " " (mapconcat #'shell-quote-argument arguments " "))
             ""))))

(defun taskwarrior-list--message-output (output)
  "Display Taskwarrior OUTPUT appropriately."
  (let ((output (string-trim output)))
    (if (string-match-p "\n" output)
        (with-current-buffer (get-buffer-create "*Taskwarrior Output*")
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert output "\n")
            (goto-char (point-min))
            (special-mode))
          (display-buffer (current-buffer)))
      (message "%s" output))))

(defun taskwarrior-list--run-action
    (command &optional arguments no-confirm show-output)
  "Run COMMAND with ARGUMENTS on selected tasks and refresh.
When NO-CONFIRM is non-nil, do not ask for confirmation.  When SHOW-OUTPUT
is non-nil, display command output in the output buffer; otherwise report a
short status message and keep the task list visible."
  (let ((uuids (taskwarrior-list--selected-uuids)))
    (when (or no-confirm
              (taskwarrior-list--confirm uuids command arguments))
      (let ((output (apply #'taskwarrior-run-on uuids command arguments)))
        (if show-output
            (taskwarrior-list--message-output output)
          (message "Taskwarrior: %s %d task%s"
                   command (length uuids)
                   (if (= (length uuids) 1) "" "s"))))
      (taskwarrior-list-refresh))))

(defun taskwarrior-list-toggle-mark ()
  "Toggle the mark on the task at point and advance one line."
  (interactive)
  (let ((uuid (taskwarrior-list--uuid-at-point)))
    (if (gethash uuid taskwarrior-list--marks)
        (remhash uuid taskwarrior-list--marks)
      (puthash uuid t taskwarrior-list--marks))
    (taskwarrior-list-refresh)
    (forward-line 1)))

(defun taskwarrior-list-mark-all ()
  "Mark all tasks in the current view."
  (interactive)
  (dolist (task taskwarrior-list--tasks)
    (puthash (gethash "uuid" task) t taskwarrior-list--marks))
  (taskwarrior-list-refresh))

(defun taskwarrior-list-unmark-all ()
  "Remove every mark in the current view."
  (interactive)
  (clrhash taskwarrior-list--marks)
  (taskwarrior-list-refresh))

(defun taskwarrior-list--close-information-window ()
  "Close the Taskwarrior information window, if it is visible."
  (setq taskwarrior-list--information-uuid nil)
  (when-let* ((window (get-buffer-window taskwarrior-list-detail-buffer-name 0)))
    (quit-window nil window)))

(defun taskwarrior-list--display-information (uuid &optional source-window)
  "Display information for UUID, using SOURCE-WINDOW as its reference."
  (let* ((buffer (get-buffer-create taskwarrior-list-detail-buffer-name))
         (output (taskwarrior-task-information uuid)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (unless (derived-mode-p 'special-mode)
          (special-mode))
        (erase-buffer)
        (insert output)
        (goto-char (point-min))))
    (unless (get-buffer-window buffer 0)
      (let ((display-buffer-overriding-action
             `((display-buffer-in-direction)
               (direction . right)
               (window . ,(or source-window (selected-window)))
               (window-parameters
                (no-other-window . t)
                (no-delete-other-windows . t)))))
        (display-buffer buffer)))))

(defun taskwarrior-list--update-information ()
  "Update visible task information when the task at point changes."
  (when (get-buffer-window taskwarrior-list-detail-buffer-name 0)
    (let ((uuid (tabulated-list-get-id)))
      (when (and uuid
                 (not (equal uuid taskwarrior-list--information-uuid)))
        (setq taskwarrior-list--information-uuid uuid)
        (taskwarrior-list--display-information uuid)))))

(defun taskwarrior-list-information ()
  "Toggle detailed information for the task at point."
  (interactive)
  (if (get-buffer-window taskwarrior-list-detail-buffer-name 0)
      (taskwarrior-list--close-information-window)
    (let ((uuid (taskwarrior-list--uuid-at-point)))
      (taskwarrior-list--display-information uuid (selected-window))
      (setq taskwarrior-list--information-uuid uuid))))

(defun taskwarrior-list-add (input)
  "Add a task using Taskwarrior arguments parsed from INPUT."
  (interactive (list (read-string "New task (description and modifiers): ")))
  (message "%s"
           (string-trim
            (taskwarrior-add (taskwarrior-parse-arguments input))))
  (when (derived-mode-p 'taskwarrior-list-mode)
    (taskwarrior-list-refresh)))

(defun taskwarrior-list-modify (input)
  "Modify selected tasks using arguments parsed from INPUT."
  (interactive (list (read-string "Taskwarrior modifiers: ")))
  (taskwarrior-list--run-action
   "modify" (taskwarrior-parse-arguments input) t))

(defun taskwarrior-list-annotate (annotation)
  "Add ANNOTATION to selected tasks."
  (interactive (list (read-string "Annotation: ")))
  (when (string-empty-p annotation)
    (user-error "Enter an annotation"))
  (taskwarrior-list--run-action "annotate" (list annotation) t))

(defun taskwarrior-list-toggle-next ()
  "Toggle the next tag on selected tasks.
Remove it when every selected task has the tag; otherwise add it to all
selected tasks."
  (interactive)
  (let* ((uuids (taskwarrior-list--selected-uuids))
         (all-next
          (cl-every
           (lambda (uuid)
             (when-let* ((task (gethash uuid taskwarrior-list--tasks-by-uuid)))
               (member "next" (gethash "tags" task))))
           uuids)))
    (taskwarrior-list--run-action
     "modify" (list (if all-next "-next" "+next")) t)))

(defun taskwarrior-list--set-date (field date)
  "Set selected tasks' FIELD to DATE without confirmation."
  (taskwarrior-list--run-action
   "modify" (list (format "%s:%s" field date)) t))

(defun taskwarrior-list-set-date (field date)
  "Set selected tasks' FIELD to DATE."
  (interactive
   (list (completing-read "Date field: "
                          '("due" "scheduled" "wait" "until") nil t)
         (read-string "Taskwarrior date (empty clears): ")))
  (taskwarrior-list--set-date field date))

(defun taskwarrior-list-schedule-today ()
  "Schedule selected tasks for today."
  (interactive)
  (taskwarrior-list--set-date "scheduled" "today"))

(defun taskwarrior-list-schedule-tomorrow ()
  "Schedule selected tasks for tomorrow."
  (interactive)
  (taskwarrior-list--set-date "scheduled" "tomorrow"))

(defun taskwarrior-list-schedule-eow ()
  "Schedule selected tasks for the end of the week."
  (interactive)
  (taskwarrior-list--set-date "scheduled" "eow"))

(defun taskwarrior-list-schedule-eom ()
  "Schedule selected tasks for the end of the month."
  (interactive)
  (taskwarrior-list--set-date "scheduled" "eom"))

(defun taskwarrior-list-schedule-clear ()
  "Clear the schedule of selected tasks."
  (interactive)
  (taskwarrior-list--set-date "scheduled" ""))

(defun taskwarrior-list--calendar-date-string (date)
  "Convert Calendar DATE, a (MONTH DAY YEAR) list, to ISO format."
  (format "%04d-%02d-%02d" (nth 2 date) (nth 0 date) (nth 1 date)))

(defun taskwarrior-list-calendar-select ()
  "Apply the date at point in Calendar to the originating task list."
  (interactive)
  (let ((date (calendar-cursor-to-date t))
        (source taskwarrior-list-calendar-source-buffer)
        (field taskwarrior-list-calendar-field))
    (calendar-exit)
    (when (buffer-live-p source)
      (pop-to-buffer source)
      (taskwarrior-list--set-date field
                                  (taskwarrior-list--calendar-date-string date)))))

(defun taskwarrior-list--calendar-date (field)
  "Open Calendar to select a date for FIELD."
  (let ((source (current-buffer)))
    (calendar)
    (with-current-buffer (calendar-get-buffer)
      (setq-local taskwarrior-list-calendar-source-buffer source
                  taskwarrior-list-calendar-field field)
      (use-local-map (copy-keymap calendar-mode-map))
      (keymap-set (current-local-map) "RET" #'taskwarrior-list-calendar-select)
      (message "Select a date and press RET; q cancels"))))

(defun taskwarrior-list-schedule-custom ()
  "Schedule selected tasks using an Emacs Calendar date."
  (interactive)
  (taskwarrior-list--calendar-date "scheduled"))

(defun taskwarrior-list-deadline-tomorrow ()
  "Set the deadline of selected tasks to tomorrow."
  (interactive)
  (taskwarrior-list--set-date "due" "tomorrow"))

(defun taskwarrior-list-deadline-eow ()
  "Set the deadline of selected tasks to the end of the week."
  (interactive)
  (taskwarrior-list--set-date "due" "eow"))

(defun taskwarrior-list-deadline-eom ()
  "Set the deadline of selected tasks to the end of the month."
  (interactive)
  (taskwarrior-list--set-date "due" "eom"))

(defun taskwarrior-list-deadline-clear ()
  "Clear the deadline of selected tasks."
  (interactive)
  (taskwarrior-list--set-date "due" ""))

(defun taskwarrior-list-deadline-custom ()
  "Set the deadline of selected tasks using an Emacs Calendar date."
  (interactive)
  (taskwarrior-list--calendar-date "due"))

(defun taskwarrior-list-start ()
  "Start selected tasks without confirmation."
  (interactive)
  (taskwarrior-list--run-action "start" nil t))

(defun taskwarrior-list-stop ()
  "Stop selected tasks without confirmation."
  (interactive)
  (taskwarrior-list--run-action "stop" nil t))

(defun taskwarrior-list-done ()
  "Complete selected tasks without confirmation."
  (interactive)
  (taskwarrior-list--run-action "done" nil t))

(defun taskwarrior-list-delete ()
  "Delete selected tasks."
  (interactive)
  (taskwarrior-list--run-action "delete"))

(defun taskwarrior-list-run-command (command input)
  "Run Taskwarrior COMMAND with arguments parsed from INPUT on selected tasks."
  (interactive
   (list (completing-read "Taskwarrior command: " (taskwarrior-commands) nil t)
         (read-string "Command arguments: ")))
  (taskwarrior-list--run-action
   command (taskwarrior-parse-arguments input t) nil t))

(defun taskwarrior-list-undo ()
  "Undo the most recent Taskwarrior change."
  (interactive)
  (when (yes-or-no-p "Undo the most recent Taskwarrior change? ")
    (message "%s" (string-trim (taskwarrior-undo)))
    (taskwarrior-list-refresh)))

(defun taskwarrior-list-set-filter (input)
  "Replace the current report's additional filter using INPUT."
  (interactive
   (list (read-string "Taskwarrior filter: "
                      (taskwarrior-list--format-filter
                       taskwarrior-list-filters))))
  (setq taskwarrior-list-filters
        (if (member input '("" "none"))
            nil
          (taskwarrior-parse-arguments input)))
  (taskwarrior-list-refresh))

(defun taskwarrior-list-select-report (report)
  "Display Taskwarrior REPORT in the appropriate Taskwarrior buffer."
  (interactive (list (taskwarrior-list--read-report)))
  (if (taskwarrior-list--task-report-p report)
      (+taskwarrior-list report nil)
    (+taskwarrior-report report nil)))

(defun taskwarrior-list-select-context (context)
  "Activate CONTEXT and refresh the current view."
  (interactive
   (list (completing-read "Taskwarrior context: "
                          (cons "none" (taskwarrior-contexts)) nil t)))
  (taskwarrior-set-context (unless (equal context "none") context))
  (message "Taskwarrior context: %s" context)
  (taskwarrior-list-refresh))

(defun taskwarrior-report--mode-line-status ()
  "Return the current read-only report state for the mode line."
  (format " report:%s filter:%s"
          taskwarrior-report-name
          (taskwarrior-list--format-filter taskwarrior-report-filters)))

(defun taskwarrior-report-refresh ()
  "Refresh the current read-only Taskwarrior report."
  (interactive)
  (let ((output (apply #'taskwarrior-run
                       (append taskwarrior-report-filters
                               (list taskwarrior-report-name)))))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert output)
      (ansi-color-apply-on-region (point-min) (point-max))
      (goto-char (point-min)))
    (force-mode-line-update)))

(defun taskwarrior-report-set-filter (input)
  "Replace the current read-only report's filter using INPUT."
  (interactive
   (list (read-string "Taskwarrior filter: "
                      (taskwarrior-list--format-filter
                       taskwarrior-report-filters))))
  (setq taskwarrior-report-filters
        (if (member input '("" "none"))
            nil
          (taskwarrior-parse-arguments input)))
  (taskwarrior-report-refresh))

(defvar-keymap taskwarrior-report-mode-map
  :doc "Keymap for read-only Taskwarrior reports."
  :parent special-mode-map
  "g" #'taskwarrior-report-refresh
  "r" #'taskwarrior-list-select-report
  "/" #'taskwarrior-report-set-filter)

(define-derived-mode taskwarrior-report-mode special-mode "Taskwarrior Report"
  "Major mode for read-only Taskwarrior reports."
  (setq-local taskwarrior-report-name nil
              taskwarrior-report-filters nil
              mode-line-process
              '(:eval (taskwarrior-report--mode-line-status)))
  (add-hook 'quit-window-hook
            #'taskwarrior-list--close-information-window nil t))

;;;###autoload
(defun +taskwarrior-report (&optional report filters)
  "Open read-only Taskwarrior REPORT with FILTERS."
  (interactive (list (taskwarrior-list--read-report)))
  (let ((buffer (get-buffer-create taskwarrior-report-buffer-name)))
    (taskwarrior-list--pop-to-buffer buffer)
    (unless (derived-mode-p 'taskwarrior-report-mode)
      (taskwarrior-report-mode))
    (setq taskwarrior-report-name report
          taskwarrior-report-filters filters)
    (taskwarrior-report-refresh)))

(transient-define-prefix taskwarrior-list-schedule-menu ()
  "Schedule selected Taskwarrior tasks."
  [["Schedule"
    ("t" "Tomorrow" taskwarrior-list-schedule-tomorrow)
    ("e" "End of week" taskwarrior-list-schedule-eow)
    ("m" "End of month" taskwarrior-list-schedule-eom)
    ("c" "Clear" taskwarrior-list-schedule-clear)
    ("D" "Custom" taskwarrior-list-schedule-custom)]
   ["Menu"
    ("q" "Quit" transient-quit-one)
    ("<escape>" "Quit" transient-quit-one)]])

(transient-define-prefix taskwarrior-list-deadline-menu ()
  "Set deadlines for selected Taskwarrior tasks."
  [["Deadline"
    ("t" "Tomorrow" taskwarrior-list-deadline-tomorrow)
    ("e" "End of week" taskwarrior-list-deadline-eow)
    ("m" "End of month" taskwarrior-list-deadline-eom)
    ("c" "Clear" taskwarrior-list-deadline-clear)
    ("D" "Custom" taskwarrior-list-deadline-custom)]
   ["Menu"
    ("q" "Quit" transient-quit-one)
    ("<escape>" "Quit" transient-quit-one)]])

(transient-define-prefix taskwarrior-list-dates-menu ()
  "Schedule tasks and set deadlines."
  [["Dates"
    ("s" "Schedule" taskwarrior-list-schedule-menu)
    ("d" "Deadline" taskwarrior-list-deadline-menu)]
   ["Menu"
    ("q" "Quit" transient-quit-one)
    ("<escape>" "Quit" transient-quit-one)]])

(transient-define-prefix taskwarrior-list-dispatch ()
  "Operate on the current Taskwarrior view and selected tasks."
  [["View"
    ("g" "Refresh" taskwarrior-list-refresh)
    ("r" "Report" taskwarrior-list-select-report)
    ("/" "Filter" taskwarrior-list-set-filter)
    ("c" "Context" taskwarrior-list-select-context)
    ("s" "Sort columns" tabulated-list-sort)]
   ["Task"
    ("a" "Add" taskwarrior-list-add)
    ("i" "Information" taskwarrior-list-information)
    ("M" "Modify" taskwarrior-list-modify)
    ("A" "Annotate" taskwarrior-list-annotate)
    ("n" "Toggle next" taskwarrior-list-toggle-next)
    ("d" "Done" taskwarrior-list-done)
    ("x" "Delete" taskwarrior-list-delete)]
   ["State"
    ("b" "Start" taskwarrior-list-start)
    ("B" "Stop" taskwarrior-list-stop)
    ("." "Schedule today" taskwarrior-list-schedule-today)
    (">" "Schedule tomorrow" taskwarrior-list-schedule-tomorrow)
    ("D" "Dates" taskwarrior-list-dates-menu)]
   ["Selection and general"
    ("t" "Toggle mark" taskwarrior-list-toggle-mark)
    ("*" "Mark all" taskwarrior-list-mark-all)
    ("u" "Unmark all" taskwarrior-list-unmark-all)
    ("!" "Run command" taskwarrior-list-run-command)
    ("U" "Undo" taskwarrior-list-undo)]
   ["Menu"
    ("q" "Quit" transient-quit-one)
    ("<escape>" "Quit" transient-quit-one)]])

(defvar-keymap taskwarrior-list-mode-map
  :doc "Keymap for `taskwarrior-list-mode'."
  :parent tabulated-list-mode-map
  "RET" #'taskwarrior-list-information
  "?" #'taskwarrior-list-dispatch
  "g" #'taskwarrior-list-refresh
  "r" #'taskwarrior-list-select-report
  "/" #'taskwarrior-list-set-filter
  "." #'taskwarrior-list-schedule-today
  ">" #'taskwarrior-list-schedule-tomorrow
  "c" #'taskwarrior-list-select-context
  "s" #'tabulated-list-sort
  "a" #'taskwarrior-list-add
  "i" #'taskwarrior-list-information
  "M" #'taskwarrior-list-modify
  "A" #'taskwarrior-list-annotate
  "n" #'taskwarrior-list-toggle-next
  "d" #'taskwarrior-list-done
  "x" #'taskwarrior-list-delete
  "b" #'taskwarrior-list-start
  "B" #'taskwarrior-list-stop
  "D" #'taskwarrior-list-dates-menu
  "m" #'taskwarrior-list-toggle-mark
  "*" #'taskwarrior-list-mark-all
  "u" #'taskwarrior-list-unmark-all
  "!" #'taskwarrior-list-run-command
  "U" #'taskwarrior-list-undo)

(define-derived-mode taskwarrior-list-mode tabulated-list-mode "Taskwarrior"
  "Major mode for browsing and operating on Taskwarrior tasks."
  (setq-local taskwarrior-list-report taskwarrior-list-default-report
              taskwarrior-list-filters nil
              taskwarrior-list--tasks nil
              taskwarrior-list--tasks-by-uuid (make-hash-table :test 'equal)
              taskwarrior-list--marks (make-hash-table :test 'equal)
              taskwarrior-list--context nil
              tabulated-list-format (taskwarrior-list--column-format)
              tabulated-list-padding 1
              tabulated-list-sort-key nil
              mode-line-process '(:eval (taskwarrior-list--mode-line-status)))
  (add-hook 'tabulated-list-revert-hook #'taskwarrior-list--reload nil t)
  (add-hook 'post-command-hook
            #'taskwarrior-list--update-information nil t)
  (add-hook 'quit-window-hook
            #'taskwarrior-list--close-information-window nil t)
  (tabulated-list-init-header))

;;;###autoload
(defun +taskwarrior-list (&optional report filters)
  "Toggle or open the persistent Taskwarrior list for REPORT with FILTERS.
With no arguments, toggle the default Taskwarrior list side window."
  (interactive)
  (let ((buffer (get-buffer taskwarrior-list-buffer-name)))
    (if (and (null report) (null filters)
             buffer (get-buffer-window buffer 0))
        (quit-window nil (get-buffer-window buffer 0))
      (if (and report (not (taskwarrior-list--task-report-p report)))
          (+taskwarrior-report report filters)
        (setq buffer (or buffer (get-buffer-create taskwarrior-list-buffer-name)))
        (taskwarrior-list--pop-to-buffer buffer)
        (unless (derived-mode-p 'taskwarrior-list-mode)
          (taskwarrior-list-mode))
        (setq taskwarrior-list-report (or report taskwarrior-list-default-report)
              taskwarrior-list-filters filters)
        (taskwarrior-list-refresh)))))

;;;###autoload
(defun +taskwarrior-list-select-report ()
  "Prompt for a report and open its appropriate Taskwarrior buffer."
  (interactive)
  (call-interactively #'taskwarrior-list-select-report))

(provide 'taskwarrior)
;;; taskwarrior.el ends here
