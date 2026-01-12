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
  :custom
  (eglot-report-progress t)
  (eglot-extend-to-xref t)
  (eglot-autoreconnect 5)
  (eldoc-echo-area-use-multiline-p 1)
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)

  :config
  (fset #'jsonrpc--log-event #'ignore)

  :general
  (leader-def
    :keymaps 'eglot-mode-map
    "c" '(:ignore t :which-key "code")
    "cl" 'eglot
    "cr" 'eglot-rename
    "cf" 'eglot-format
    "ca" 'eglot-code-actions
    "cd" 'xref-find-definitions
    "cD" 'xref-find-references
    "ci" 'eglot-find-implementation
    "ct" 'eglot-find-typeDefinition
    "cR" 'eglot-reconnect
    "cQ" 'eglot-shutdown
    "cS" 'eglot-shutdown-all)

  :bind
  (:map eglot-mode-map
    ("M-g e a" . xref-find-apropos)
    ("M-g e d" . xref-find-definitions)
    ("M-g e r" . eglot-rename)
    ("M-g e i" . eglot-find-implementation)
    ("M-g e D" . eglot-find-declaration)
    ("M-g e t" . eglot-find-typeDefinition)))

;;; Treesitter
(use-package treesit-auto
  :hook (after-init . global-treesit-auto-mode)
  :custom
  (treesit-font-lock-level 5)
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all))

;;; Flymake
(use-package flymake
  :straight (:type built-in)
  :hook (prog-mode . flymake-mode)
  :general
  (leader-def
    :keymaps 'flymake-mode-map
    "!" '(:ignore t :which-key "diagnostics")
    "!!" 'consult-flymake
    "!l" 'flymake-show-buffer-diagnostics
    "!L" 'flymake-show-project-diagnostics
    "!n" 'flymake-goto-next-error
    "!p" 'flymake-goto-prev-error)
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
  :after (consult flymake)
  :defer t)


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
