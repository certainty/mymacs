;;; writing-asciidoc.el --- ascii doc -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:


(use-package adoc-mode
  :mode (("\\.adoc\\'" . adoc-mode)
          ("\\.asciidoc\\'" . adoc-mode))
  :hook
  (adoc-mode . visual-line-mode)
  (adoc-mode . l-visual-fill-column-mode)
  :general
  (local-leader-def
    :keymaps 'adoc-mode-map
    "h" '(:ignore t :which-key "headings")
    "h1" 'adoc-adjust-title-del
    "h2" 'adoc-adjust-title-del

    "i" '(:ignore t :which-key "insert")
    "il" 'adoc-insert-link
    "ii" 'adoc-insert-image)
  :custom
  (adoc-fontify-code-blocks-natively t))

(provide 'writing-asciidoc)
