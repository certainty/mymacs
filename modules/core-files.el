;;; core-files.el --- File configuration -*- lexical-binding: t; -*-
;;
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package files
  :straight (:type built-in)
  :custom
  (make-backup-files nil)
  (auto-save-default nil)
  (auto-save-list-file-prefix nil)
  (create-lockfiles nil)

  (large-file-warning-threshold nil)
  (find-file-visit-truename t)
  (make-backup-files nil)
  (vc-make-backup-files nil)
  (delete-auto-save-files t))

(use-package recentf
  :straight (:type built-in)
  :demand t
  :custom
  (recentf-max-saved-items 100)
  (recentf-max-menu-items 15)
  (recentf-auto-cleanup 'never)
  :config
  (recentf-mode 1)
  ;; Exclude certain files from recent list
  (add-to-list 'recentf-exclude "^/\\(?:ssh\\|su\\|sudo\\)?:")
  (add-to-list 'recentf-exclude "/\\.emacs\\.d/straight/")
  (add-to-list 'recentf-exclude "/\\.emacs\\.d/eln-cache/")
  (add-to-list 'recentf-exclude "\\.elc$")
  (add-to-list 'recentf-exclude "COMMIT_EDITMSG"))

;;;; Bookmarks
(use-package bookmark
  :straight (:type built-in)
  :custom
  (bookmark-save-flag 1)
  (bookmark-default-file (expand-file-name "bookmarks" user-emacs-directory)))

;;; Dired mode
(use-package dired
  :straight (:type built-in)
  :commands (dired dired-jump)
  :hook
  (dired-mode . dired-omit-mode)
  (dired-mode . hl-line-mode)
  :general
  (leader-def
   "e" 'dired-jump
   "E" 'dired)
  :custom
  (dired-listing-switches "-alh")
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (delete-by-moving-to-trash t)
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-auto-revert-buffer #'dired-directory-changed-p) ; also see `dired-do-revert-buffer'
  (dired-make-directory-clickable t)
  (dired-free-space nil)
  (dired-mouse-drag-files t)
  (dired-no-confirm t)

  :config
  (when (and (eq system-type 'darwin) (executable-find "gls"))
    (setq insert-directory-program "gls")))

(use-package dired-aux
  :straight (:type built-in)
  :after dired
  :bind
  (:map dired-mode-map
        ("C-+" . dired-create-empty-file)
        ("M-s f" . nil)
        ("C-<return>" . dired-do-open)
        ("C-x v v" . dired-vc-next-action))
  :custom
  (dired-isearch-filenames 'dwim)
  (dired-create-destination-dirs 'ask)
  (dired-vc-rename-file t)
  (dired-do-revert-buffer (lambda (dir) (not (file-remote-p dir))))
  (dired-create-destination-dirs-on-trailing-dirsep t))

(use-package dired-x
  :straight (:type built-in)
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
  :straight (:type built-in)
  :after dired
  :general
  (:keymaps 'dired-mode-map
   :states 'normal
   "i" 'wdired-change-to-wdired-mode)
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))


(with-eval-after-load 'general
  (leader-def
   "ff" 'find-file
   "fs" 'save-buffer
   "fS" 'save-some-buffers))

(provide 'core-files)
;;; core-files.el ends here
