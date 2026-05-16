;;; core-mymacs.el --- configure mymacs -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package emacs
  :straight (:type built-in)
  :preface
  (defun +config-file ()
    "Find a file in the Emacs config directory."
    (interactive)
    (let ((default-directory user-emacs-directory))
      (call-interactively #'find-file)))

  (defun +browse-config ()
    "Open Emacs config directory in dired."
    (interactive)
    (dired user-emacs-directory))

  (defun +init-file ()
    "Open init.el."
    (interactive)
    (find-file (expand-file-name "init.el" user-emacs-directory)))

  (defun +find-early-init-file ()
    "Open early-init.el."
    (interactive)
    (find-file (expand-file-name "early-init.el" user-emacs-directory)))

  (defun +edit-config-module ()
    "Find and edit a config module in modules/."
    (interactive)
    (let ((default-directory (expand-file-name "modules" user-emacs-directory)))
      (call-interactively #'find-file)))

  (defun +reload-config ()
    "Reload Emacs configuration."
    (interactive)
    (load-file (expand-file-name "init.el" user-emacs-directory))
    (message "Configuration reloaded")))

(provide 'core-mymacs)
