;;; core-help.el --- Help system -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package helpful
  :bind
  (([remap describe-function] . helpful-callable)
    ([remap describe-variable] . helpful-variable)
    ([remap describe-key] . helpful-key)
    ([remap describe-command] . helpful-command)
    ([remap describe-symbol] . helpful-symbol))
  :custom
  (helpful-max-buffers 2))

;;;; Info mode enhancements
(use-package info
  :straight (:type built-in)
  :custom
  (Info-use-header-line nil))

(provide 'core-help)

;;; core-help.el ends here
