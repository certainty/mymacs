;;; my-ui.el --- user interface configuration -*- lexical-binding: t; -*-

;;; Display elements

(use-package emacs
  :ensure nil
  :custom
  (frame-inhibit-implied-resize nil)
  (frame-title-format "\n")
  (initial-scratch-message nil)
  (tool-bar-mode nil)
  (scroll-bar-mode nil)
  (initial-major-mode 'fundamental-mode))

;;; Fonts
(use-package fontaine
  :diminish fontaine-mode
  :hook elpaca-after-init
  :custom
  (x-underline-at-descent-line nil)
  (fontaine-presets
   `((regular)
     (bigger :default-height ,my-font-size-bigger)
     (presentation :default-height ,my-font-size-presentation)
     (t
      :default-family ,my-font
      :default-weight regular
      :default-slant normal
      :default-height ,my-font-size

      :fixed-pitch-family ,my-font
      :fixed-pitch-height ,my-font-size
      :fixed-pitch-serif-height ,my-font-size

      :variable-pitch-family ,my-variable-pitch-font
      :variable-pitch-height ,my-font-size)))

  :config
  (defun my/regular-font ()
    (interactive)
    (fontaine-set-preset 'regular))

  (defun my/bigger-font ()
    (interactive)
    (fontaine-set-preset 'bigger))

  (defun my/presentation-font ()
    (interactive)
    (fontaine-set-preset 'presentation))
    (fontaine-mode 1)

  (my/bind-ux-map
   "f"  '(:ignore t :which-key "+font")
   "f+" '("bigger" . my/bigger-font)
   "fr" '("regular" . my/regular-font)
   "fp" '("bigger" . my/presentation-font))

  (fontaine-set-preset 'regular))

;;; Theme
(use-package modus-themes
  :ensure nil
  :demand t
  :custom
  (modus-themes-to-toggle '(modus-vivendi modus-operandi))
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
  (modus-themes-common-palette-overrides
   '((fg-line-number-inactive "gray50")
     (bg-line-number-inactive unspecified)
     (bg-line-number-active unspecified)
     (fringe "#111111")))
  :init
  (load-theme 'modus-vivendi :no-confirm))

;;; Spacious padding
(use-package spacious-padding
  :demand t
  :config
  (spacious-padding-mode 1)
  :custom
  (spacious-padding-subtle-frame-lines
   '(:mode-line-active spacious-padding-line-active
     :mode-line-inactive spacious-padding-line-inactive
     :header-line-active spacious-padding-line-active
     :header-line-inactive spacious-padding-line-inactive)))

;;; Icons
(use-package nerd-icons)

;;; Modeline

(use-package doom-modeline
  :demand t
  :after spacious-padding
  :custom
  (doom-modeline-bar-width 0)
 
  :custom-face
  (doom-modeline-bar ((t (:background "#000000" :foreground "#000000"))))

  :config
  (doom-modeline-mode 1))

(provide 'my-ui)
