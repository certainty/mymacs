;;; my-tasks.el --- Org task management -*- lexical-binding: t; -*-

;;; Org task workflow
(use-package org
  :custom
  (org-agenda-files
   (list (expand-file-name "todo.org" org-directory)))
  (org-todo-keywords
   '((sequence "TODO(t!)" "DOING(g!)" "BLOCKED(b!)" "|"
               "DONE(d!)" "CANCELLED(c!)")))
  (org-log-done 'time)
  (org-log-into-drawer "LOGBOOK")
  (org-agenda-custom-commands
   '(("t" "Task overview"
      ((tags-todo "+PRIORITY=\"A\""
                  ((org-agenda-overriding-header "Important, unscheduled")
                   (org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline))))
       (tags-todo "DEADLINE<\"<today>\"|SCHEDULED<\"<today>\""
                  ((org-agenda-overriding-header "Overdue")))
       (agenda ""
               ((org-agenda-span 1)))
       (agenda ""
               ((org-agenda-start-day "+1d")
                (org-agenda-span 2)
                (org-agenda-overriding-header "Next two days")))
       (agenda ""
               ((org-agenda-start-day "today")
                (org-agenda-span 14)
                (org-agenda-entry-types '(:deadline))
                (org-agenda-overriding-header "Deadlines in the next 14 days"))))))))

(defun my/tasks--file ()
  "Return the path to the single task file, creating its directory if needed."
  (make-directory org-directory t)
  (expand-file-name "todo.org" org-directory))

(defun my/tasks-agenda ()
  "Open the custom task overview agenda."
  (interactive)
  (my/tasks--file)
  (org-agenda nil "t"))

(defun my/tasks-capture ()
  "Capture a task in the single task file."
  (interactive)
  (my/tasks--file)
  (org-capture nil "t"))

(defun my/tasks-open-file ()
  "Open the single task file."
  (interactive)
  (find-file (my/tasks--file)))

(keymap-set my/task-prefix-map "t" #'my/tasks-agenda)
(keymap-set my/task-prefix-map "T" #'org-agenda)
(keymap-set my/task-prefix-map "a" #'my/tasks-capture)
(keymap-set my/task-prefix-map "e" #'my/tasks-open-file)

(provide 'my-tasks)
;;; my-tasks.el ends here
