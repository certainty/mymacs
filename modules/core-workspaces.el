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
  :bind
  (:map my/leader-map
    ("/" . consult-ripgrep)
    ("*" . +find-symbol)
    ("f" . project-find-file))
  (:map +project
    ("p" . project-switch-project)
    ("B" . project-switch-to-buffer)
    ("b" . consult-project-buffer)
    ("d" . project-dired)
    ("s" . consult-ripgrep)
    ("k" . project-kill-buffers)
    ("D" . project-forget-project)
    ("c" . project-compile))

  (:map +project-search
    ("p" . consult-ripgrep))

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
  :bind
  (:map +workspaces
    ("TAB" . tabspaces-switch-or-create-workspace)
    (">" . tabspaces-switch-or-create-workspace)
    ("d" . tabspaces-close-workspace)
    ("b" . tabspaces-switch-to-buffer)
    ("k" . tabspaces-kill-buffers-close-workspace)
    ("R" . tabspaces-restore-session)
    ("S" . tabspaces-save-session)
    ("C" . tabspaces-clear-buffers)
    ("." . tabspaces-switch-buffer-and-tab))

  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*"))
  (tabspaces-session t)
  (tabspaces-session-auto-restore nil))

(provide 'core-workspaces)
;;; core-workspaces.el ends here
