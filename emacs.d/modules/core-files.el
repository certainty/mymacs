;;; core-files.el --- File management, backups, and Dired -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Backup settings, recent files, saveplace, and Dired configuration.
;;
;;; Code:

;;; Basic file settings
(use-package emacs
  :custom
  ;; Backups
  (create-lockfiles nil)
  (make-backup-files nil)
  (vc-make-backup-files nil)
  (auto-save-default nil)
  (auto-save-list-file-prefix nil)
  (delete-auto-save-files t)
  (large-file-warning-threshold nil)
  (find-file-visit-truename t)

  ;; Recentf
  (recentf-max-saved-items 1000)
  (recentf-max-menu-items 25)
  (recentf-exclude
   '(".gz" ".xz" ".zip"
     "/_build/" "/deps/" "/node_modules/"
     "^/\\(?:ssh\\|su\\|sudo\\)?:"
     "/\\.emacs\\.d/straight/"
     "/\\.emacs\\.d/eln-cache/"
     "\\.elc$"
     "COMMIT_EDITMSG"))
  :init
  (recentf-mode 1)
  (save-place-mode 1))

(use-package bookmark
  :straight (:type built-in)
  :custom
  (bookmark-save-flag 1)
  (bookmark-default-file (expand-file-name "bookmarks" user-emacs-directory)))

;;; Dired
(use-package dired
  :straight (:type built-in)
  :hook
  ((dired-mode . hl-line-mode))
  :custom
  (dired-listing-switches "-agho --group-directories-first")
  (dired-dwim-target t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  :config
  (setopt dired-auto-revert-buffer #'dired-directory-changed-p)
  (put 'dired-find-alternate-file 'disabled nil)
  (when (eq system-type 'darwin)
    (setq dired-listing-switches "-alh --group-directories-first")
    (setq insert-directory-program "/opt/homebrew/bin/gls")
    (setq dired-use-ls-dired t)))

(use-package dired-x
  :straight (:type built-in)
  :after dired)

(use-package dired-aux
  :straight (:type built-in)
  :after dired
  :custom
  (dired-vc-rename-file t)
  (dired-isearch-filenames 'dwim))

(use-package diredfl
  :hook (dired-mode . diredfl-mode))

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("TAB" . dired-subtree-toggle)))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package wdired
  :straight (:type built-in)
  :after dired
  :bind
  (:map dired-mode-map
        ("C-c C-w" . wdired-change-to-wdired-mode)
        ("C-c C-k" . wdired-abort-changes)
        ("C-c C-c" . wdired-finish-edit))
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(provide 'core-files)
;;; core-files.el ends here
