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

(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold 100000000
      gc-cons-percentage 0.1)))

;; let's use pinned versions
;; (setq straight-profiles
;;   '((nil . "default.el")
;;      (pinned . "pinned.el")))

;; ;; make sure we load pinned versions
;; (autoload #'straight-x-pull-all "straight-x")
;; (autoload #'straight-x-freeze-versions "straight-x")
;; (defalias 'straight-pull-all #'straight-x-pull-all)
;; (defalias 'straight-freeze-versions #'straight-x-freeze-versions)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(use-package diminish :demand t)

(require 'mymacs)

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
(require 'writing-base)
(require 'writing-markdown)
(require 'writing-org)
(require 'writing-notes)

(when (my/context-work-p)
  (require 'writing-asciidoc))

(require 'org-gtd)

(require 'tools-vc)
(require 'tools-secrets)
(require 'tools-terminal)
(require 'tools-rss)

(require 'ai-gptel)

(when (my/context-work-p)
  (use-package consult-pmd
    :straight `(consult-pmd
                 :type nil
                 :local-repo ,(expand-file-name "local-packages/consult-pmd" user-emacs-directory)
                 :files ("*.el"))
    :commands (+pmd-projects +pmd-servicegroups +pmd-teams))
  (require 'tools-gh)
  (require 'ai-copilot))

(provide 'init)
;;; init.el ends here
