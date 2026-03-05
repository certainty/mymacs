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
  (defun +find-config-file ()
    "Find a file in the Emacs config directory."
    (interactive)
    (let ((default-directory user-emacs-directory))
      (call-interactively #'find-file)))

  (defun +browse-config ()
    "Open Emacs config directory in dired."
    (interactive)
    (dired user-emacs-directory))

  (defun +find-init-file ()
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
    (message "Configuration reloaded"))

  (defun +show-startup-time ()
    "Show Emacs startup time."
    (interactive)
    (message "Emacs startup time: %s" (emacs-init-time)))

  (defun my/authinfo-path ()
    "Return the path to the authinfo.gpg file."
    (let ((ctx my/context))
      (cond
        ((eq ctx 'work)
          (expand-file-name "secrets/authinfo.work.gpg" user-emacs-directory))
        ((eq ctx 'private)
          (expand-file-name "secrets/authinfo.private.gpg" user-emacs-directory))
        (t
          (error "Unknown context: %s" ctx)))))

  (defun +find-auth-info ()
    (interactive)
    (find-file (my/authinfo-path)))

  :bind
  (:map +config
    ("f" . +find-config-file)
    ("d" . +browse-config)
    ("i" . +find-init-file)
    ("e" . +find-early-init-file)
    ("m" . +edit-config-module))
  (:map +do
    ("c" . +reload-config)
    ("t" . +show-startup-time)))

(provide 'core-mymacs)
