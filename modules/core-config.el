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
  (add-hook 'after-init-hook (lambda () (mymacs-mode 1)))

  (when (my/context-private-p)
    (setopt user-mail-address "david@krentzlin.me"))

  (when (my/context-work-p)
    (setopt user-mail-address "david.krentzlin@new-work.se"))

  (when (memq window-system '(mac ns))
    (setopt my/pitch-font "Iosevka Aile")
    (setopt my/font-size 130)
    (setopt my/bigger-font-size 170)
    (setopt my/presentation-font-size 230)))

(provide 'core-config)
;;; core-config.el ends here
