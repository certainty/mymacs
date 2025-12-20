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

(use-package smartparens
  :hook ((emacs-lisp-mode
          lisp-mode
          clojure-mode
          racket-mode
          scheme-mode)
         . smartparens-strict-mode)
  :config
  (sp-pair "'" nil :actions nil))

(use-package evil-cleverparens
  :hook
  (emacs-lisp-mode . evil-cleverparens-mode)
  (lisp-mode . evil-cleverparens-mode)
  (scheme-mode . evil-cleverparens-mode)
  (clojure-mode . evil-cleverparens-mode)
  (racket-mode . evil-cleverparens-mode)
  :config
  (smartparens-strict-mode 1))

(use-package evil-cleverparens
  :after (evil smartparens)
  :hook (smartparens-strict-mode . evil-cleverparens-mode)
  :custom
  (evil-cleverparens-use-regular-motion t)
  :config
  (diminish 'evil-cleverparens-mode))

(provide 'dev-lispy)
