;;; my-code-ruby.el --- Ruby -*- lexical-binding: t; -*-

(use-package ruby-mode
  :ensure nil
  :mode "\\.\\(?:a?rb\\|aslsx\\)\\'"
  :mode "/\\(?:Brew\\|Fast\\)file\\'"
  :interpreter "j?ruby\\(?:[0-9.]+\\)"
  :hook
  (ruby-ts-mode . eglot-ensure)
  (ruby-mode . eglot-ensure))

(use-package rubocop
  :hook ruby-ts-mode)

(use-package rspec-mode
  :mode ("/\\.rspec\\'" . text-mode))

(use-package inflections)

(provide 'my-code-ruby)
