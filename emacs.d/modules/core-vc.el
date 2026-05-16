;;; core-vc.el --- Version control and diffs -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Configures Magit, built-in VC, and modern diff tools like Delta
;; and Difftastic for a superior version control experience.
;;
;;; Code:

;;; VC
(use-package vc
  :straight (:type built-in)
  :custom
  (vc-follow-symlinks t)

  :config
  (require 'vc-annotate)
  (require 'vc-dir)
  (require 'vc-git)
  (require 'add-log)
  (require 'log-view)

  (setopt vc-handled-backends '(Git))
  (require 'log-edit)
  (setopt log-edit-confirm 'changed)
  (setopt log-edit-keep-buffer nil)
  (setopt log-edit-require-final-newline t)
  (setopt log-edit-setup-add-author nil)
  (remove-hook 'log-edit-hook #'log-edit-show-files)

  (setopt vc-find-revision-no-save t)
  (setopt vc-annotate-display-mode 'scale) ; scale to oldest
  (setopt add-log-keep-changes-together t)
  (setopt vc-git-diff-switches '("--patch-with-stat" "--histogram"))
  (setopt vc-git-log-switches '("--stat"))
  (setopt vc-git-print-log-follow t)
  (setopt vc-git-revision-complete-only-branches nil) ; Emacs 28
  (setopt vc-git-root-log-format
    `("%d %h %ai %an: %s"
       ;; The first shy group matches the characters drawn by --graph.
       ;; We use numbered groups because `log-view-message-re' wants the
       ;; revision number to be group 1.
       ,(concat "^\\(?:[*/\\|]+\\)\\(?:[*/\\| ]+\\)?"
          "\\(?2: ([^)]+) \\)?\\(?1:[0-9a-z]+\\) "
          "\\(?4:[0-9]\\{4\\}-[0-9-]\\{4\\}[0-9\s+:-]\\{16\\}\\) "
          "\\(?3:.*?\\):")
       ((1 'log-view-message)
         (2 'change-log-list nil lax)
         (3 'change-log-name)
         (4 'change-log-date))))

  ;; These two are from Emacs 29
  (setopt vc-git-log-edit-summary-target-len 80)
  (setopt vc-git-log-edit-summary-max-len 120)

  :init
  (my/with-popper!
    "\\*vc-change-log\\*"
    "\\*vc-log\\*"
    "\\*vc-annotate\\*")
  (my/register-side-popup 'vc-diff-mode))

;;; Magit
(use-package magit
  :commands (magit-status magit-file-dispatch magit-log-buffer-file magit-log-all)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  (magit-tramp-pipe-stty-settings 'pty)
  :config
  (when (eq system-type 'darwin)
    (setopt magit-git-executable "/opt/homebrew/bin/git")))

;;; Magit Delta (Modern diff highlighting)
;; Requires `delta` CLI installed on your system.
;; (use-package magit-delta
;;   :hook (magit-mode . magit-delta-mode))

;;; Difftastic (Structural diffs)
;; Requires `difft` CLI installed on your system.
(use-package difftastic
  :after magit)

;;; Gutter indicators
(use-package diff-hl
  :hook
  ((after-init . global-diff-hl-mode)
    (magit-post-refresh . diff-hl-magit-post-refresh)))

;;; Ediff (side-by-side merge/diff)
(use-package ediff
  :straight (:type built-in)
  :custom
  (ediff-split-window-function #'split-window-horizontally)
  (ediff-window-setup-function #'ediff-setup-windows-plain))

;;; Merge conflict resolution
(use-package smerge-mode
  :straight (:type built-in)
  :bind
  (:map smerge-mode-map
    ("C-c m" . smerge-keep-upper)
    ("C-c o" . smerge-keep-lower)
    ("C-c b" . smerge-keep-base)
    ("C-c a" . smerge-keep-all)
    ("C-c c" . smerge-keep-current)
    ("C-c n" . smerge-next)
    ("C-c p" . smerge-prev)))

(use-package git-modes
  :mode ("/\\.\\(docker\\|fd\\|rg\\|ag\\|hg\\)?ignore\\'" . gitignore-mode)
  :mode ("/\\.dumbjump\\'" . gitignore-mode))

(use-package diffview)

(provide 'core-vc)
;;; core-vc.el ends here
