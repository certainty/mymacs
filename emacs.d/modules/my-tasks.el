;;; my-tasks.el --- Org task management -*- lexical-binding: t; -*-

;;; Org task workflow

()

(use-package org
  :bind
  (:map my/task-prefix-map
        ("t" . my/tasks-agenda)
        ("T" . org-agenda)
        ("x" . my/tasks-capture)
        ("e" . my/tasks-open-file))
  (:map org-read-date-minibuffer-local-map
        ("C-f" . (lambda () (interactive) (org-eval-in-calendar '(calendar-forward-day 1))))
        ("C-b" . (lambda () (interactive) (org-eval-in-calendar '(calendar-backward-day 1))))
        ("M-f" . (lambda () (interactive) (org-eval-in-calendar '(calendar-forward-week 1))))
        ("M-b" . (lambda () (interactive) (org-eval-in-calendar '(calendar-backward-week 1))))
        ("M-a" . (lambda () (interactive) (org-eval-in-calendar '(calendar-beginning-of-week))))
        ("M-e" . (lambda () (interactive) (org-eval-in-calendar '(calendar-end-of-week))))
        ("C-M-f" . (lambda () (interactive) (org-eval-in-calendar '(calendar-forward-month 1))))
        ("C-M-b" . (lambda () (interactive) (org-eval-in-calendar '(calendar-forward-month 1))))
        ("C-M-a" . (lambda () (interactive) (org-eval-in-calendar '(calendar-begining-of-month))))
        ("C-M-e" . (lambda () (interactive) (org-eval-in-calendar '(calendar-end-of-month)))))
  :custom
  (org-agenda-files
   (list (expand-file-name my/org-tasks-file org-directory)))
  
  (org-todo-keywords
   '((sequence "TODO(t!)" "DOING(g!)" "BLOCKED(b!)" "|"
               "DONE(d!)" "CANCELLED(c!)")))
  (org-log-done 'time)
  (org-log-into-drawer "LOGBOOK")
  (org-agenda-custom-commands
   '(("v" "Task overview"
      ((tags-todo "+next"
                  ((org-agenda-overriding-header "Next")
                   (org-agenda-sorting-strategy '(priority-down scheduled-up))))
       (tags-todo "+PRIORITY=\"A\""
                  ((org-agenda-overriding-header "Important, unscheduled")
                   (org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline))))
       (tags-todo "DEADLINE<\"<today>\"|SCHEDULED<\"<today>\""
                  ((org-agenda-overriding-header "Overdue")))
       (agenda ""
               ((org-agenda-span 1)
                (org-deadline-warning-days 0)))
       (agenda ""
               ((org-agenda-start-day "+1d")
                (org-agenda-span 2)
                (org-deadline-warning-days 0)
                (org-agenda-overriding-header "Next two days")))
       (agenda ""
               ((org-agenda-start-day "today")
                (org-agenda-span 14)
                (org-agenda-entry-types '(:deadline))
                (org-agenda-overriding-header "Deadlines in the next 14 days")))))
     ("D" "Doing tasks with hierarchy" todo "DOING"
      ((org-agenda-overriding-header "Doing")
       (org-agenda-prefix-format '((todo . " %i %-12:c%b")))
       (org-agenda-todo-list-sublevels t)))))

  :init
  (push `("^\\*Org Agenda\\*$" . ,(my/side-window-config))
        display-buffer-alist)

  :config
  
  (defun my/tasks--file ()
    "Return the path to the single task file, creating its directory if needed."
    (make-directory org-directory t)
    (expand-file-name my/org-tasks-file org-directory))

  (defun my/tasks-agenda ()
    "Open the custom task overview agenda."
    (interactive)
    (my/tasks--file)
    (org-agenda nil "v"))

  (defun my/tasks-capture ()
    "Capture a task in the single task file."
    (interactive)
    (my/tasks--file)
    (org-capture nil "t"))

  (defun my/tasks-open-file ()
    "Open the single task file."
    (interactive)
    (find-file (my/tasks--file))))


(provide 'my-tasks)
;;; my-tasks.el ends here
