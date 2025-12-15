;;; my-code-eglot.el --- Trusty LSP -*- lexical-binding: t; -*-

;;; Eglot
(use-package eglot
  :ensure nil
  :general
  (my-lsp-keymap
   "R" '("reconnect" . eglot-reconnect)
   "q" '("quit" . eglot-shutdown-all)
   "c" '("config" . eglot-show-workspace-configuration)
   "a" '("actions" . eglot-code-actions)
   "F" '("format" . eglot-format-buffer)
   "f" '("quickfix" . eglot-code-action-quickfix)
   "re" '("extract" . eglot-code-action-extract)
   "ri" '("extract" . eglot-code-action-inline)
   "rr" '("extract" . eglot-code-action-rewrite))

  (my-buffer-keymap
   "F" '("format" . eglot-format-buffer))

  (my-point-leader-keymap
   "r" '("rename" . eglot-rename)
   "a" '("code action" . eglot-code-actions)
   "f" '("quickfix" . eglot-code-actions-quickfix))

  (eglot-mode-map
   "M-g e a" '("apropos" . xref-find-apropos)
   "M-g e d" '("definition" . xref-find-definitions)
   "M-g e i" '("implementation" . eglot-find-implementation))

  :custom
  (eglot-report-progress t)
  (eglot-extend-to-xref t)
  (eglot-autoreconnect 5)
  (max-mini-window-height 5)
  (eldoc-echo-area-use-multiline-p 1))

(provide 'my-code-eglot)
