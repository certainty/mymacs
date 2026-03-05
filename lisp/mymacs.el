;;; mymacs.el ---  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defvar my/context 'private
  "Current context: 'work or 'private.
Set explicitly via environment variable MYMACS_CONTEXT or detected automatically.")

(defun my/detect-context ()
  "Detect whether we're in work or private environment.
Checks MYMACS_CONTEXT environment variable first, then falls back to OS detection."
  (let ((env-context (getenv "MYMACS_CONTEXT")))
    (cond
      (env-context (intern (downcase env-context)))
      ((eq system-type 'darwin) 'work)
      ((eq system-type 'gnu/linux) 'private)
      (t 'private))))

(defun my/context-private-p ()
  (eq my/context 'private))

(defun my/context-work-p ()
  (eq my/context 'work))

(setq my/context (my/detect-context))

(defun my/lookup-password (&rest keys)
  (let ((result (apply #'auth-source-search keys)))
    (if result
      (funcall (plist-get (car result) :secret))
      nil)))

;;; config
(defcustom my/font "Iosevka Nerd Font Mono"
  "Fixed pitch font"
  :type 'string
  :group 'mymacs)

(defcustom my/pitch-font "Iosevka Nerd Font Propo"
  "Variable pitch font"
  :type 'string
  :group 'mymacs)

(defcustom my/font-size 102
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

(defcustom my/automatically-switch-themes nil
  "Switch themes automatically (dark/light)."
  :type 'boolean
  :group 'mymacs)

(defcustom my/org-path "~/Documents/Local/Org"
  "Path to the org files."
  :type 'string
  :group 'mymacs)

(defcustom my/notes-path "~/Documents/Local/Notes"
  "Path to the note files."
  :type 'string
  :group 'mymacs)

(defcustom my/managed-documents-path "~/Documents/Cloud"
  "Path to the managed document files for denote."
  :type 'string
  :group 'mymacs)

(defcustom my/library-path "~/Library"
  "Path to the library"
  :type 'string
  :group 'mymacs)

(defcustom my/elfeed-directory "~/Documents/Local/Archive/Elfeed"
  "Path to the elfeed db directory."
  :type 'string
  :group 'mymacs)

(defcustom my/repositories-path "~/Code"
  "Base path for cloned repositories. Hosts and org/repo paths are mirrored under this root."
  :type 'string
  :group 'mymacs)

(defcustom my/quicklinks nil
  "An alist of bookmarks where each element is of the form (`NAME' . `URL')"
  :group 'mymacs)

(define-minor-mode mymacs-mode
  "Minor mode for MYMACS, which gives a home for my customizations and keybindings."
  :global t
  :lighter " λ"
  :keymap (make-sparse-keymap))

(add-hook 'after-init-hook (lambda () (mymacs-mode 1)))

(provide 'mymacs)
;;; mymacs.el ends here
