;;; core-mymacs.el --- configure mymacs -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(defun my/find-config-file ()
  "Find a file in the Emacs config directory."
  (interactive)
  (let ((default-directory user-emacs-directory))
    (call-interactively #'find-file)))

(defun my/browse-config ()
  "Open Emacs config directory in dired."
  (interactive)
  (dired user-emacs-directory))

(defun my/find-init-file ()
  "Open init.el."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(defun my/find-early-init-file ()
  "Open early-init.el."
  (interactive)
  (find-file (expand-file-name "early-init.el" user-emacs-directory)))

(defun my/edit-config-module ()
  "Find and edit a config module in modules/."
  (interactive)
  (let ((default-directory (expand-file-name "modules" user-emacs-directory)))
    (call-interactively #'find-file)))

(defun my/reload-config ()
  "Reload Emacs configuration."
  (interactive)
  (load-file (expand-file-name "init.el" user-emacs-directory))
  (message "Configuration reloaded"))

(defun my/show-startup-time ()
  "Show Emacs startup time."
  (interactive)
  (message "Emacs startup time: %s" (emacs-init-time)))

;;;; Config Keybindings
(with-eval-after-load 'general
  (leader-def
    "Mf" 'my/find-config-file
    "Md" 'my/browse-config
    "Mi" 'my/find-init-file
    "Me" 'my/find-early-init-file
    "Mm" 'my/edit-config-module
    "Mr" 'my/reload-config
    "Mt" 'my/show-startup-time
    "Mb" 'my/browse-config))

(provide 'core-mymacs)
