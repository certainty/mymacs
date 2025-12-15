;;; my-code-web.el --- Web -*- lexical-binding: t; -*-

(use-package web-mode
  :hook (web-mode . eglot-ensure))

(use-package css-mode
  :ensure nil
  :hook
  (css-mode . eglot-ensure)
  (css-ts-mode . eglot-ensure))

(use-package graphql-ts-mode
  :mode ("\\.graphql\\'" "\\.gql\\'")
  :init
  (with-eval-after-load 'treesit
    (add-to-list 'treesit-language-source-alist
                 '(graphql "https://github.com/bkegley/tree-sitter-graphql"))))

(provide 'my-code-web)
