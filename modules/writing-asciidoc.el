;;; writing-asciidoc.el --- ascii doc -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:


(use-package adoc-mode
  :mode (("\\.adoc\\'" . adoc-mode)
          ("\\.asciidoc\\'" . adoc-mode))
  :hook
  (adoc-mode . visual-line-mode)
  (adoc-mode . visual-fill-column-mode)
  :bind
  (:map adoc-mode-map
    ("C-c v" . adoc-preview-buffer))
  :custom
  (adoc-fontify-code-blocks-natively t))

(provide 'writing-asciidoc)
