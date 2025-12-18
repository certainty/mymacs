;;; dev-base.el --- Basic Dev Setup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

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
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)

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
  :custom
  (treesit-font-lock-level 5)
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

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
  :config
  (diminish 'flymake-mode))

;;;; Consult-Flymake - Consult integration for flymake
(use-package consult-flymake
  :straight nil
  :after (consult flymake)
  :defer t)

;;; Format
(use-package apheleia
  :defer 2
  :general
  (leader-def
    "to" 'apheleia-mode
    "tO" 'apheleia-global-mode)
  :config
  (apheleia-global-mode +1)
  (diminish 'apheleia-mode)

  (setf (alist-get 'prettier apheleia-formatters)
    '("prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'black apheleia-formatters)
    '("black" "-"))
  (setf (alist-get 'rustfmt apheleia-formatters)
    '("rustfmt" "--edition" "2021" "--emit" "stdout"))
  (setf (alist-get 'gofmt apheleia-formatters)
    '("gofmt"))
  (setf (alist-get 'shfmt apheleia-formatters)
    '("shfmt" "-i" "2" "-"))
  (setf (alist-get 'typescript-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'javascript-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'js-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'js-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'json-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'json-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'css-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'css-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'html-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'python-mode apheleia-mode-alist) 'black)
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) 'black)
  (setf (alist-get 'rust-mode apheleia-mode-alist) 'rustfmt)
  (setf (alist-get 'rust-ts-mode apheleia-mode-alist) 'rustfmt)
  (setf (alist-get 'go-mode apheleia-mode-alist) 'gofmt)
  (setf (alist-get 'go-ts-mode apheleia-mode-alist) 'gofmt)
  (setf (alist-get 'sh-mode apheleia-mode-alist) 'shfmt)
  (setf (alist-get 'bash-ts-mode apheleia-mode-alist) 'shfmt))


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

(provide 'dev-base)
;;; dev-base.el ends here
