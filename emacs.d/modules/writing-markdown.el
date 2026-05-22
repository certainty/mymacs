;;; writing-markdown.el --- Markdown support  -*- lexical-binding: t -*-

;;; Code:

(use-package markdown-mode
  :ensure t
  :init
  (add-hook 'markdown-mode-hook 'eglot-ensure))

(provide 'writing-markdown)
