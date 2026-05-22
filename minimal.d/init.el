;; -*- lexical-binding: t; -*-

(setopt custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

(load-theme 'modus-vivendi-tinted)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)


(repeat-mode 1)

;; completion

;;(icomplete-vertical-mode 1)

