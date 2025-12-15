;;; my-org.el --- Org -*- lexical-binding: t; -*-

;;; Basics
(use-package org
  :ensure nil
  :commands (org-mode)
  :mode (("\\.org$" . org-mode))
  :custom
  (org-directory (file-truename (expand-file-name "~/Silo/Shared/Org"))
  (org-attach-id-dir (concat org-directory "/.attach/")))

  ;; Aesthetics & UI
  (org-auto-align-tags t)
  (org-catch-invisible-edits 'smart)
  (org-cycle-separator-lines 0)
  (org-ellipsis "…")
  (org-fontify-quote-and-verse-blocks t)
  (org-hide-emphasis-markers t)
  (org-hide-leading-stars t)
  (org-image-actual-width  500)
  (org-pretty-entities t)
  (org-pretty-entities-include-sub-superscripts t)
  (org-read-date-prefer-future 'time)
  (org-startup-folded t)


  ;; Footnotes
  (org-footnote-section nil)   ;; place footnotes locally
  (org-footnote-auto-adjust t) ;; renumber footnotes

  ;; Indentation
  (org-adapt-indentation nil)      ;; adapt indentation
  (org-startup-indented t)         ;; start with indentation of headlines
  (org-src-preserve-indentation t) ;; preserve code indentation

  ;; Insertion/Yanking
  (org-insert-heading-respect-content nil) ;; I never want to insert after subtree NOOOO
  (org-M-RET-may-split-line '((default . t))) ;; don't split line when creating a new headline, list item, or table field
  (org-yank-adjusted-subtrees t) ;; adjust subtrees to depth when yanked

  ;; Lists
  (org-list-allow-alphabetical t) ;; allow alphabetical list

  ;; Logging
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-log-state-notes-insert-after-drawers nil)
  (org-log-redeadline nil) ;; don't log the time a task was rescheduled/redeadlined.
  (org-log-reschedule nil)

  ;; Movement
  (org-return-follows-link t) ;; make RET follow links
  (org-special-ctrl-a/e nil)

  ;; Searching
  (org-imenu-depth 12)   ;; scan to depth 8 w/imenu
  (imenu-auto-rescan t) ;; make sure imenu refreshes

  ;; Source block settings
  (org-src-fontify-natively t)         ;; use lang-specific fontification
  (org-src-window-setup 'other-window) ;; edit source in other window
  (org-src-tab-acts-natively t)        ;; use lang bindings
  (org-confirm-babel-evaluate t)       ;; confirm evaluation

  ;; Refiling
  (org-refile-targets
   '((nil :maxlevel . 5)
     (org-agenda-files :maxlevel . 5)))

  (org-outline-path-complete-in-steps nil)
  (org-refile-use-outline-path t)

  ;; Images
  (org-display-inline-images t)

  :config
  (require 'org-faces)

  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)

  (add-to-list 'display-buffer-alist
    '("\\*Org \\(Select\\|Note\\)\\*"
             (display-buffer-in-side-window)
             (dedicated . t)
             (side . bottom)
             (slot . 0)
       (window-parameters . ((mode-line-format . none))))))

;; use org-modern
(use-package org-modern
  :ensure (org-modern :host github :repo "minad/org-modern")
  :hook
  (elpaca-after-init . global-org-modern-mode)
  (org-agenda-finalize . org-modern-agenda)
  :custom
  (org-modern-fold-stars '(("◉" . "◉") ("○" . "○") ("◈" . "◈") ("◇" . "◇") ("◦" . "◦")))
  :config
  (org-indent-mode t))

(use-package yankpad
  :general
  (my-global-leader-keymap
   "y" '("Yankpad insert" . yankpad-insert))
  :custom
  (yankpad-file (expand-file-name "snippets.org" user-emacs-directory))
  :config
  (add-to-list 'hippie-expand-try-functions-list #'yankpad-expand))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; babel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package org
  :ensure nil
  :custom
  (org-plantuml-exec-mode 'plantuml)
  :config
  (org-babel-do-load-languages
    'org-babel-load-languages
    '((plantuml . t))))

;;; GDT
(use-package org
  :ensure nil
  :hook (org-after-todo-state-change . save-buffer)
  :general
  (my-gtd-keymap
    "a" '("agenda" . my/personal-agenda)
    "c" '("capture" . org-capture)
    "t" '("todo" . my/capture-task))

  (my-open-keymap
    "a" '("agenda" . my/personal-agenda))

  :init
  (require 'org-id)

  :custom
  (org-id-link-to-org-use-id t)
  (org-todo-keywords
    '((sequence "TODO(t)" "DOING(g!)" "|" "DONE(d!)")
       (sequence "FEATURE(r)" "DOING(g!)" "|" "DONE(d!)")
       (sequence "TECHDEPT(e)" "|" "DONE(d!)")
       (sequence "FIX(f!)" "REVIEW(r!)" "|" "DONE(d)")
       (sequence "POC(p)" "|" "DONE(d)")
       (sequence "REFACTOR(f)" "|" "DONE(d)")
       (sequence "DOC(o)" "|" "DONE(d)")
       (sequence "MEETING(m)" "|" "DONE(d)")
       (sequence "APPT(a)" "|" "DONE(d)")
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
    '(("t" "Task" entry (file+headline "todo.org" "Main")
        "* TODO %?
:PROPERTIES:
:CAPTURED: %U
:END:"
        :prepend t)

       ("c" "Contact" entry (file "contacts.org")
         "* %^{Name}
:PROPERTIES:
:CAPTURED: %U
:CATEGORY: contact
:END:

%?
"    )))

  ;; Agenda
  (org-agenda-files
    (list
     (concat org-directory "/todo.org")
     (concat org-directory "/projects.org")
     (concat org-directory "/contacts.org")))

  (org-agenda-current-time-string
    "◀── now ─────────────────────────────────────────────────")

  (org-agenda-sorting-strategy
    '((agenda habit-down time-up ts-up priority-down category-keep)
       (todo priority-down category-keep)
       (tags priority-down category-keep)
       (search category-keep)))

  (org-columns-default-format-for-agenda "%SCHEDULED %25ITEM %TODO %3PRIORITY %TAGS")

  ;; TODO tweak agenda to be more useful for coderelated tasks
  (org-agenda-custom-commands
    '(("y" "My Agenda"
        ((tags-todo "-CATEGORY=\"project\""
            ((org-agenda-overriding-header "⚡ Today\n")
              (org-agenda-sorting-strategy '(priority-down))
              (org-agenda-remove-tags nil)
              (org-agenda-use-time-grid t)
              (org-agenda-deadline-leaders '(" Deadline: " " In %2d d.: " "%2d d. ago: "))
              (org-agenda-skip-function '(org-agenda-skip-entry-if  'todo 'done))
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
              (org-agenda-time-grid (quote ((today require-timed remove-match) () "      " "┈┈┈┈┈┈┈┈┈┈┈┈┈")))))))

       ("w" "Weekly Review"
         ((todo "*"
            ((org-agenda-overriding-header "🎉 Completed Tasks\n")
              (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
              (org-agenda-skip-function '(org-agenda-skip-entry-if 'nottodo 'done))
              (org-agenda-span 'week)))

          (agenda ""
            ((org-agenda-overriding-header "\n📋 Unfinished Scheduled Tasks\n")
              (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
              (org-agenda-prefix-format "   %?-2i %?-12c %?-2t%s ")
              (org-agenda-span 'week)))))

       ("u" "Unscheduled Tasks"
         ((tags-todo "-SCHEDULED={.+}"
            ((org-agenda-overriding-header "⚡Unscheduled Tasks\n")
              (org-agenda-sort-strategy '(priority-down))
              (org-agenda-group-by-heading t)
              (org-tags-match-list-sublevels t)
              (org-agenda-prefix-format "%i %-15c ")))))))
  :config
  (defun my/personal-agenda ()
    (interactive)
    (org-agenda nil "y"))

  (defun my/capture-task ()
    (interactive)
    (org-capture nil "t"))

  (defun my/goto-tasks ()
    (interactive)
    (find-file-other-window (concat org-directory "/todo.org")))

  (defun my/org-ripgrep ()
    (interactive)
    (consult-ripgrep org-directory))

  (defun my/org-grep ()
    (interactive)
    (let ((default-directory org-directory))
      (call-interactively #'grep)))

  ;; embark
  (with-eval-after-load 'embark
    (keymap-set embark-org-heading-map
      "i" #'org-id-get-create))

  (with-eval-after-load 'popper
    (cl-pushnew 'org-agenda-mode popper-reference-buffers)
    (cl-pushnew "\\*Org Agenda\\*" popper-reference-buffers))

  (add-to-list 'display-buffer-alist
               '("\\*Org Agenda\\*"
                (display-buffer-reuse-window
                 display-buffer-in-side-window)
                (side . right)
                (slot . 0)
                (window-width . 0.4)
                (reusable-frames . visible))))


;;; Project capture
(use-package org-project-capture
  :general
  (my-gtd-keymap
    "p" '("project" . org-project-capture-capture-for-current-project)
    "P" '("project*" . org-project-capture-project-todo-completing-read))
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
  (cl-defmethod org-project-capture-current-project ((_backend org-project-capture-project-backend))
    (project-name (project-current))))

(provide 'my-org)
