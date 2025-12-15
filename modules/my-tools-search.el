;;; my-tools-search.sel --- search -*- lexical-binding: t; -*-
(use-package p-search
  :ensure (p-search :host github :repo "zkry/p-search")
  :general
  (search-map
   "x" '("p-search" . p-search))
  :config
  (require 'p-search-x-denote))

(provide 'my-tools-search)
