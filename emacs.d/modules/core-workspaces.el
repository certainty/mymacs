;;; core-workspaces.el --- Workspaces and projects -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Configures project.el for project management and tabspaces for
;; workspace isolation based on tab-bar-mode.
;;
;;; Code:

;;; Project Management
(use-package project
  :straight (:type built-in)
  :custom
  (project-vc-extra-root-markers '(".project" ".git" ".node_modules"))
  (project-switch-commands
   '((project-find-file "Find file" ?f)
     (consult-ripgrep "Ripgrep" ?s)
     (project-dired "Dired" ?d)
     (magit-project-status "Magit" ?g)
     (project-vc-dir "VC" ?v)))

  :init
  (keymap-set project-prefix-map "c" #'project-compile)
  (keymap-set project-prefix-map "s" #'consult-ripgrep)
  (keymap-set project-prefix-map "e" #'project-dired)

  :preface
  (defun +find-symbol ()
    "Search for symbol at point in project using ripgrep."
    (interactive)
    (consult-ripgrep (project-root (project-current t))
                     (thing-at-point 'symbol))))

;;; Projection (Project-type awareness and multi-target compilation)
(use-package projection
  :straight (:type git :host github :repo "mohkale/projection")
  :hook (after-init . global-projection-hook-mode)
  :hook (compilation-mode . projection-customize-compilation-mode)
  :custom
  (compilation-buffer-name-function
   #'projection-customize-compilation-buffer-name-function))

(use-package ansi-color
  :straight (:type built-in)
  :preface
  (defvar-local my/compilation-status nil
    "Visual status of the current compilation buffer.")

  (defun my/compilation-status-segment ()
    "Return a mode-line segment describing the current compilation state."
    (pcase my/compilation-status
      ('running (propertize " ↻" 'face 'mode-line-emphasis))
      ('success (propertize " ✓" 'face 'success))
      ('error (propertize " ✕" 'face 'error))
      (_ "")))

  (defun my/compilation-finish-status (buffer status)
    "Update BUFFER mode line after compilation finishes with STATUS."
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (setq-local my/compilation-status
                    (if (string-prefix-p "finished" status) 'success 'error))
        (force-mode-line-update t))))

  (defun my/enable-ansi-color-in-compilation ()
    "Enable ANSI color translation and status display in compilation buffers."
    (setq-local compilation-scroll-output t)
    (setq-local ansi-color-for-compilation-mode t)
    (setq-local my/compilation-status 'running)
    (setq-local mode-line-format
                (append mode-line-format '((:eval (my/compilation-status-segment)))))
    (add-hook 'compilation-finish-functions #'my/compilation-finish-status nil t)
    (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter nil t))
  :hook (compilation-mode . my/enable-ansi-color-in-compilation))

(use-package projection-find
  :straight (:type git :host github :repo "mohkale/projection"))

(use-package projection-multi
  :straight (:type git :host github :repo "mohkale/projection")
  :after projection
  :bind
  (:map project-prefix-map
        ("C" . projection-multi-compile)))

(use-package projection-multi-embark
  :straight (:type git :host github :repo "mohkale/projection")
  :after (projection-multi embark)
  :config
  (projection-multi-embark-setup-command-map))

;; Projection integration for `dape'
(use-package projection-dape
  :bind (:map projection-map ("D" . #'projection-dape)))

;;; Workspaces via tab-bar
(use-package tabspaces
  :hook (after-init . tabspaces-mode)
  :commands (tabspaces-switch-or-create-workspace
             tabspaces-open-or-create-project-and-workspace)
  :preface
  (declare-function tabspaces-prompt-project-dir "tabspaces")

  (defun my/tabspaces-open-project-dired (&optional project prefix)
    "Open PROJECT in a dedicated tabspace and visit its root in Dired.
With PREFIX, always create a new tab for the project."
    (interactive
     (list (tabspaces-prompt-project-dir) current-prefix-arg))
    (let ((tabspaces-project-switch-commands 'project-dired))
      (tabspaces-open-or-create-project-and-workspace project prefix))
    (when-let* ((project-root
                 (or project
                     (when-let* ((current-project (project-current nil)))
                       (project-root current-project)))))
      (dired project-root)))

  (with-eval-after-load 'dashboard
    (setopt dashboard-projects-switch-function #'my/tabspaces-open-project-dired))
  :custom
  (tabspaces-project-switch-commands #'project-dired)
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*"))
  (tabspaces-session t)
  (tabspaces-session-auto-restore nil)
  :bind
  (:map project-prefix-map
        ("p" . my/tabspaces-open-project-dired)
        ("b" . tabspaces-switch-to-buffer)
        ("k" . tabspaces-kill-buffers-close-workspace)
        ("x" . tabspaces-close-workspace)))

(provide 'core-workspaces)
;;; core-workspaces.el ends here
