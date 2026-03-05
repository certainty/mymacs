;;; writing-markdown.el --- Markdown support  -*- lexical-binding: t -*-

;;; Code:

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
          ("\\.markdown\\'" . markdown-mode)
          ("README\\.md\\'" . gfm-mode))
  :custom
  (markdown-command "multimarkdown")
  (markdown-fontify-code-blocks-natively t)
  (markdown-enable-math t)
  (markdown-enable-wiki-links t)
  (markdown-italic-underscore t)
  (markdown-asymmetric-header t)
  (markdown-gfm-additional-languages '("sh" "elisp"))
  (markdown-make-gfm-checkboxes-buttons t)

  :config
  (add-hook 'markdown-mode-hook
    (lambda ()
      (+disable-format-on-save)
      (eglot-ensure)
      (visual-line-mode 1)
      (visual-fill-column-mode 1))))

(provide 'writing-markdown)
