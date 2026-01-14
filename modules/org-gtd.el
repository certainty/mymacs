;; -*- lexical-binding: t; -*-
;;; GTD / Org setup

(use-package org
  :hook (org-after-todo-state-change . save-buffer)
  :general
  (leader-def
    "o" '(:ignore t :which-key "org")
    "oa" 'my/personal-agenda
    "oA" 'org-agenda
    "oc" 'org-capture
    "ot" 'my/capture-task
    "on" 'my/capture-note
    "oe" 'my/capture-event
    "od" 'my/capture-decision

    "go" '(:ignore t :which-key "org")
    "god" 'my/open-org-dir
    "gop" 'my/goto-projects
    "gol" 'my/goto-log
    "goc" 'my/goto-contacts)

  :custom
  (org-id-link-to-org-use-id t)

  (org-todo-keywords
    '((sequence "DECISION(!q)" "|")
       (sequence "TODO(t)" "DOING(g!)" "|" "DONE(d!)")
       (sequence "FEATURE(r)" "DOING(g!)" "|" "DONE(d!)")
       (sequence "PROJ(p)" "DOING(g!)" "|" "DONE(d!)")
       (sequence "EVT(m)" "|" "DONE(d)")
       (sequence "|" "BLOCKED(l!)")
       (sequence "|" "CANCELED(c!)")))

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
         "* PROJ %?
:PROPERTIES:
:CAPTURED: %U
:END:"
         :prepend t)

       ("d" "Decision" entry (file+olp+datetree "log.org")
         "* DECISION %?
:PROPERTIES:
:CAPTURED: %T
:CATEGORY: decision
:END:"
         :tree-type week)

       ("e" "Event" entry (file "calendar.org")
         "* EVT %?
:PROPERTIES:
:CAPTURED: %U
:CATEGORY: event
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
         ((tags "CATEGORY=\"decision\"|TODO=\"DECISION\""
            ((org-agenda-overriding-header "🧠 Decision Log\n")
              (org-agenda-remove-tags nil)
              (org-agenda-show-inherited-tags t)
              (org-agenda-time t)
              (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
              (org-agenda-scheduled-leaders '("" ""))
              (org-agenda-time-grid '((today require-timed remove-match) () "      " "┈┈┈┈┈┈┈┈┈┈┈┈┈"))))))

       ("e" "Event Log"
         ((tags "CATEGORY=\"event\"|TODO=\"EVT\""
            ((org-agenda-overriding-header "📅 Event Log\n")
              (org-agenda-remove-tags nil)
              (org-agenda-show-inherited-tags t)
              (org-agenda-prefix-format "  %?-2i %s ")
              (org-agenda-todo-keyword-format "")))))

       ("y" "My Agenda"
         ((tags-todo "-CATEGORY=\"project\""
            ((org-agenda-overriding-header "⚡ Today\n")
              (org-agenda-sorting-strategy '(priority-down))
              (org-agenda-remove-tags nil)
              (org-agenda-use-time-grid t)
              (org-agenda-deadline-leaders '(" Deadline: " " In %2d d.: " "%2d d. ago: "))
              (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
              (org-agenda-prefix-format "%s  %?-2i %?-12c ")))

           (tags "+CATEGORY=\"project\"|+TODO=\"PROJ\""
             ((org-agenda-overriding-header "\n⚡ Projects\n")
               (org-agenda-remove-tags nil)
               (org-tags-match-list-sublevels nil)
               (org-agenda-show-inherited-tags t)
               (org-agenda-prefix-format "  %?-2i %s ")
               (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
               (org-agenda-todo-keyword-format "")))

           (agenda ""
             ((org-agenda-overriding-header "\n🗓️ Calendar\n")
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
           (tags "CATEGORY=\"decision\"|TODO=\"DECISION\""
             ((org-agenda-overriding-header "\n🧠 Decisions (last 7 days)\n")
               (org-agenda-span 7)
               (org-agenda-start-day "-6d")
               (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
               (org-agenda-remove-tags nil)))
           (tags-todo "+CATEGORY=\"project\"|+TODO=\"PROJ\""
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

  (defun my/personal-agenda ()
    (interactive)
    (org-agenda nil "y"))

  (defun my/capture-task ()
    (interactive)
    (org-capture nil "t"))

  (defun my/capture-note ()
    (interactive)
    (org-capture nil "n"))

  (defun my/capture-event ()
    (interactive)
    (org-capture nil "e"))

  (defun my/capture-project ()
    (interactive)
    (org-capture nil "p"))

  (defun my/capture-decision ()
    (interactive)
    (org-capture nil "d"))

  (defun my/open-org-dir ()
    (interactive)
    (dired my/org-path))

  (defun my/goto-special-org-file (name)
    (interactive "sFile name (without .org): ")
    (let ((file-path (concat org-directory "/" name ".org")))
      (unless (file-exists-p file-path)
        (with-temp-buffer
          (write-file file-path)))
      (find-file-other-window file-path)))

  (defun my/goto-log ()
    (interactive)
    (my/goto-special-org-file "log"))

  (defun my/goto-projects ()
    (interactive)
    (my/goto-special-org-file "projects"))

  (defun my/goto-contacts ()
    (interactive)
    (my/goto-special-org-file "contacts"))

  (defun my/org-ripgrep ()
    (interactive)
    (consult-ripgrep org-directory))

  (defun my/org-grep ()
    (interactive)
    (let ((default-directory org-directory))
      (call-interactively #'grep)))

  (setopt org-agenda-files
    (list
      (concat org-directory "/log.org")
      (concat org-directory "/tasks.org")))

  (when (my/context-private-p)
    (add-to-list 'org-agenda-files (concat org-directory "/caldav_tasks.org"))
    (add-to-list 'org-agenda-files (concat org-directory "/calendar.org"))
    (add-to-list 'org-agenda-files (concat org-directory "/caldav_calendar.org")))

  (when my/context-work-p
    (add-to-list 'org-agenda-files (concat org-directory "/pr-review.org")))

  :init
  (with-eval-after-load 'embark
    (keymap-set embark-org-heading-map
      "i" #'org-id-get-create))

  ;; Use shackle to pin agenda to the right; match both mode and buffer name.
  (my/window-rule! org-agenda-mode :align right :size 0.4 :select nil :reuse t))
(my/window-rule! "*Org Agenda.*" :regexp t :align right :size 0.4 :select nil :reuse t)
(my/with-popper! "*Org Agenda.*")

(use-package org-project-capture
  :general
  (leader-def
    "op" 'org-project-capture-capture-for-current-project
    "oP" 'org-project-capture-project-todo-completing-read)

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
  :general
  (leader-def
    "oS" 'org-caldav-sync)

  :custom
  (org-caldav-url "https://drive.krentzlin.me/remote.php/dav/calendars/david")
  (org-caldav-files nil)
  (org-icalendar-timezone "Europe/Berlin")
  (org-icalendar-include-todo 'all)
  (org-caldav-sync-todo t)
  (org-caldav-todo-percent-states '((0 "TODO")
                                     (100 "DONE")))
  :config
  (setq org-caldav-calendars
    `((:calendar-id "personal"
        :inbox ,(concat my/org-path "/caldav_calendar.org")
        :files (,(concat my/org-path "/calendar.org")))
       (:calendar-id "aufgaben"
         :inbox ,(concat my/org-path "/caldav_tasks.org")
         :files (,(concat my/org-path "/tasks.org"))))))

(provide 'org-gtd)
