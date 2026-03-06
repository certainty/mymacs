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

(straight-use-package 'use-package)
(setopt straight-vc-use-snapshot-installation t)
(setopt straight-use-package-by-default t)
(setopt use-package-always-defer t)
(setopt use-package-always-ensure t)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(use-package diminish :demand t)

(require 'mymacs)

;;; Core
(require 'core-config)
(require 'core-env)
(require 'core-keys)
(require 'core-mymacs)
(require 'core-ui)
(require 'core-editing)
(require 'core-files)
(require 'core-buffers)
(require 'core-help)
(require 'core-completion)
(require 'core-search)
(require 'core-workspaces)
(require 'core-dashboard)

;;; Dev

(require 'dev-base)
(require 'dev-format)
(require 'dev-lispy)
(require 'dev-elisp)

(require 'dev-web)
(require 'dev-go)

(when (my/context-private-p)
  (require 'dev-common-lisp)
  (require 'dev-ocaml))

(when (my/context-work-p)
  (require 'dev-ruby)
  (require 'dev-scala))

(require 'data-base)

;; Writing
(require 'writing-base)
(require 'writing-markdown)
(require 'writing-org)
(require 'writing-notes)

(when (my/context-work-p)
  (require 'writing-asciidoc))

;;; GTD
(require 'org-gtd)

;;; Tools
(require 'tools-vc)
(require 'tools-secrets)
(require 'tools-terminal)
(require 'tools-tmr)
;;(require 'tools-rss)

(when (my/context-work-p)
  (require 'ai-gptel)
  ;;(require 'ai-minuet)
  (require 'ai-agent-shell))

(provide 'init)
;;; init.el ends here
