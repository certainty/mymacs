;;; my-core-ui.el --- Core UI and global defaults -*- lexical-binding: t; -*-

;;; Theme
(use-package kanagawa-themes
  :ensure t
  :pin "melpa"
  :preface
  (setq kanagawa-themes-custom-colors
        '((bg "#000000")
          (bg-gutter "#000000")
          (diff-add "#1f3a2a")
          (diff-delete "#4a252b")
          (diff-change "#243d52")
          (diff-text "#62502f")))
  :config
  (add-to-list 'custom-theme-load-path
               (expand-file-name "vendor" user-emacs-directory)))

(use-package emacs
  :bind
  (:map mymacs-mode-map
        ("C-g" . +escape-dwim)
        ("M-D" . backward-kill-sexp)
        ("C-o" . my/open-line-above-indented)
        ("M-<backspace>" . my/backward-kill-line)
        ("M-z" . zap-up-to-char)
        ("C-^" . just-one-space)
        ("<f5>" . display-line-numbers-mode)
        ("<f6>" . toggle-frame-maximized))
  (:map my/leader-map
        ("<" . indent-rigidly-left-to-tab-stop)
        (">" . indent-rigidly-right-to-tab-stop))
  (:map goto-map
        ("n" . nil)
        ("p" . nil)
        ("<" . pop-to-mark-command)
        ("m" . pop-global-mark))
  (:repeat-map my/navigation-repeat-map
               ("n" . forward-line)
               ("p" . previous-line))
  (:repeat-map my/mark-repeat-map
               ("<" . pop-to-mark-command)
               ("m" . pop-global-mark))

  :custom
;;; ui
  (use-short-answers t)
  (ring-bell-function 'ignore)
  (inhibit-startup-screen t)
  (inhibit-startup-message t)
  (initial-scratch-message ";; Hack the planet!\n\n")

;;; editing
  (kill-whole-line t)
  (next-line-add-newlines t)
  (set-mark-command-repeat-pop t)

  :preface
  (defun +escape-dwim ()
    (interactive)
    (cond
     ((region-active-p)
      (keyboard-quit))
     ((derived-mode-p 'completion-list-mode)
      (delete-completion-window))
     ((> (minibuffer-depth) 0)
      (abort-recursive-edit))
     (t
      (keyboard-quit))))

  (defun my/open-line-above-indented ()
    (interactive)
    (forward-line -1)
    (end-of-line)
    (insert "\n")
    (indent-according-to-mode))

  (defun my/backward-kill-line ()
    "Kills the whole line backwards starting from point"
    (interactive)
    (let ((curr (point)))
      (back-to-indentation)
      (delete-region (point) curr)))

  (defun my/disable-meow-locally ()
    "Disable Meow in the current buffer."
    (when (and (fboundp 'meow-mode)
               (bound-and-true-p meow-mode))
      (meow-mode -1)))

  :init
;;; modes
  (menu-bar-mode -1)
  (when (fboundp 'tool-bar-mode)
    (tool-bar-mode -1))
  (when (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))
  (global-hl-line-mode -1)
  (repeat-mode)
  (delete-selection-mode)
  (global-subword-mode)
  (save-place-mode)
  (unless (display-graphic-p)
    (xterm-mouse-mode 1))

;;; tab settings
  (setq-default indent-tabs-mode nil)
  (setq-default standard-indent 2)
  (setq-default tab-width 2)

;;;; load theme
  (load-theme my/theme)

;;; default font
  (set-face-attribute
   'default nil
   :font my/font
   :height my/font-height
   :weight my/font-weight)


;;;; modeline
  (dolist (m '(mode-line mode-line-active mode-line-inactive))
    (set-face-attribute m nil :background 'unspecified :box nil :overline "gray50" :underline nil))

  (setopt mode-line-compact nil
          mode-line-right-align-edge 'right-margin)

  (setq-default mode-line-format
                '("%e"
                  mode-line-front-space
                  mode-line-modified
                  mode-line-remote
                  " "
                  mode-line-buffer-identification
                  (:eval
                   (when (mode-line-window-selected-p)
                     (format-mode-line
                      '("  " (vc-mode vc-mode)
                        "  " mode-name mode-line-process))))
                  mode-line-format-right-align
                  (:eval
                   (when (mode-line-window-selected-p)
                     (format-mode-line
                      `("  "
                        ,@(when (bound-and-true-p flymake-mode)
                            '(flymake-mode-line-format
                              "  "))
                        mode-line-misc-info))))
                  mode-line-end-spaces)))

(use-package easy-kill
  :ensure t
  :bind
  ([remap mark-sexp] . easy-mark)
  ([remap kill-ring-save] . easy-kill)
  (:map mymacs-mode-map
        ("M-j" . mark-sexp)))

;;;; outline

(use-package outline
  :hook ((prog-mode . outline-minor-mode)
         (markdown-ts-mode . outline-minor-mode))
  :bind
  (:map outline-minor-mode-map
        ("C-<tab>" . outline-cycle)))

(provide 'my-core-ui)
;;; my-core-ui.el ends here
