;;; writing-gtd.el --- GTD workflow with Org -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Getting Things Done workflow built on org-mode.  Provides capture
;; templates, agenda views, and a weekly review command.  Depends on
;; writing-org.el being loaded first.
;;
;;; Code:

;;; GTD Helpers

(defun +personal-agenda ()
  "Show the personal agenda view."
  (interactive)
  (org-agenda nil "y"))

(defun +org-toggle-next-up ()
  "Toggle the 'nextup' tag on the current item."
  (interactive)
  (if (derived-mode-p 'org-agenda-mode)
    (let ((marker (or (get-text-property (point) 'org-hd-marker)
                    (get-text-property (point) 'org-marker))))
      (unless marker (user-error "No Org item at point"))
      (org-with-point-at marker
        (org-toggle-tag "nextup" 'toggle)
        (save-buffer))
      (org-agenda-redo))
    (org-toggle-tag "nextup" 'toggle)
    (save-buffer)))


;;; Org GTD configuration

(use-package org
  :hook (org-after-todo-state-change . save-buffer)
  :init
  (my/register-side-popup 'org-agenda-mode)
  (my/register-side-popup "Org Agenda.*" t t)

  :custom
  ;; TODO states
  (org-todo-keywords
    '((sequence "INBOX(i)" "NEXT(n)" "TODO(t)" "WAIT(w@/!)" "BLOCKED(b@/!)" "PROJ(p)"
        "|" "DONE(d!)" "CANCELLED(c@)")
       (sequence "EVT(m)" "|" "DONE(d!)" "CANCELLED(c@)")
       (sequence "|" "DECISION(d)")))
  (org-use-fast-todo-selection 'expert)
  (org-enforce-todo-dependencies t)
  (org-priority-default ?B)
  (org-priority-highest ?A)
  (org-priority-lowest ?F)

  ;; Capture templates
  (org-capture-templates
    '(("t" "Task" entry (file "tasks.org")
        "* TODO %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:"
        :prepend t)
       ("n" "Note" entry (file+olp+datetree "log.org")
         "* %<%H:%M> %?\n:PROPERTIES:\n:CAPTURED: %T\n:END:"
         :tree-type week)

       ("d" "Decision" entry (file+olp+datetree "log.org")
         "* DECISION %?\n:PROPERTIES:\n:CAPTURED: %T\n:END:"
         :tree-type week)

       ("e" "Event" entry (file+olp+datetree "log.org")
         "* EVT %? :event:\n:PROPERTIES:\n:CAPTURED: %U\n:END:"
         :tree-type week
         :prepend t)))

  ;; Agenda
  (org-agenda-files (list my/org-path))
  (org-agenda-current-time-string
    "---- now ----")
  (org-agenda-sorting-strategy
    '((agenda habit-down time-up ts-up priority-down category-keep)
       (todo priority-down category-keep)
       (tags priority-down category-keep)))

  (org-agenda-custom-commands
    '(("y" "My Agenda"
        ((tags-todo "+nextup+TODO=\"NEXT\"|+nextup+TODO=\"TODO\""
           ((org-agenda-overriding-header "Next Up\n")
             (org-agenda-sorting-strategy '(priority-down deadline-up))
             (org-agenda-max-entries 12)
             (org-agenda-prefix-format "  ")))
          (todo "NEXT|TODO"
            ((org-agenda-overriding-header "\nReady\n")
              (org-agenda-sorting-strategy '(deadline-up priority-down))
              (org-agenda-max-entries 12)
              (org-agenda-prefix-format "  ")))
          (todo "BLOCKED|WAIT"
            ((org-agenda-overriding-header "\nBlocked\n")
              (org-agenda-max-entries 12)
              (org-agenda-prefix-format "  ")))
          (agenda ""
            ((org-agenda-overriding-header "\nUpcoming\n")
              (org-agenda-start-day "+0d")
              (org-agenda-span 5)
              (org-deadline-warning-days 3)))))
       ("w" "Weekly Review"
         ((agenda ""
            ((org-agenda-overriding-header "Completed (last 7 days)\n")
              (org-agenda-span 7)
              (org-agenda-start-day "-6d")
              (org-agenda-start-with-log-mode 'closed)
              (org-agenda-skip-function
                '(org-agenda-skip-entry-if 'notregexp "CLOSED"))))
           (todo "*"
             ((org-agenda-overriding-header "\nOpen Tasks\n")
               (org-agenda-skip-function
                 '(org-agenda-skip-entry-if 'todo 'done))))))))

  :config
  (require 'org-id))

;;; Buffer placement
(my/register-side-popup 'org-agenda-mode)

(provide 'writing-gtd)
;;; writing-gtd.el ends here
