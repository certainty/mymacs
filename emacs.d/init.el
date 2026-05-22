;;; init.el --- Main initialization -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Configure package.el, configure use-package, and load core modules.
;; Feature modules are loaded conditionally based on flags in base-config.
;;
;;; Code:

;; Emacs 31 pre-releases such as 31.0.50 can lack `set-local', while newer
;; package releases already call it and `compat' does not backfill it on 31.x.
(unless (fboundp 'set-local)
  (defun set-local (variable value)
    "Make VARIABLE buffer-local and set it to VALUE."
    (set (make-local-variable variable) value)))

(require 'package)

(setopt package-archives
        '(("gnu" . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/"))
        package-archive-priorities
        '(("gnu" . 20)
          ("nongnu" . 10))
        package-install-upgrade-built-in t
        package-check-signature t)

(when (boundp 'package-native-compile)
  (setopt package-native-compile t))

(when (boundp 'package-quickstart)
  (setopt package-quickstart t))

(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

(package-initialize)
(require 'use-package)

(use-package diminish
  :ensure t
  :demand t)

(require 'core-config)
(require 'core-env)
(require 'core-mymacs)
(require 'core-keys)
(require 'core-ui)
(require 'core-tui)
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
  ;; TODO: change name to gtd-basec
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

(when my/ai-remote-agent-enable
  (require 'ai-remote-agent))

(when my/enable-pmd
  (use-package consult-pmd
    :ensure nil
    :load-path "local-packages/consult-pmd"
    :commands (+pmd-projects +pmd-servicegroups +pmd-teams)))

(provide 'init)
;;; init.el ends here
