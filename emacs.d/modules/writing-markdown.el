;;; writing-markdown.el --- Markdown support  -*- lexical-binding: t -*-

;;; Code:

(use-package markdown-mode)

(use-package markdown-ts-mode
  :after markdown-mode
  :mode (("\\.md\\'" . markdown-ts-mode)
         ("\\.markdown\\'" . markdown-ts-mode))
  :init
  (with-eval-after-load 'treesit
    (add-to-list 'treesit-language-source-alist
                 '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" nil "tree-sitter-markdown-inline/src")))
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
