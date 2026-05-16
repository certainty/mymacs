;;; writing-markdown.el --- Markdown support  -*- lexical-binding: t -*-

;;; Code:

(use-package markdown-ts-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-command "multimarkdown")
  (markdown-fontify-code-blocks-natively t)
  (markdown-enable-math t)
  (markdown-enable-wiki-links t)
  (markdown-italic-underscore t)
  (markdown-asymmetric-header t)

  :config
  (add-hook 'markdown-ts-mode-hook
            (lambda ()
              (+disable-format-on-save)
              ;;(eglot-ensure)
              )))

(provide 'writing-markdown)
