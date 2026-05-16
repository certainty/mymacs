;;; init.el --- Main initialization -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Bootstrap straight.el, configure use-package, and load core modules.
;; Feature modules are loaded conditionally based on flags in base-config.
;;
;;; Code:

;; Emacs 31 pre-releases such as 31.0.50 can lack `set-local', while newer
;; package releases already call it and `compat' does not backfill it on 31.x.
(unless (fboundp 'set-local)
  (defun set-local (variable value)
    "Make VARIABLE buffer-local and set it to VALUE."
    (set (make-local-variable variable) value)))

;;; Straight.el bootstrap
(setq straight-vc-use-snapshot-installation t
      straight-use-package-by-default t
      straight-enable-use-package-integration t)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(straight-use-package 'use-package)
(use-package diminish :demand t)

(require 'core-config)
(require 'core-env)
(require 'core-mymacs)
(require 'core-keys)
(require 'core-ui)
(require 'core-tui)
(require 'core-dashboard)
(require 'core-editing)
(require 'core-completion)
(require 'core-remote)
(require 'core-files)
(require 'core-buffers)
(require 'core-help)
(require 'core-search)
(require 'core-workspaces)
(require 'core-vc)
(require 'core-terminal)

;;; Writing modules (conditional)
(when my/enable-writing
  (require 'writing-base)
  (require 'writing-notes)
  (require 'writing-markdown)
  (require 'writing-org))

(when my/enable-gtd
  ;; TODO: change name to gtd-base
  (require 'writing-gtd))

;;; Development modules (always loaded)
(require 'dev-base)
(require 'dev-format)
(require 'dev-data)
(require 'dev-elisp)

;;; Language-specific modules (conditional)
(when my/enable-dev-go
  (require 'dev-go))

(when my/enable-dev-ruby
  (require 'dev-ruby))

(when my/enable-dev-scala
  (require 'dev-scala))

(when my/enable-dev-common-lisp
  (require 'dev-common-lisp))

(when my/enable-dev-web
  (require 'dev-web))

;;; AI modules (conditional)
(when my/enable-ai
  (require 'ai-base))

(provide 'init)
;;; init.el ends here
