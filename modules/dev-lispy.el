;;; dev-lispy.el --- lispy languages  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;;; Lispyville - Lisp editing with evil

(with-eval-after-load 'paren
  (setq show-paren-delay 0.1
    show-paren-highlight-openparen t
    show-paren-when-point-inside-paren t
    show-paren-when-point-in-periphery t))

(use-package lispyville
  :hook ((emacs-lisp-mode
           lisp-mode
           clojure-mode
           racket-mode
           scheme-mode)
          . lispyville-mode)
  :config
  (lispyville-set-key-theme '(operators additional slurp/barf-lispy wrap additional-insert commentary additional-movement escape)))

(provide 'dev-lispy)
