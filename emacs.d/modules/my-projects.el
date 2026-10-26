;;; my-projects.el --- Projects and version control -*- lexical-binding: t; -*-

;;; Projects
(use-package project
  :bind
  (:map my/leader-map
        ("f" . project-find-file)
        ("e" . project-dired)
        (";" . project-compile))
  (:map my/project-prefix-map
        ("p" . project-switch-project)
        ("j" . my/notes-capture-project)
        ("J" . my/notes-project-open)
        ("C-j" . my/notes-project-select))
  (:map goto-map
        ("f" . project-find-file)
        ("P" . project-switch-project))
  (:map search-map
        ("*" . +project-find-symbol))
  :custom
  (project-vc-extra-root-markers '(".project.el"))
  :preface
  (defun +project-find-symbol ()
    "Search for symbol under point in whole project"
    (interactive)
    (consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol))))

;;;; auto-revert
(use-package autorevert
  :custom
  (auto-revert-verbose nil)
  :init
  (global-auto-revert-mode 1))

;;;; minibuffer
(use-package minibuffer
  :custom
  (enable-recursive-minibuffers t)
  :init
  (minibuffer-depth-indicate-mode))

(use-package savehist
  :custom
  (history-length 200)
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100)
  :init
  (add-hook 'emacs-startup-hook #'savehist-mode))


;;;; vc
(use-package vc
  :bind
  (:map my/leader-map
        ("v" . project-vc-dir))
  :custom
  (vc-allow-rewriting-published-history 'ask)
  (vc-dir-hide-up-to-date-on-revert t)
  (vc-deduce-backend-nonvc-modes t)
  (vc-find-revision-no-save t)
  (vc-follow-symlinks t)
  (vc-use-incoming-outgoing-prefixes t)
  (vc-dir-simple-unmark-all-files t)
  :preface
  (defun my/vc-dir-in-tab (original &rest args)
    "Run ORIGINAL in the named VC tab."
    (require (quote tab-bar))
    (tab-bar-switch-to-tab "VC")
    (apply original args))

  (defun my/vc-git-close-successful-pushpull (original command &rest args)
    "Close the VC Git output window after a successful push or pull."
    (let ((process (apply original command args)))
      (when (member command '("push" "pull"))
        (let ((buffer (process-buffer process)))
          (vc-exec-after
           (lambda ()
             (when (buffer-live-p buffer)
               (dolist (window (get-buffer-window-list buffer nil t))
                 (quit-window nil window))))
           0 process)))
      process))
  :init
  (vc-auto-revert-mode 1)
  :config
  (with-eval-after-load "vc-dir"
    (advice-add (quote vc-dir) :around (function my/vc-dir-in-tab)))
  (with-eval-after-load 'vc-git
    (advice-add 'vc-git--pushpull :around
                #'my/vc-git-close-successful-pushpull)))

(use-package diff-hl
  :ensure t
  :hook
  (prog-mode . turn-on-diff-hl-mode)
  (text-mode . turn-on-diff-hl-mode)
  (vc-dir-mode . turn-on-diff-hl-mode)
  :custom
  (diff-hl-draw-borders nil)
  :config
  (unless (display-graphic-p)
    (require 'diff-hl-margin)
    (setq diff-hl-margin-symbols-alist
          '((insert . " ") (delete . " ") (change . " ")
            (unknown . " ") (ignored . " ")))
    (diff-hl-margin-mode 1)))

;;;; magit
(use-package magit
  :ensure t
  :pin "nongnu"
  :commands (magit-status)
  :bind
  (:map my/leader-map
        ("V" . magit-status))
  :custom
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1))

;;;; vc log
(use-package log-view
  :bind
  (:map log-view-mode-map
        ("H" . log-view-delete-revisions-from-end)))

;;;; ediff
(use-package ediff
  :preface
  (defun my/ediff-store-layout ()
    "Store the current frame's window configuration for Ediff."
    (set-frame-parameter
     (selected-frame) 'my/ediff-window-configuration
     (current-window-configuration)))

  (defun my/ediff-restore-layout ()
    "Restore the frame's window configuration saved before Ediff."
    (when-let* ((configuration
                 (frame-parameter (selected-frame)
                                  'my/ediff-window-configuration)))
      (set-window-configuration configuration)))

  (defun my/ediff-visible-buffers-2 ()
    "Run Ediff on the buffers displayed in the current frame's two windows."
    (interactive)
    (if (= (length (window-list)) 2)
        (let ((buffers (mapcar #'window-buffer (window-list))))
          (ediff-buffers (car buffers) (cadr buffers)))
      (user-error "Can only operate on two windows")))

  (defun my/ediff-visible-buffers-3 ()
    "Run three-way Ediff on buffers in the current frame's three windows."
    (interactive)
    (if (= (length (window-list)) 3)
        (let ((buffers (mapcar #'window-buffer (window-list))))
          (ediff-buffers3 (nth 0 buffers) (nth 1 buffers) (nth 2 buffers)))
      (user-error "Can only operate on three windows")))
  :init
  (add-hook 'ediff-before-setup-hook #'my/ediff-store-layout)
  (add-hook 'ediff-quit-hook #'my/ediff-restore-layout))

(provide 'my-projects)
;;; my-projects.el ends here
