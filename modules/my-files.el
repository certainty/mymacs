;;; mad-files.el --- File management -*- lexical-binding: t; -*-

(use-package files
  :ensure nil
  :general
  (my-file-keymap
   "f" '("Files" . find-file))
  :custom
  (large-file-warning-threshold nil)
  (find-file-visit-truename t)

  (make-backup-files nil) ; no backup files
  (vc-make-backup-files nil) ; no backup files in vc
  (create-lockfiles nil) ; no lockfiles since I only ever have one instance of emacs running
  (delete-auto-save-files t)
  (auto-save-default t)
  (auto-save-files-dir "~/.local/cache/emacs")
  (auto-save-list-file-prefix
    (concat "~/.local/cache/auto-save-list" "/.saves-")))

(use-package no-littering
  :demand t)

(use-package recentf
  :ensure nil
  :hook elpaca-after-init
  :custom
  (recentf-max-saved-items 100)
  (recentf-max-menu-items 15)
  (recentf-auto-cleanup 'never))

(use-package trashed
  :custom
  (trashed-action-confirmer 'nil)
  (trashed-use-header-line t)
  (trashed-sort-key '("Date deleted" . t))
  (trashed-date-format "%Y-%m-%d %H:%M:%S"))

;;; Dired
(use-package dired
  :ensure nil
  :hook
  (dired-mode . dired-omit-mode)
  (dired-mode . dired-hide-details-mode)
  (dired-mode . hl-line-mode)
  :general
  (my-global-leader-keymap
   "e" '("Dired*" . project-find-dir)
   "E" '("Dired" . dired))
  :custom
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (delete-by-moving-to-trash t)
  (dired-dwim-target t)
  (dired-auto-revert-buffer #'dired-directory-changed-p)
  (dired-make-directory-clickable t)
  (dired-free-space nil)
  (dired-mouse-drag-files t)

  :config
  (when (and (eq system-type 'darwin) (executable-find "gls"))
    (setq insert-directory-program "gls")))

(use-package dired-x
  :ensure nil
  :after dired
  :bind
  (:map dired-mode-map
    ("I" . dired-info))

  :custom
  (dired-clean-up-buffers-too t)
  (dired-clean-confirm-killing-deleted-buffers t)
  (dired-x-hands-off-my-keys t)
  (dired-bind-man nil)
  (dired-bind-info nil))

(use-package dired-subtree
  :after dired
  :bind
  (:map dired-mode-map
    ("<tab>" . dired-subtree-toggle)
    ("<backtab>" . dired-subtree-cycle)))

(use-package wdired
  :ensure nil
  :commands (wdired-change-to-wdired-mode)
  :bind
  (:map dired-mode-map
    ("C-x C-q" . wdired-change-to-wdired-mode))

  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(use-package nerd-icons-dired
  :after nerd-icons
  :hook dired-mode)

(provide 'my-files)
