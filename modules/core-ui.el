;;; core-ui.el ---  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package emacs
  :custom
  (ring-bell-function 'ignore)
  (use-short-answers t)
  (frame-inhibit-implied-resize nil)
  (frame-title-format "\n")
  (inhibit-startup-screen t)
  (inhibit-startup-message t)
  (inhibit-splash-screen t)
  (initial-scratch-message nil)
  (tool-bar-mode nil)
  (scroll-bar-mode nil)
  (initial-major-mode 'fundamental-mode)
  (bidi-inhibit-bpa t)
  (inhibit-compacting-font-caches t)
  (cursor-in-non-selected-windows nil)
  (scroll-margin 0)
  (scroll-conservatively 100000)
  (scroll-preserve-screen-position 1)

  :init
  (setq-default
    indent-tabs-mode nil
    tab-width 2
    fill-column 150)

;;; is writting by my night theme switcher gnome extension
;;; via run command:  (defvar my/gnome-theme-file "~/.cache/gnome-theme")
  (defvar my/gnome-theme-change-hook nil
    "Hook run when the GNOME light/dark theme changes.
Functions are called with one argument: either 'light or 'dark.")

  (defvar my/gnome-theme-file "~/.cache/gnome-theme")

  (defun my/read-gnome-theme-file ()
    (when (file-exists-p my/gnome-theme-file)
      (string-trim (with-temp-buffer
                     (insert-file-contents my/gnome-theme-file)
                     (buffer-string)))))

  (defun my/gnome-theme-from-file ()
    (if (string= (my/read-gnome-theme-file) "'prefer-dark'")
      'dark
      'light))

  (defun my/gnome-theme-file-changed (_event)
    (let ((current-theme (my/gnome-theme-from-file))))
    (run-hook-with-args
      'my/gnome-theme-change-hook
      (my/gnome-theme-from-file)))

  (when (and (my/context-private-p) my/automatically-switch-themes)
    (require 'filenotify)
    (file-notify-add-watch
      my/gnome-theme-file
      '(change)
      #'my/gnome-theme-file-changed)))

;; Mode-line: Mood-line
(use-package mood-line
  :hook after-init
  :custom
  (mood-line-glyph-alist mood-line-glyphs-unicode)
  (mood-line-segment-modal-evil-state-alist
    '((normal  . ("🅝" . font-lock-variable-name-face))
       (insert  . ("🅘" . font-lock-string-face))
       (visual  . ("🅥" . font-lock-keyword-face))
       (replace . ("🅡" . font-lock-type-face))
       (motion  . ("🅜" . font-lock-constant-face))
       (operator . ("🅞" . font-lock-function-name-face))
       (emacs   . ("🄴" . font-lock-builtin-face)))))

(use-package modus-themes
  :demand t
  :general
  (leader-def
    "tt" 'modus-themes-toggle)
  :custom
  (modus-themes-to-toggle '(modus-vivendi modus-operandi))
  (modus-themes-mode-line '(moody))
  (modus-themes-custom-auto-reload t)
  (modus-themes-disable-other-themes nil)
  (modus-themes-mixed-fonts t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-variable-pitch-ui t)
  (modus-themes-prompts '(extrabold italic))
  (modus-themes-paren-match '(bold intense))
  (modus-themes-org-blocks 'tinted-background)
  (modus-themes-completions
    '((matches . (extrabold underline))
       (selection . (semibold italic))))
  :config

  (when my/automatically-switch-themes
    (add-hook 'my/gnome-theme-change-hook
      (lambda (theme)
        (if (eq theme 'dark)
          (modus-themes-select-dark 'modus-vivendi)
          (modus-themes-select-light 'modus-operandi)))))

  (defun my/modus-defaults-with-overrides (defaults overrides)
    "Merge overrides into defaults. Overriding any defaults."
    (append (cl-remove-if (lambda (x) (member (car x) (mapcar 'car overrides))) defaults) overrides))

  ;; I prefer a less vibrant version of the theme (less greenish)
  (setq modus-vivendi-palette-overrides
    (my/modus-defaults-with-overrides modus-themes-preset-overrides-faint
      `((bg-paren-match bg-magenta-intense)
         (underline-paren-match fg-main)
         (fg-line-number-active red-cooler))))

  (setopt modus-themes-headings
    '((1 . (variable-pitch 1.1))
       (t . (1.0))))

  (let ((initial-theme
          (if (and (my/context-private-p) my/automatically-switch-themes)
            (let ((current (my/gnome-theme-from-file)))
              (if (eq current 'dark)
                'modus-vivendi
                'modus-operandi))
            'modus-vivendi)))

    (load-theme initial-theme :no-confirm)))

;;; Fonts
(use-package fontaine
  :hook after-init
  :general
  (leader-def
    "tf" '(:ignore t :which-key "font")
    "tfa" 'text-scale-adjust
    "tff" '(my/toggle-font-bigger :which-key "bigger")
    "tfp" '(my/toggle-font-presentation :which-key "presentation"))
  :custom
  (x-underline-at-descent-line nil)
  (fontaine-presets
    `((regular)
       (bigger
         :default-height ,my/bigger-font-size)
       (presentation
         :default-height ,my/presentation-font-size)
       (t
         :default-family ,my/font
         :default-weight medium
         :default-slant normal
         :default-height ,my/font-size

         :fixed-pitch-family ,my/font
         :fixed-pitch-height 1.0
         :fixed-pitch-serif-height 1.0

         :variable-pitch-family ,my/pitch-font
         :variable-pitch-height 1.0)))

  :preface
  (defun my/toggle-font-bigger ()
    (interactive)
    (if (eq fontaine-current-preset 'bigger)
      (fontaine-set-preset 'regular)
      (fontaine-set-preset 'bigger)))

  (defun my/toggle-font-presentation ()
    (interactive)
    (if (eq fontaine-current-preset 'presentation)
      (fontaine-set-preset 'regular)
      (fontaine-set-preset 'presentation)))

  :config
  (fontaine-set-preset 'regular)
  (diminish 'fontaine-mode))

;;;; Nerd Icons
(use-package nerd-icons
  :if (display-graphic-p))

;;;; HL-TODO - Highlight keywords in comments
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :custom
  (hl-todo-keyword-faces
    '(("TODO"    . "#88C0D0")
       ("FIXME"   . "#BF616A")
       ("NOTE"    . "#EBCB8B")
       ("HACK"    . "#D08770")
       ("REVIEW"  . "#A3BE8C")
       ("DISCUSS" . "#B48EAD")
       ("XXX"     . "#BF616A")
       ("TEMP"    . "#D08770")
       ("DEBUG"   . "#EBCB8B")))
  :general
  (leader-def
    "sH" 'hl-todo-occur
    "sT" 'hl-todo-next
    "sP" 'hl-todo-previous)
  :config
  (diminish 'hl-todo-mode))

(provide 'core-ui)
;;; core-ui.el ends here
