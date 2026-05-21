;;; core-help.el --- Help system enhancements -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Small tweaks for the built-in help system.
;;
;;; Code:

;;; Info mode enhancements
(use-package info
  :straight (:type built-in)
  :custom
  (Info-use-header-line nil))

(provide 'core-help)
;;; core-help.el ends here
