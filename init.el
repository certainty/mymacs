;;; init.el --- Main Initialization -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; My Emacs configuration with evil mode and packages tailored for software engineers
;;
;;  Description
;;
;;; Code:

;;; Straight setup
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq straight-disable-byte-compilation t)
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq use-package-always-defer t)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(require 'mymacs)

(my/require 'core-features)
(my/require 'core-config)
(my/require 'core-env)
(my/require 'core-keys)
(my/require 'core-editing)
(my/require 'core-files)
(my/require 'core-buffers)
(my/require 'core-ui)
(my/require 'core-help)
(my/require 'core-completion)
(my/require 'core-search)
(my/require 'core-workspaces)
(my/require 'core-dashboard)

(my/require 'dev-base)

(my/require 'tools-vc)

(provide 'init)
;;; init.el ends here
