;;; core-workspaces.el --- Workspaces and projects -*- lexical-binding: t; -*-
;;
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package project
  :straight (:type built-in)
  :general
  (leader-def
    "/" 'consult-ripgrep
    "*" 'my/ripgrep-symbol
    "SPC" 'project-find-file
    "pp" 'project-switch-project
    "pf" 'project-find-file
    "pB" 'project-switch-to-buffer
    "pb" 'consult-project-buffer
    "pd" 'project-dired
    "ps" 'consult-ripgrep
    "pk" 'project-kill-buffers
    "pD" 'project-forget-project
    "pc" 'project-compile)

  :custom
  (project-switch-commands
    '((project-find-file "Find file" ?f)
       (consult-ripgrep "Ripgrep" ?s)
       (project-dired "Dired" ?d)
       (project-vc-dir "VC" ?v)
       (project-eshell "Eshell" ?e)))

  :preface
  (defun my/ripgrep-symbol ()
    "Search for symbol at point in project using ripgrep."
    (interactive)
    (consult-ripgrep (project-root (project-current t))
      (thing-at-point 'symbol)))

  :config
  (setq project-vc-extra-root-markers '(".project" ".git" ".node_modules")))

(use-package tabspaces
  :hook (after-init . tabspaces-mode)
  :commands (tabspaces-switch-or-create-workspace
              tabspaces-open-or-create-project-and-workspace)
  :general
  (leader-def
    "TAB TAB" 'tabspaces-open-or-create-project-and-workspace
    ">" 'tabspaces-switch-or-create-workspace
    "TAB d" 'tabspaces-close-workspace
    "TAB b" 'tabspaces-switch-to-buffer
    "TAB k" 'tabspaces-kill-buffers-close-workspace
    "TAB R" 'tabspaces-restore-session
    "TAB S" 'tabspaces-save-session
    "TAB C" 'tabspaces-clear-buffers
    "TAB ." 'tabspaces-switch-buffer-and-tab)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*"))
  (tabspaces-session t)
  (tabspaces-session-auto-restore nil))

(with-eval-after-load 'consult
  (consult-customize consult--source-buffer :hidden t :default nil)
  (defvar consult--source-workspace
    (list :name     "Workspace Buffers"
      :narrow   ?w
      :history  'buffer-name-history
      :category 'buffer
      :state    #'consult--buffer-state
      :default  t
      :items    (lambda () (consult--buffer-query
                             :predicate #'tabspaces--local-buffer-p
                             :sort 'visibility
                             :as #'buffer-name)))
    "Workspace buffer candidate source for `consult-buffer'.")
  (add-to-list 'consult-buffer-sources 'consult--source-workspace))


(provide 'core-workspaces)
;;; core-workspaces.el ends here
