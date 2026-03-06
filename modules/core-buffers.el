;;; core-buffers.el --- Buffer management -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

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

(use-package uniquify
  :straight (:type built-in)
  :custom
  (uniquify-buffer-name-style 'forward)
  (uniquify-strip-common-suffix t)
  (uniquify-separator "/")
  (uniquify-after-kill-buffer-p t)
  (uniquify-ignore-buffers-re "^\\*"))

;;; Tame the windows with shackle and popper

(use-package shackle
  :hook after-init
  :preface
  (cl-defmacro my/window-rule! (&body args)
    `(with-eval-after-load 'shackle (add-to-list 'shackle-rules '(,@args))))

  :custom
  (shackle-rules
    '((info-mode :align right :size 0.3 :select nil)
       (help-mode :align right :size 0.3 :select nil)
       (helpful-mode :align right :size 0.3 :select nil)
       (compilation-mode :align bottom :size 0.3 :select t)
       (org-capture-mode :align bottom :size 0.3 :select t))))

(use-package popper
  :hook after-init

  :preface
  (cl-defun my/with-popper! (&rest config)
    (with-eval-after-load 'popper
      (cl-dolist (c config)
        (add-to-list 'popper-reference-buffers c))))

  :custom
  (popper-reference-buffers
    '("\\*Messages\\*"
       "\\*Warnings\\*"
       "Output\\*$"
       "\\*Async Shell Command\\*"
       "\\*compilation\\*"
       "\\*Completions\\*"
       "\\*Backtrace\\*"
       help-mode
       helpful-mode
       compilation-mode))
  (popper-display-control 'user)
  :config
  (global-set-key (kbd "C-/") #'popper-toggle)
  (popper-echo-mode 1)
  (diminish 'popper-mode))

;;;; Ibuffer - Advanced buffer list
(use-package ibuffer
  :straight (:type built-in)
  :custom
  (ibuffer-expert t)
  (ibuffer-show-empty-filter-groups nil)
  (ibuffer-saved-filter-groups
    '(("default"
        ("Org" (mode . org-mode))
        ("Dired" (mode . dired-mode))
        ("Emacs" (or (name . "^\\*scratch\\*$")
                   (name . "^\\*Messages\\*$")
                   (name . "^\\*dashboard\\*$")))
        ("Help" (or (mode . helpful-mode)
                  (mode . help-mode)
                  (name . "^\\*Help\\*$")))
        ("Magit" (name . "^magit"))
        ("Programming" (derived-mode . prog-mode))
        ("Text" (derived-mode . text-mode)))))
  :hook (ibuffer-mode . (lambda ()
                          (ibuffer-switch-to-saved-filter-groups "default"))))

;;;  Handle big buffers
(use-package so-long
  :straight (:type built-in)
  :hook (after-init . global-so-long-mode))

(use-package emacs
  :bind
  (:map mymacs-mode-map
    ("C-g" . +escape))
  :preface
  (defun +escape ()
    "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
    (interactive)
    (cond
      ((region-active-p)
        (keyboard-quit))
      ((derived-mode-p 'completion-list-mode)
        (delete-completion-window))
      ((> (minibuffer-depth) 0)
        (abort-recursive-edit))
      (t
        (keyboard-quit)))))

(use-package visual-fill-column-mode
  :straight (:type built-in)
  :custom
  (visual-fill-column-width 250)
  (visual-fill-column-inhibit-sensible-window-split t)
  (visual-fill-column-fringes-outside-margins t)

  :init
  (defun +center-window ()
    (interactive)
    (if (bound-and-true-p visual-fill-column-mode)
      (progn
        (setq-local visual-fill-column-center-text nil)
        (display-line-numbers-mode 1)
        (visual-fill-column-mode -1))
      (progn
        (setq-local visual-fill-column-center-text t)
        (display-line-numbers-mode -1)
        (visual-fill-column-mode 1)))))


;;; Windows
(use-package ace-window
  :commands (ace-window ace-swap-window))

(defun +split-vertically ()
  "Split the window to the right and focus it."
  (interactive)
  (split-window-right)
  (windmove-right))

(defun +split-horizontally ()
  "Split the window below and focus it"
  (interactive)
  (split-window-below)
  (windmove-down))

(provide 'core-buffers)
;;; buffers.el ends here
