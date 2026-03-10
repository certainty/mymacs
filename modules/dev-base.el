;;; dev-base.el --- Basic Dev Setup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package emacs
  :init
  (my/window-rule! eldoc-mode :align bottom :size 0.3 :select nil)
  (my/with-popper! 'eldoc-mode)

  (my/window-rule! "\\*\\(Backtrace\\|Compile-log\\|Messages\\|Warnings\\)\\*" :align bottom :size 0.3 :select nil)
  (my/with-popper! "\\*\\(Backtrace\\|Compile-log\\|Messages\\|Warnings\\)\\*"))

(use-package eglot
  :straight (:type built-in)
  :commands (eglot eglot-ensure)
  :init
  (setq eglot-stay-out-of '(flymake))
  :custom
  (eglot-report-progress nil)
  (eglot-extend-to-xref t)
  (eglot-autoreconnect 5)
  (eldoc-echo-area-use-multiline-p 1)
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)
  :config
  (fset #'jsonrpc--log-event #'ignore))

;;; Treesitter
(use-package treesit
  :straight (:type built-in)
  :custom
  (treesit-extra-load-path
    (list (expand-file-name "tree-sitter" user-emacs-directory)))
  (treesit-font-lock-level 5)
  :config
  (when (>= emacs-major-version 31)
    (setopt treesit-auto-install-grammar 'always)
    (setopt treesit-enabled-modes t)))


;;; Flymake
(use-package flymake
  :straight (:type built-in)
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-no-changes-timeout 0.5)
  (flymake-start-on-save-buffer t)
  (flymake-error-bitmap '(right-triangle compilation-error))
  (flymake-warning-bitmap '(right-triangle compilation-warning))
  (flymake-note-bitmap '(right-triangle compilation-info))
  (flymake-show-diagnostics-at-end-of-line nil)
  :config
  (diminish 'flymake-mode))

;;;; Consult-Flymake - Consult integration for flymake
(use-package consult-flymake
  :straight (:type built-in)
  :after (consult flymake))


;;; Global dev related settings
(use-package paren
  :straight (:type built-in)
  :hook (prog-mode . show-paren-mode)
  :custom
  (show-paren-delay 0))

(use-package highlight-parentheses
  :hook prog-mode)

(use-package electric-pair
  :straight (:type built-in)
  :hook prog-mode)

(use-package emacs
  :hook
  (makefile-bsdmake-mode . (lambda () (setq-local my/format-on-save-enabled nil)))
  (makefile-mode . (lambda () (setq-local my/format-on-save-enabled nil)))
  (makefile-gmake-mode . (lambda () (setq-local my/format-on-save-enabled nil))))

(provide 'dev-base)
;;; dev-base.el ends here
