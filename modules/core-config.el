;;; core-config.el --- Basic configuration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defcustom my/font "Iosevka Nerd Font Mono"
  "Fixed pitch font"
  :type 'string
  :group 'mymacs)

(defcustom my/pitch-font "Iosevka Nerd Font Propo"
  "Variable pitch font"
  :type 'string
  :group 'mymacs)

(defcustom my/font-size 110
  "Default font size to use"
  :type 'integer
  :group 'mymacs)

(defcustom my/bigger-font-size 140
  "Default font size to use"
  :type 'integer
  :group 'mymacs)

(defcustom my/presentation-font-size 210
  "Presentation font size to use"
  :type 'integer
  :group 'mymacs)

(defcustom my/org-path "~/Org"
  "Path to the org files."
  :type 'string
  :group 'mymacs)

(defcustom my/notes-path "~/Notes"
  "Path to the note files."
  :type 'string
  :group 'mymacs)

(define-minor-mode mymacs-mode
  "Minor mode for MYMACS, which gives a home for my customizations and keybindings."
  :global t
  :lighter " λ"
  :keymap (make-sparse-keymap))


(use-package emacs
  :custom
  (user-full-name "David Krentzlin")
  (custom-file (expand-file-name "custom.el" user-emacs-directory))

  :init
  (add-hook 'after-init-hook (lambda () (mymacs-mode 1)))

  (when (my/featurep 'context/private)
    (setopt user-mail-address "david@krentzlin.me"))

  (when (my/featurep 'context/work)
    (setopt user-mail-address "david.krentzlin@new-work.se"))

  (when (memq window-system '(mac ns))
    (setopt my/pitch-font "Iosevka Aile")
    (setopt my/font-size 130)
    (setopt my/bigger-font-size 170)
    (setopt my/presentation-font-size 230)))

(use-package diminish
  :demand t)

(provide 'core-config)
;;; core-config.el ends here
