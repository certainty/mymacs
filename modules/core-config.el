;;; core-config.el --- Basic configuration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defcustom my/font "Iosevka Nerd Font"
  "Fixed pitch font"
  :type 'string
  :group 'mymacs)

(defcustom my/pitch-font "Iosevka Aile"
  "Variable pitch font"
  :type 'string
  :group 'mymacs)

(defcustom my/font-size 130
  "Default font size to use"
  :type 'integer
  :group 'mymacs)

(defcustom my/bigger-font-size 170
  "Default font size to use"
  :type 'integer
  :group 'mymacs)

(defcustom my/presentation-font-size 210
  "Presentation font size to use"
  :type 'integer
  :group 'mymacs)

(defcustom my/org-path "~/Org"
  "Path to the org files"
  :type 'string
  :group 'mymacs)

(defcustom my/notes-path "~/Notes"
  "Path to the note files"
  :type 'string
  :group 'mymacs)

(define-minor-mode mymacs-mode
  "Minor mode for MYMACS, which gives a home for my customizations and keybindings."
  :global t
  :lighter " λ"
  :keymap (make-sparse-keymap))


(use-package emacs
  :init
  (add-hook 'after-init-hook (lambda () (mymacs-mode 1)))
  (setq-default
   indent-tabs-mode nil
   tab-width 2
   fill-column 150)

  :custom
  (user-full-name "David Krentzlin")
  (custom-file (expand-file-name "custom.el" user-emacs-directory))
  (ring-bell-function 'ignore)
  (use-short-answers t)
  (initial-scratch-message nil)
  (inhibit-startup-screen t)

  (scroll-margin 0)
  (scroll-conservatively 100000)
  (scroll-preserve-screen-position 1)
  :config
  (if (my/featurep 'context/private)
      (setopt user-mail-address "david@krentzlin.me")
    (setopt user-mail-address "david.krentzlin@new-work.se")))

(use-package diminish
  :demand t)

(provide 'core-config)
;;; core-config.el ends here
