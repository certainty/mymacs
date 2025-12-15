;;; mad-windows.el --- windows, buffers and frames -*- lexical-binding: t; -*-

;;; Frames
(use-package frame
  :ensure nil
  :hook (before-make-frame . window-divider-mode)
  :general
  (my-ux-keymap
   "w" '("Maximize" . toggle-frame-maximized)
   "W" '("Fullscreen" . toggle-frame-fullscreen))
  :custom
  (confirm-kill-emacs nil)
  (default-frame-alist
   '((undecorated . nil) ;; no title window
     (frame-title-format . nil)
     (internal-border-width . 2)
     (tool-bar-lines . 0)
     (vertical-scroll-bars . nil)
     (horizontal-scroll-bars . nil)))
  (window-divider-default-right-width 1)
  (window-divider-default-bottom-width 1)
  (window-divider-default-places 'right-only))

(use-package transpose-frame
  :general
  (my-window-keymap
   "t" '("transpose" . transpose-frame)
   "r" '("rotate" . rotate-frame-clockwise)))

;;; Windows

(use-package window
  :ensure nil
  :hook (after-init . winner-mode)
  :general
  (my-global-leader-keymap
   "=" '("splith" . split-window-vertically)
   "|" '("split" . split-window-horizontally))
  (my-window-keymap
   "}" '("enlarge" . enlarge-window)
   ">" '("enlargeh" . enlarge-window-horizontally)
   "{" '("shrink" . shrink-window)
   "<" '("shrinkh" . shrink-window-horizontally)
   "=" '("balance" . balance-windows))
  :custom
  ;; I have a wide-screen so I prefer vertical splits to use the real estate
  (split-width-threshold 0)
  (split-height-threshold nil)
  (display-buffer-base-action nil))

(use-package ace-window
  :general
  (my-window-keymap
   "w" '("window" . ace-window)
   "s" '("swap" . ace-swap-window))
  (mymacs-mode-map
   "M-h" '("left" . windmove-left)
   "M-l" '("right" . windmove-right)
   "M-j" '("down" . windmove-down)
   "M-k" '("up" . windmove-up)))

;;; Buffers

(use-package so-long
  :ensure nil
  :hook (after-init . global-so-long-mode))

(use-package uniquify
  :demand t
  :ensure nil
  :custom
  (uniquify-buffer-name-style 'forward)
  (uniquify-strip-common-suffix t)
  (uniquify-separator "/")
  (uniquify-after-kill-buffer-p t)
  (uniquify-ignore-buffers-re "^\\*"))

(use-package whitespace
  :ensure nil
  :general
  (mymacs-mode-map
   "C-c z" '("Delete WS" . delete-trailing-whitespace))
  (my-ux-keymap
   "s" '("Whitespace" . whitespace-mode)))

(use-package revert-buffer-all)

(use-package popper
  :general
  (my-buffer-keymap
   "p" '("popup toggle" . popper-toggle)
   "P" '("popup cycle" . popper-cycle))
  :init
  (setq popper-reference-buffers
    '("\\*Messages\\*"
       "Output\\*$"
       "\\*Async Shell Command\\*"
       help-mode
       compilation-mode))
  (popper-mode +1)
  (popper-echo-mode +1))

(provide 'my-windows)
