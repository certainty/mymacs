;;; my-writing-tools.el --- writing tools -*- lexical-binding: t; -*-

(use-package writegood-mode
  :hook
  (text-mode . writegood-mode))

(provide 'my-writing-tools)
