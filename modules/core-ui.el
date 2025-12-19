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
  (scroll-margin 0)
  (scroll-conservatively 100000)
  (scroll-preserve-screen-position 1)

  :init
  (setq-default
    indent-tabs-mode nil
    tab-width 2
    fill-column 150))

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t
    doom-themes-enable-italic t)
  (load-theme 'doom-nord t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

;;;; Doom Modeline
(use-package doom-modeline
  :demand t
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 25)
  (doom-modeline-bar-width 0)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-indent-info nil)
  (doom-modeline-vcs-max-length 12)
  (doom-modeline-workspace-name t)
  (doom-modeline-persp-name t)
  (doom-modeline-lsp t)
  (doom-modeline-github nil)
  (doom-modeline-modal-icon t)
  (doom-modeline-env-version t))

;;; Fonts
(use-package fontaine
  :demand t
  :general
  (leader-def
    "tf" '(:ignore t :which-key "font")
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
         :default-weight regular
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
  (fontaine-mode 1)
  (fontaine-set-preset 'regular)
  (diminish 'fontaine-mode))

;;;; Spacious Padding
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

;;;; Nerd Icons
(use-package nerd-icons
  :demand t
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
  (global-hl-todo-mode 1)
  (diminish 'hl-todo-mode))

(provide 'core-ui)
;;; core-ui.el ends here
