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

(use-package paredit
  :hook ((emacs-lisp-mode
           lisp-mode
           clojure-mode
           racket-mode
           scheme-mode)
          . paredit-mode))

(with-eval-after-load 'meow
  (my/def-command-with-selection paredit-forward my/paredit-forward-w-selection)
  (my/def-command-with-selection paredit-forward-down my/paredit-forward-down-w-selection)
  (my/def-command-with-selection paredit-backward my/paredit-backward-w-selection)
  (my/def-command-with-selection paredit-backward-up my/paredit-backward-up-w-selection)

  (meow-define-keys 'normal
    '("M-l" . paredit-forward)
    '("M-L" . my/paredit-forward-w-selection)
    '("M-h" . paredit-backward)
    '("M-H" . my/paredit-backward-w-selection)
    '("M-j" . paredit-forward-down)
    '("M-k" . paredit-backward-up)
    '("M-s" . paredit-kill)
    '("M-m" . paredit-join-sexps)
    '("M-r" . paredit-raise-sexp)
    '("|" . paredit-split-sexp)
    '("@" . paredit-splice-sexp)))

(provide 'dev-lispy)
