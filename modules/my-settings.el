;;; my-settings.el --- Basic settings -*- lexical-binding: t; -*-

(defgroup my nil
  "My mymacs configuration group"
  :prefix "my-"
  :group 'emacs)

(defcustom my-scope 'private
  "The scope of this configuration"
  :type 'symbol
  :options '(private work)
  :group 'my)

(defcustom my-full-name "David Krentzlin"
  "Full username"
  :type 'string
  :group 'my)

(defcustom my-font "Iosevka Nerd Font"
  "Fixed pitch font"
  :type 'string
  :group 'my)

(defcustom my-variable-pitch-font "Iosevka Aile"
  "Variable pitch font"
  :type 'string
  :group 'my)

(defcustom my-font-size 130
    "Default font size to use"
    :type 'integer
    :group 'my)

(defcustom my-font-size-bigger 150
    "Bigger font size to use"
    :type 'integer
    :group 'my)

(defcustom my-font-size-presentation 180
    "Presentation font size to use"
    :type 'integer
    :group 'my)

(when (equal "WORK" (getenv "MYMACS_SCOPE"))
  (setopt my-scope 'work))

(defun my/scope-work-p ()
  "Check if the scope of this configuration is `work`."
  (equal my/scope 'work))

(defun my/scope-private-p ()
  "Check if the scope of this configuration is `private`."
  (equal my/scope 'private))

(provide 'my-settings)
