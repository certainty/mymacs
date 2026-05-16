;;; core-ui.el --- UI configuration: theme, modeline, fonts, icons -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Theme selection (modus-themes, catppuccin), modeline (mood-line),
;; font management (fontaine), ligatures, nerd-icons, and hl-todo.
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
  (initial-major-mode 'lisp-interaction-mode)
  (bidi-inhibit-bpa t)
  (inhibit-compacting-font-caches t)
  (cursor-in-non-selected-windows nil)
  (scroll-margin 0)
  (scroll-conservatively 100000)
  (scroll-preserve-screen-position 1)

  :init
  (setq-default indent-tabs-mode nil
                tab-width 2
                fill-column 150))


;;; Modus Themes
(use-package modus-themes
  :demand t
  :custom
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
  (defun my/modus-defaults-with-overrides (defaults overrides)
    "Merge overrides into defaults. Overriding any defaults."
    (append (cl-remove-if (lambda (x) (member (car x) (mapcar 'car overrides))) defaults) overrides))

  (setq modus-vivendi-palette-overrides
        (my/modus-defaults-with-overrides modus-themes-preset-overrides-faint
                                          `((bg-paren-match bg-magenta-intense)
                                            (underline-paren-match fg-main)
                                            (fg-line-number-active red-cooler)
                                            (bg-main "#000000")
                                            (bg-dim "#000000")
                                            (bg-line-number-inactive "#000000")
                                            (bg-line-number-active "#000000")
                                            (bg-hl-line "#111111"))))

  (setopt modus-themes-headings
          '((1 . (variable-pitch 1.1))
            (t . (1.0))))

  (defun my/adjust-line-number-faces ()
    "Set line number backgrounds to match the theme background."
    (set-face-attribute 'line-number nil :background "#000000")
    (set-face-attribute 'line-number-current-line nil :background "#000000"))

  (add-hook 'modus-themes-after-load-theme-hook #'my/adjust-line-number-faces))

;;; Catppuccin Theme
(use-package catppuccin-theme
  :demand t
  :custom
  (catppuccin-flavor 'mocha)
  (catppuccin-italic-comments t)
  (catppuccin-dark-line-numbers-background t)
  :config
  (defun my/adjust-catppuccin ()
    "Override catppuccin mocha backgrounds: pure black for editing area,
near-black for modeline and gutters."
    (when (eq catppuccin-flavor 'mocha)
      (catppuccin-set-color 'base "#000000")
      (catppuccin-set-color 'mantle "#0e0e16")
      (catppuccin-set-color 'crust "#060609"))
    (my/adjust-line-number-faces)))

;;; Load initial theme
(load-theme my/default-theme :no-confirm)
(when (eq my/default-theme 'catppuccin)
  (my/adjust-catppuccin)
  (catppuccin-reload))
(my/adjust-line-number-faces)

;;; Modeline: Mood-line
(defconst my/mood-line-checker-glyphs
  '((:checker-info . ?\uf05a)
    (:checker-issues . ?\uf071)
    (:checker-good . ?\uf00c)
    (:checker-checking . ?\uf110)
    (:checker-errored . ?\uf00d)
    (:checker-interrupted . ?\uf04c))
  "Checker glyphs mapping to Nerd Font codepoints.")

(use-package mood-line
  :hook after-init
  :custom
  (mood-line-segment-modal-meow-state-alist
   '((normal . ("\x1f15d " . font-lock-variable-name-face))
     (insert . ("\x1f158 " . font-lock-string-face))
     (keypad . ("\x1f15a " . font-lock-keyword-face))
     (beacon . ("\x1f151 " . font-lock-type-face))
     (motion . ("\x1f15c " . font-lock-constant-face))))
  :config
  (let ((glyphs (copy-tree mood-line-glyphs-unicode)))
    (dolist (pair my/mood-line-checker-glyphs)
      (setf (alist-get (car pair) glyphs) (cdr pair)))
    (setq mood-line-glyph-alist glyphs)))

;;; Fonts
(use-package fontaine
  :demand t
  :preface
  (defun +font-regular ()
    "Switch to the regular font preset."
    (interactive)
    (fontaine-set-preset 'regular))

  (defun +font-bigger ()
    "Toggle between regular and bigger font presets."
    (interactive)
    (if (eq fontaine-current-preset 'bigger)
        (fontaine-set-preset 'regular)
      (fontaine-set-preset 'bigger)))

  (defun +font-presentation ()
    "Toggle between regular and presentation font presets."
    (interactive)
    (if (eq fontaine-current-preset 'presentation)
        (fontaine-set-preset 'regular)
      (fontaine-set-preset 'presentation)))

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
  :config
  (when (and (memq window-system '(mac ns))
             (fboundp 'mac-auto-operator-composition-mode))
    (mac-auto-operator-composition-mode))

  (defconst my/ligature-composition-rules
    '((?! . ("!=" "!!" "!!!"))
      (?= . ("==" "=>" "==="))
      (?> . (">=" ">>" ">>>" "->" "=>"))
      (?< . ("<-" "<=" "<<"))
      (?- . ("->" "--" "-<"))
      (?/ . ("//" "/*" "*/" "/="))
      (?| . ("||" "|="))
      (?& . ("&&" "&="))
      (?+ . ("++" "+="))
      (?~ . ("~~" "~="))
      (?: . ("::" ":="))
      (?# . ("###" "##"))
      (?^ . ("^="))
      (?\? . ("??" "?:"))
      (?. . (".." "..."))
      (?\\ . ("\\\\"))
      (?% . ("%%" "%%%"))
      (?' . ("''"))
      (?_ . ("__"))
      (?$ . ("$$"))
      (?@ . ("@@")))
    "Character sequences that should render as ligatures.")

  (defun +enable-font-ligatures (&optional frame)
    "Enable font ligatures for Maple Mono NF in FRAME or the current frame."
    (interactive)
    (let ((target-frame (or frame (selected-frame))))
      (when (display-graphic-p target-frame)
        (with-selected-frame target-frame
          (dolist (rule my/ligature-composition-rules)
            (let* ((char (car rule))
                   (patterns (cdr rule))
                   (table (mapcar (lambda (pattern)
                                    (vector pattern 0 'font-shape-gstring))
                                  patterns)))
              (set-char-table-range composition-function-table char table)))))))

  (+enable-font-ligatures)
  (set-frame-font my/font t)
  (+font-regular))

;;; Nerd Icons
(use-package nerd-icons
  :if (display-graphic-p))

;;; HL-Todo
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
  :config
  (diminish 'hl-todo-mode))

(provide 'core-ui)
;;; core-ui.el ends here
