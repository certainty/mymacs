;; -*- lexical-binding: t; -*-
;;; GTD / Org setup

(use-package org
  :hook (org-after-todo-state-change . save-buffer)
  :custom
  (org-id-link-to-org-use-id t)
  (org-todo-keywords
    '((sequence "INBOX(i)" "NEXT(n)" "TODO(t)" "WAIT(w@/!)" "BLOCKED(b@/!)" "PROJ(p)" "|" "DONE(d!)" "CANCELLED(c@)")
       (sequence "EVT(m)" "|" "DONE(d!)" "CANCELLED(c@")
       (sequence "DECISION(q)" "|")))


  (org-priority-default ?B)
  (org-priority-highest ?A)
  (org-priority-lowest ?F)

  (org-use-fast-todo-selection 'expert)
  (org-enforce-todo-dependencies t)
  (org-enforce-todo-checkbox-dependencies t)

  ;; blocks
  (org-structure-template-alist
    '(("s" . "src")
       ("e" . "src emacs-lisp")
       ("E" . "src emacs-lisp :results value code :lexical t")
       ("t" . "src emacs-lisp :tangle FILENAME")
       ("T" . "src emacs-lisp :tangle FILENAME :mkdirp yes")
       ("x" . "example")
       ("X" . "export")
       ("q" . "quote")))

  ;; Capture for GTD
  (org-capture-templates
    '(
       ("n" "Note" entry (file+olp+datetree "log.org")
         "* %<%H:%M>  %?
:PROPERTIES:
:CAPTURED: %T
:END:"
         :tree-type week)

       ("t" "Task" entry (file "tasks.org")
         "* TODO %?
:PROPERTIES:
:CAPTURED: %U
:END:"
         :prepend t)

       ("p" "Project" entry (file "tasks.org")
         "* PROJ %? :project:
:PROPERTIES:
:CAPTURED: %U
:END:"
         :prepend t)

       ("d" "Decision" entry (file+olp+datetree "log.org")
         "* DECISION %? :decision:
:PROPERTIES:
:CAPTURED: %T
:END:"
         :tree-type week)

       ("e" "Event" entry (file+olp+datetree "log.org")
         "* EVT %? :event:
:PROPERTIES:
:CAPTURED: %U
:END:"
         :prepend t)))

  (org-agenda-current-time-string
    "◀── now ─────────────────────────────────────────────────")

  (org-agenda-sorting-strategy
    '((agenda habit-down time-up ts-up priority-down category-keep)
       (todo priority-down category-keep)
       (tags priority-down category-keep)
       (search category-keep)))

  (org-columns-default-format-for-agenda "%SCHEDULED %25ITEM %TODO %3PRIORITY %TAGS")

  (org-agenda-custom-commands
    '(
       ("d" "Decision Log"
         ((tags-todo "!DECISION"
            ((org-agenda-overriding-header "🧠 Decision Log\n")
              (org-agenda-remove-tags nil)
              (org-agenda-show-inherited-tags t)
              (org-agenda-time t)
              (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
              (org-agenda-scheduled-leaders '("" ""))
              (org-agenda-time-grid '((today require-timed remove-match) () "      " "┈┈┈┈┈┈┈┈┈┈┈┈┈"))))))

       ("e" "Event Log"
         ((tags "+event"
            ((org-agenda-overriding-header "📅 Event Log\n")
              (org-agenda-remove-tags nil)
              (org-agenda-show-inherited-tags t)
              (org-agenda-prefix-format "  %?-2i %s ")
              (org-agenda-todo-keyword-format "")))))

       ("y" "My Agenda"
         ((tags-todo "+nextup+TODO=\"NEXT\"|+nextup+TODO=\"TODO\""
            ((org-agenda-overriding-header "⭐ Next Up\n")
              (org-agenda-sorting-strategy '(priority-down deadline-up scheduled-up))
              (org-agenda-remove-tags nil)
              (org-agenda-max-entries 12)
              (org-agenda-prefix-format "  ")))

           (todo "NEXT|TODO"
             ((org-agenda-overriding-header "⚡ Ready\n")
               (org-agenda-sorting-strategy '(deadline-up scheduled-up priority-down))
               (org-agenda-remove-tags nil)
               (org-agenda-use-time-grid t)
               (org-agenda-max-entries 12)
               (org-agenda-deadline-leaders '(" Deadline: " " In %2d d.: " "%2d d. ago: "))
               (org-agenda-prefix-format "  ")))

           (todo "BLOCKED|WAITING"
             ((org-agenda-overriding-header "\n⚡ Blocked\n")
               (org-agenda-sorting-strategy '(priority-down))
               (org-agenda-remove-tags nil)
               (org-agenda-max-entries 12)
               (org-agenda-show-inherited-tags t)
               (org-agenda-deadline-leaders '(" Deadline: " " In %2d d.: " "%2d d. ago: "))
               (org-agenda-prefix-format "  ")))

           (agenda ""
             ((org-agenda-overriding-header "\n🗓️ Upcoming\n")
               (org-deadline-warning-days 3)
               (org-agenda-skip-scheduled-if-done nil)
               (org-agenda-time-leading-zero t)
               (org-agenda-timegrid-use-ampm nil)
               (org-agenda-skip-timestamp-if-done t)
               (org-agenda-skip-deadline-if-done t)
               (org-agenda-start-day "+0d")
               (org-agenda-span 5)
               (org-agenda-repeating-timestamp-show-all nil)
               (org-agenda-remove-tags nil)
               (org-agenda-time t)
               (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
               (org-agenda-scheduled-leaders '("" ""))
               (org-agenda-deadline-leaders '(" Deadline: " " In %2d d.: " "%2d d. ago: "))
               (org-agenda-time-grid '((today require-timed remove-match) () "      " "┈┈┈┈┈┈┈┈┈┈┈┈┈"))))))

       ("w" "Weekly Review"
         ((agenda ""
            ((org-agenda-overriding-header "🎉 Completed (last 7 days)\n")
              (org-agenda-span 7)
              (org-agenda-start-day "-6d")
              (org-agenda-start-with-log-mode 'closed)
              (org-agenda-show-log 'clockcheck)
              (org-agenda-log-mode-items '(closed clock))
              (org-agenda-skip-function '(org-agenda-skip-entry-if 'notregexp "CLOSED"))
              (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")))
           (tags "+decision"
             ((org-agenda-overriding-header "\n🧠 Decisions (last 7 days)\n")
               (org-agenda-span 7)
               (org-agenda-start-day "-6d")
               (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
               (org-agenda-remove-tags nil)))
           (tags-todo "+project|!TODO|!BLOCKED|!DELEGATED"
             ((org-agenda-overriding-header "\n📋 Open Projects\n")
               (org-agenda-remove-tags nil)
               (org-tags-match-list-sublevels nil)
               (org-agenda-show-inherited-tags t)
               (org-agenda-prefix-format "  %?-2i %s ")
               (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
               (org-agenda-todo-keyword-format "")))
           (todo "*"
             ((org-agenda-overriding-header "\n📝 Open Tasks to Refile\n")
               (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
               (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
               (org-agenda-span 'week)))))

       ("l" "Done Log (last 14 days)"
         ((agenda ""
            ((org-agenda-overriding-header "✅ Done (last 14 days)\n")
              (org-agenda-span 14)
              (org-agenda-start-day "-13d")
              (org-agenda-start-with-log-mode 'closed)
              (org-agenda-show-log 'clockcheck)
              (org-agenda-skip-function '(org-agenda-skip-entry-if 'notregexp "CLOSED"))
              (org-agenda-sorting-strategy '(closed-up priority-down))
              (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s "))))))

    ("u" "Unscheduled Tasks"
      ((tags-todo "-SCHEDULED={.+}"
         ((org-agenda-overriding-header "⚡Unscheduled Tasks\n")
           (org-agenda-sort-strategy '(priority-down))
           (org-agenda-group-by-heading t)
           (org-tags-match-list-sublevels t)
           (org-agenda-prefix-format "%i %-15c "))))))

  :config
  (require 'org-id)

  (defun +personal-agenda ()
    (interactive)
    (org-agenda nil "y"))

  (defun +org-toggle-next-up ()
    (interactive)
    (if (derived-mode-p 'org-agenda-mode)
      (let* ((marker (or (get-text-property (point) 'org-hd-marker)
                       (get-text-property (point) 'org-marker)))
              (agenda-window (get-buffer-window (current-buffer) 0))
              (keep-top-visible (and agenda-window
                                  (= (window-start agenda-window) (point-min)))))
        (unless marker
          (user-error "No Org item at point"))
        (org-with-point-at marker
          (org-toggle-tag "nextup" 'toggle)
          (save-buffer))
        (org-agenda-redo)
        (when keep-top-visible
          (set-window-start agenda-window (point-min) t)))
      (org-toggle-tag "nextup" 'toggle)
      (save-buffer)))

  (defun +capture-task ()
    (interactive)
    (org-capture nil "t"))

  (defun +capture-note ()
    (interactive)
    (org-capture nil "n"))

  (defun +capture-event ()
    (interactive)
    (org-capture nil "e"))

  (defun +capture-project ()
    (interactive)
    (org-capture nil "p"))

  (defun +capture-decision ()
    (interactive)
    (org-capture nil "d"))

  (defun +browse-org ()
    (interactive)
    (dired my/org-path))

  (defun +sort-all-by-todo ()
    (interactive)
    (mark-whole-buffer)
    (org-sort-entries nil ?o)
    (deactivate-mark))

  (defun +collapse-all ()
    (interactive)
    ;; run org-cycle with universal argument to collapse all
    (universal-argument)
    (org-cycle))

  (defun my/goto-special-org-file (name)
    (interactive "sFile name (without .org): ")
    (let ((file-path (concat org-directory "/" name ".org")))
      (unless (file-exists-p file-path)
        (with-temp-buffer
          (write-file file-path)))
      (find-file-other-window file-path)))

  (defun +goto-log ()
    (interactive)
    (my/goto-special-org-file "log"))

  (defun +goto-tasks ()
    (interactive)
    (my/goto-special-org-file "tasks"))

  (defun +goto-contacts ()
    (interactive)
    (my/goto-special-org-file "contacts"))

  (defun +org-ripgrep ()
    (interactive)
    (consult-ripgrep org-directory))

  (defun +org-grep ()
    (interactive)
    (let ((default-directory org-directory))
      (call-interactively #'grep)))

  (setopt org-agenda-files
    (list
      (concat org-directory "/log.org")
      (concat org-directory "/tasks.org")))

  :init
  (with-eval-after-load 'embark
    (keymap-set embark-org-heading-map
      "i" #'org-id-get-create))

  (with-eval-after-load 'org-agenda
    (keymap-set org-agenda-mode-map "C-c n" #'+org-toggle-next-up))

  ;; Use shackle to pin agenda to the right; match both mode and buffer name.
  (my/window-rule! org-agenda-mode :align right :size 0.4 :select nil :reuse t)
  (my/window-rule! "*Org Agenda.*" :regexp t :align right :size 0.4 :select nil :reuse t)
  (my/with-popper! "*Org Agenda.*"))

(use-package org-project-capture
  :custom
  (org-project-capture-backend (make-instance 'org-project-capture-project-backend))
  (org-project-capture-capture-template "* TODO %?
:PROPERTIES:
:CAPTURED: %U
:FILE: [[%F][%f]]
:POS: %l
:END:

%i
")
  :config
  (org-project-capture-per-project)

  ;; upstream version is outdated so we use this
  (cl-defmethod org-project-capture-current-project ((_backend org-project-capture-project-backend))
    (project-name (project-current))))


(use-package org-caldav
  :if (my/context-private-p)
  :custom
  (org-caldav-url "https://drive.krentzlin.me/remote.php/dav/calendars/david")
  (org-caldav-files nil)
  (org-icalendar-timezone "Europe/Berlin")
  (org-icalendar-include-todo '("TODO" "PROJ" "DOING" "DONE" "CANCELLED" "BLOCKED" "DELEGATED"))
  (org-caldav-sync-todo t)
  (org-caldav-todo-percent-states '((0 "TODO")
                                     (0 "PROJ")
                                     (50 "DOING")
                                     (50 "BLOCKED")
                                     (50 "DELEGATED")
                                     (100 "DONE")
                                     (100 "CANCELLED")))
  :config
  (setq org-caldav-calendars
    `((:calendar-id "personal"
        :inbox ,(concat my/org-path "/caldav_calendar.org")
        :files (,(concat my/org-path "/calendar.org")))
       (:calendar-id "aufgaben"
         :inbox ,(concat my/org-path "/caldav_tasks.org")
         :files (,(concat my/org-path "/tasks.org"))))))

(provide 'org-gtd)
