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
  :custom
  (project-switch-commands
    '((project-find-file "Find file" ?f)
       (consult-ripgrep "Ripgrep" ?s)
       (project-dired "Dired" ?d)
       (magit-project-status "Magit" ?m)
       (project-vc-dir "VC" ?v)
       (forge-dispatch "Forge" ?g)
       (project-eshell "Eshell" ?e)))

  :preface
  (defun +find-symbol ()
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
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*"))
  (tabspaces-session t)
  (tabspaces-session-auto-restore nil))

(provide 'core-workspaces)
;;; core-workspaces.el ends here
