;;; core-config.el --- Basic configuration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package emacs
  :custom
  (user-full-name "David Krentzlin")
  (custom-file (expand-file-name "custom.el" user-emacs-directory))

  :init

  (when (my/context-private-p)
    (setopt my/repositories-path "~/Code")
    (setopt user-mail-address "david@krentzlin.me"))

  (when (my/context-work-p)
    (setopt my/org-path "~/Documents/Org" )
    (setopt my/notes-path "~/Documents/Notes")
    (setopt my/managed-documents-path "~/Documents/Work")
    (setopt my/repositories-path "~/NewWork/Code")
    (setopt user-mail-address "david.krentzlin@new-work.se"))

  (when (memq window-system '(mac ns))
    (setopt my/font-size 131)
    (setopt my/bigger-font-size 170)
    (setopt my/presentation-font-size 230)))

(provide 'core-config)
;;; core-config.el ends here
