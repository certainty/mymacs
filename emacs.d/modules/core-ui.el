;;; core-ui.el --- UI configuration: theme, modeline, fonts, icons -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Theme selection (modus-themes, catppuccin), modeline (mood-line),
;; font management (fontaine), ligatures, nerd-icons, and hl-todo.
;;
;;; Code:

(defun my/ui-graphic-p (&optional frame)
  "Return non-nil when FRAME or the selected frame is graphical."
  (display-graphic-p frame))

(defun +font-regular ()
  "Switch to the regular font preset, or reset text scaling in TTY."
  (interactive)
  (if (and (my/ui-graphic-p) (fboundp 'fontaine-set-preset))
      (fontaine-set-preset 'regular)
    (text-scale-set 0)))

(defun +font-bigger ()
  "Toggle larger fonts, or increase text scaling in TTY."
  (interactive)
  (if (and (my/ui-graphic-p) (fboundp 'fontaine-set-preset))
      (if (eq fontaine-current-preset 'bigger)
          (fontaine-set-preset 'regular)
        (fontaine-set-preset 'bigger))
    (text-scale-increase 1)))

(defun +font-presentation ()
  "Toggle presentation fonts, or use a larger text scale in TTY."
  (interactive)
  (if (and (my/ui-graphic-p) (fboundp 'fontaine-set-preset))
      (if (eq fontaine-current-preset 'presentation)
          (fontaine-set-preset 'regular)
        (fontaine-set-preset 'presentation))
    (text-scale-set 3)))

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
  (modus-themes-mixed-fonts (my/ui-graphic-p))
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-variable-pitch-ui (my/ui-graphic-p))
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
                                            (bg-mode-line-active "#0e0e16")
                                            (border-mode-line-active "#0e0e16")
                                            (bg-mode-line-inactive "#060609")
                                            (border-mode-line-inactive "#060609")
                                            (bg-line-number-inactive "#000000")
                                            (bg-line-number-active "#000000")
                                            (bg-hl-line "#111111"))))

  (setopt modus-themes-headings
          (if (my/ui-graphic-p)
              '((1 . (variable-pitch 1.1))
                (t . (1.0)))
            '((1 . (1.0))
              (t . (1.0)))))

  (defun my/adjust-line-number-faces ()
    "Tune line number faces for the current display type."
    (if (my/ui-graphic-p)
        (progn
          (set-face-attribute 'line-number nil :background "#000000")
          (set-face-attribute 'line-number-current-line nil :background "#000000"))
      (set-face-attribute 'line-number nil :background 'unspecified)
      (set-face-attribute 'line-number-current-line nil :background 'unspecified :weight 'bold)))

  (add-hook 'modus-themes-after-load-theme-hook #'my/adjust-line-number-faces))

;;; Catppuccin Theme
(use-package catppuccin-theme
  :demand t
  :no-require t
  :custom
  (catppuccin-flavor 'mocha)
  (catppuccin-italic-comments t)
  (catppuccin-dark-line-numbers-background t)
  :init
  ;; This theme library does not provide `catppuccin-theme'; load its
  ;; autoloads so `custom-theme-load-path' is populated before `load-theme'.
  (load (locate-library "catppuccin-theme-autoloads") nil t)
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
  '((:checker-info . ?ℹ)
    (:checker-issues . ?!)
    (:checker-good . ?✓)
    (:checker-checking . ?↻)
    (:checker-errored . ?✕)
    (:checker-interrupted . ?⏸))
  "Checker glyphs chosen for reliable rendering across GUI and TTY frames.")

(use-package mood-line
  :hook after-init
  :custom
  (mood-line-segment-modal-meow-state-alist
   '((normal . ("\x1f15d " . font-lock-variable-name-face))
     (insert . ("\x1f158 " . font-lock-string-face))
     (keypad . ("\x1f15a " . font-lock-keyword-face))
     (beacon . ("\x1f151 " . font-lock-type-face))
     (motion . ("\x1f15c " . font-lock-constant-face))
     (passthrough . ("T" . font-lock-warning-face))))
  :config
  (let ((glyphs (copy-tree mood-line-glyphs-unicode)))
    (dolist (pair my/mood-line-checker-glyphs)
      (setf (alist-get (car pair) glyphs) (cdr pair)))
    ;; Use a branch glyph for the clean VC state so the mode line reads
    ;; like branch information instead of a checkmark.
    (setf (alist-get :vc-good glyphs) ?)
    (setq mood-line-glyph-alist glyphs)))

;;; Fonts
(use-package fontaine
  :if (my/ui-graphic-p)
  :demand t
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
(use-package nerd-icons)

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
