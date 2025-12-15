;;; my-code-treesitter.el --- TS -*- lexical-binding: t; -*-

(use-package treesit-auto
  :hook (elpaca-after-init . global-treesit-auto-mode)
  :custom
  (treesit-font-lock-level 5) ;; make sure we get the elements highlighted we're interested in
  (treesit-auto-install 'prompt)
  (treesit-language-source-alist
    '((elisp "https://github.com/Wilfred/tree-sitter-elisp")
      (common-lisp "https://github.com/theHamsta/tree-sitter-commonlisp"))
      (markdown "https://github.com/ikatyang/tree-sitter-markdown")
      (bash "https://github.com/tree-sitter/tree-sitter-bash/"))
  (treesit-auto-langs '(ruby go gosum csv scala rust typescript tsx javascript yaml dockerfile json html css lua elisp)))

(provide 'my-code-treesitter)
