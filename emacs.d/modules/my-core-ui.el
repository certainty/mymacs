;;; my-core-ui.el --- Core UI and global defaults -*- lexical-binding: t; -*-

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
        ("p" . nil))
  (:repeat-map my/navigation-repeat-map
               ("n" . forward-line)
               ("p" . previous-line))
  :custom
;;; ui
  (use-short-answers t)
  (ring-bell-function 'ignore)
  (inhibit-startup-screen t)
  (inhibit-startup-message t)
  

;;; editing
  (kill-whole-line t)
  (next-line-add-newlines t)
  (set-mark-command-repeat-pop t)
  (editorconfig-mode t)
  (imenu-auto-rescan t)
  (view-read-only t)
  (column-number-mode t)
  (kill-do-not-save-duplicates t)
  (scroll-error-top-bottom t)

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

  ;; mouse
  (unless (display-graphic-p)
    (xterm-mouse-mode 1))
  (setopt mouse-avoidance-mode 'exile) ;; the mouse goes away on typing

;;; tab settings
  (setq-default indent-tabs-mode nil)
  (setq-default standard-indent 2)
  (setq-default tab-width 2)

;;; default font
  (set-face-attribute
   'default nil
   :font my/font
   :height my/font-height
   :weight my/font-weight)

  (setopt mode-line-compact nil
          mode-line-right-align-edge 'right-margin)

  (setq-default mode-line-format
                '("%e"
                  mode-line-front-space
                  mode-line-modified
                  mode-line-remote
                  " "
                  mode-line-buffer-identification
                  " "
                  "%l:%c"
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
                            '(flymake-mode-line-format "  "))
                        mode-line-misc-info))))
                  mode-line-end-spaces)))

;;; Theme
(use-package modus-themes
  :demand t
  :custom
  (modus-themes-disable-other-themes t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-prompts '(extrabold italic))
  (modus-themes-completions
   '((matches . (extrabold underline))
     (selection . (semibold italic))))
  :preface
  ;; Theme support files live on `custom-theme-load-path', not `load-path'.
  (let ((custom-theme-load-path (cons t custom-theme-load-path)))
    (require-theme 'modus-themes))
  :config
  (setq modus-themes-common-palette-overrides
        '((bg-paren-match bg-magenta-intense)
          (fringe bg-main)
          (bg-space bg-main))
        modus-vivendi-palette-overrides
        '((bg-line-number-active "#000000")
          (bg-line-number-inactive "#000000")
          (bg-mode-line-active "#000000")
          (bg-mode-line-inactive "#000000")))
  (load-theme my/theme t)

  ;; Preserve the custom modeline edge while letting light themes choose
  ;; their own contrasting backgrounds.
  (dolist (face '(mode-line mode-line-active mode-line-inactive))
    (set-face-attribute face nil
                        :box nil
                        :overline "#606060"
                        :underline nil)
    (when (eq my/theme 'modus-vivendi)
      (set-face-attribute face nil :background "#000000"))))

(use-package pulsar
  :ensure t
  :hook
  (after-init . (lambda () (pulsar-global-mode 1)))
  :custom
  (pulsar-delay 0.055)
  (pulsar-iterations 5)
  :config
  ;; `pulsar-pulse-functions' covers `next-error' and `previous-error';
  ;; include Flymake's direct navigation commands as well.
  (dolist (function '(flymake-goto-next-error flymake-goto-prev-error))
    (add-to-list 'pulsar-pulse-functions function))
  ;; Compilation buffers use `next-error-hook' rather than the ordinary
  ;; command mechanism to mark the selected diagnostic.
  (add-hook 'next-error-hook #'pulsar-pulse-line)
  ;; Imenu and Consult jumps can land inside hidden Outline/Org entries.
  (add-hook 'imenu-after-jump-hook #'pulsar-recenter-top)
  (add-hook 'imenu-after-jump-hook #'pulsar-reveal-entry)
  (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
  (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry)
  ;; Pulsar documents this hook for minibuffer feedback.
  (add-hook 'minibuffer-setup-hook #'pulsar-pulse-line))

;;;; outline

(use-package outline
  :hook ((prog-mode . outline-minor-mode)
         (markdown-ts-mode . outline-minor-mode))
  :bind
  (:map outline-minor-mode-map
        ("C-<tab>" . outline-cycle)))

(provide 'my-core-ui)
;;; my-core-ui.el ends here
