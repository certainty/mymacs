;;; core-tui.el --- Terminal-specific UI tuning -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Keep terminal Emacs intentional and attractive without changing the GUI
;; experience.  This module only adjusts behavior when running on a text
;; terminal.
;;
;;; Code:

(use-package emacs
  :if (not (display-graphic-p))
  :init
  (xterm-mouse-mode 1)
  :config
  (defconst my/tui-border-glyph-candidates
    '(?\s ?▕ ?│ ?┃ ?¦ ?|)
    "Preferred glyphs for terminal window borders, in fallback order.")

  (defun my/tui--display-table-glyph (char &optional face)
    "Return a display table glyph vector for CHAR using FACE."
    (vector (if face
                (make-glyph-code char face)
              char)))

  (defun my/tui-border-glyph ()
    "Return the best available glyph for terminal window borders."
    (or (seq-find #'char-displayable-p my/tui-border-glyph-candidates)
        ?|))

  (defun my/tui-refresh-ui ()
    "Apply terminal-specific face and border tuning."
    (unless standard-display-table
      (setq standard-display-table (make-display-table)))

    (set-display-table-slot standard-display-table 'vertical-border
                            (my/tui--display-table-glyph
                             (my/tui-border-glyph)
                             'vertical-border))
    (set-display-table-slot standard-display-table 'truncation
                            (my/tui--display-table-glyph ?… 'shadow))
    (set-display-table-slot standard-display-table 'wrap
                            (my/tui--display-table-glyph ?↩ 'shadow))

    (set-face-attribute 'mode-line nil :box nil :inverse-video nil)
    (set-face-attribute 'mode-line-inactive nil :box nil :inverse-video nil)
    (set-face-attribute 'header-line nil :box nil)
    (set-face-attribute 'vertical-border nil
                        :foreground "brightblack"
                        :background "brightblack")
    (set-face-attribute 'window-divider nil
                        :foreground "brightblack"
                        :background "brightblack")
    (set-face-attribute 'window-divider-first-pixel nil
                        :foreground "brightblack"
                        :background "brightblack")
    (set-face-attribute 'window-divider-last-pixel nil
                        :foreground "brightblack"
                        :background "brightblack")
    (set-face-attribute 'fringe nil :background 'unspecified)
    (set-face-attribute 'line-number nil :background 'unspecified)
    (set-face-attribute 'line-number-current-line nil
                        :background 'unspecified
                        :weight 'bold))

  (add-hook 'tty-setup-hook #'my/tui-refresh-ui)
  (with-eval-after-load 'modus-themes
    (add-hook 'modus-themes-after-load-theme-hook #'my/tui-refresh-ui))
  (my/tui-refresh-ui))

(provide 'core-tui)
;;; core-tui.el ends here
