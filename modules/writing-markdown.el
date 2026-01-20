;;; writing-markdown.el --- Markdown support  -*- lexical-binding: t -*-

;;; Code:

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
          ("\\.markdown\\'" . markdown-mode)
          ("README\\.md\\'" . gfm-mode))
  :general
  (local-leader-def
    :keymaps 'markdown-mode-map
    "p" 'markdown-preview
    "e" 'markdown-export
    "c" 'markdown-check-refs

    "h" '(:ignore t :which-key "headings")
    "hi" 'markdown-insert-header-dwim
    "h1" 'markdown-insert-header-atx-1
    "h2" 'markdown-insert-header-atx-2
    "h3" 'markdown-insert-header-atx-3

    "i" '(:ignore t :which-key "insert")
    "il" 'markdown-insert-link
    "ii" 'markdown-insert-image
    "ic" 'markdown-insert-code
    "ib" 'markdown-insert-bold
    "it" 'markdown-insert-italic

    "t" '(:ignore t :which-key "table")
    "tt" 'markdown-insert-table
    "ta" 'markdown-table-align)
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
