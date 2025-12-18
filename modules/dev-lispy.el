;;; dev-lispy.el --- lispy languages  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;;; Lispyville - Lisp editing with evil

(use-package lispyville
  :hook (emacs-lisp-mode . lispyville-mode)
  (lisp-mode . lispyville-mode)
  (scheme-mode . lispyville-mode)
  (clojure-mode . lispyville-mode)
  (racket-mode . lispyville-mode)

  :config
  (lispyville-set-key-theme
    '(operators
       c-w
       prettify
       navigation
       slurp/barf-cp
       wrap
       additional
       additional-insert
       additional-wrap
       escape))
  (diminish 'lispyville-mode))

(with-eval-after-load 'paren
  (setq show-paren-delay 0.1
    show-paren-highlight-openparen t
    show-paren-when-point-inside-paren t
    show-paren-when-point-in-periphery t))

(provide 'dev-lispy)
