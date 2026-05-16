;;; core-buffers.el --- Buffer and window management -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; This module manages buffers and windows. It uses Shackle for deterministic
;; window placement and Popper to manage/toggle transient buffers (popups).
;; By disabling Popper's display control, we ensure Shackle is the single
;; source of truth for where windows appear.
;;
;;; Code:

;;; Buffer Management Helpers
(defun +kill-current ()
  "Kill the current buffer without prompting."
  (interactive)
  (kill-buffer (current-buffer)))

(defun +kill-other ()
  "Kill all buffers except the current one."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list)))
  (message "Killed all other buffers"))

(defun +kill-all ()
  "Kill all buffers."
  (interactive)
  (when (yes-or-no-p "Kill all buffers? ")
    (mapc 'kill-buffer (buffer-list))
    (message "Killed all buffers")))

(defun +escape ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.
- When the region is active, disable it.
- When a minibuffer is open, close it.
- When the Completions buffer is selected, close it.
- Otherwise regular `keyboard-quit'."
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

(use-package emacs
  :bind
  (:map mymacs-mode-map
    ("C-g" . +escape)))

;;; Built-in buffer hygiene
(use-package uniquify
  :straight (:type built-in)
  :custom
  (uniquify-buffer-name-style 'forward)
  (uniquify-strip-common-suffix t)
  (uniquify-separator "/")
  (uniquify-after-kill-buffer-p t)
  (uniquify-ignore-buffers-re "^\\*"))

(use-package so-long
  :straight (:type built-in)
  :hook (after-init . global-so-long-mode))

;;; Clean up old buffers automatically
(use-package buffer-terminator
  :hook after-init
  :custom
  (buffer-terminator-verbose nil)
  (buffer-terminator-inactivity-timeout (* 30 60))
  (buffer-terminator-interval (* 10 60)))

;;; Ibuffer
(use-package ibuffer
  :straight (:type built-in)
  :custom
  (ibuffer-expert t)
  (ibuffer-show-empty-filter-groups nil)
  (ibuffer-saved-filter-groups
    '(("default"
        ("Dired" (mode . dired-mode))
        ("Org" (mode . org-mode))
        ("Emacs" (or (name . "^\\*scratch\\*$")
                   (name . "^\\*Messages\\*$")))
        ("Help" (or (mode . helpful-mode)
                  (mode . help-mode)
                  (name . "^\\*Help\\*$")))
        ("Magit" (name . "^magit"))
        ("Programming" (derived-mode . prog-mode))
        ("Text" (derived-mode . text-mode)))))
  :hook (ibuffer-mode . (lambda ()
                          (ibuffer-switch-to-saved-filter-groups "default"))))

;;; Window Management API

(defvar my/popup-bottom-size 0.3
  "Default size for bottom popups.")

(defvar my/popup-side-size 0.3
  "Default size for side popups.")

(defun my/window-rule! (condition)
  (with-eval-after-load 'shackle
    (add-to-list 'shackle-rules condition)))

(defun my/with-popper! (&rest conditions)
  (with-eval-after-load 'popper
    (dolist (condition conditions)
      (add-to-list 'popper-reference-buffers condition))))

(defun my/register-bottom-popup (condition &optional select regexp no-reuse)
  "Register CONDITION as a bottom popup in Shackle and Popper.
If SELECT is non-nil, the window is selected when popped.
If REGEXP is non-nil, CONDITION is treated as a regular expression."
  (my/window-rule!
    (append
      (list condition :align 'bottom :size my/popup-bottom-size :select select :reuse (not no-reuse))
      (when regexp (list :regexp t))))

  (my/with-popper! condition))

(defun my/register-side-popup (condition &optional select regexp no-reuse)
  "Register CONDITION as a side popup in Shackle and Popper.
If SELECT is non-nil, the window is selected when popped.
If REGEXP is non-nil, CONDITION is treated as a regular expression."
  (my/window-rule!
    (append (list condition :align 'right :size my/popup-side-size :select select :reuse (not no-reuse))
      (when regexp (list :regexp t))))

  (my/with-popper! condition))

;;; Window Management: Shackle (Placement) + Popper (Toggling)
(use-package shackle
  :demand t
  :config
  (shackle-mode 1)
  ;; Shackle is the absolute authority on where popups open.
  (my/register-side-popup 'info-mode)
  (my/register-side-popup 'help-mode)
  (my/register-side-popup 'helpful-mode)
  (my/register-side-popup 'compilation-mode t)
  (my/register-bottom-popup 'org-capture-mode t)
  (my/register-bottom-popup "\\*Messages\\*" nil t)
  (my/register-bottom-popup "\\*Warnings\\*" nil t)
  (my/register-bottom-popup "Output\\*$" nil t)
  (my/register-bottom-popup "\\*Async Shell Command\\*" nil t)
  (my/register-bottom-popup "\\*Completions\\*" nil t)
  (my/register-bottom-popup "\\*Backtrace\\*" t t))

(use-package popper
  :hook (after-init . popper-mode)
  :custom
  ;; Crucial: Set display control to nil so Popper only tracks/toggles buffers,
  ;; while Shackle (above) is allowed to handle the actual placement rules.
  (popper-display-control nil)
  :bind
  (:map mymacs-mode-map
    ("C-/" . popper-toggle)
    ("M-/" . popper-cycle)
    ("C-M-/" . popper-toggle-type))
  :config
  (popper-echo-mode 1)
  (diminish 'popper-mode))

(defun +split-vertically ()
  "Split the window to the right and focus it."
  (interactive)
  (split-window-right)
  (windmove-right))

(defun +split-horizontally ()
  "Split the window below and focus it."
  (interactive)
  (split-window-below)
  (windmove-down))

;;; Window actions
(use-package ace-window
  :commands (ace-window ace-swap-window)
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(provide 'core-buffers)
;;; core-buffers.el ends here
