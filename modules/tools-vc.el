;;; tools-vc.el --- Configure emacs vc  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:
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
    "\\*vc-diff\\*"
    "\\*vc-change-log\\*"
    "\\*vc-log\\*"
    "\\*vc-annotate\\*")

  (my/window-rule! vc-diff-mode :align right :size 0.35 :select t))

(use-package agitate
  :hook
  ((diff-mode . agitate-diff-enable-outline-minor-mode))
  :bind
  (:map vc-dir-mode-map
    ("C-c G" . agitate-vc-git-grep)
    ("C-c g" . agitate-vc-git-grep-symbol-at-point)
    ("C-c F" . agitate-vc-git-find-revision)
    ("C-c C" . agitate-vc-git-commit-search))

  :config
  (advice-add #'vc-git-push :override #'agitate-vc-git-push-prompt-for-remote)

  (setq agitate-log-edit-informative-show-root-log nil
    agitate-log-edit-informative-show-files nil)

  (agitate-log-edit-informative-mode))

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  :config
  (when (my/context-work-p)
    (setopt magit-git-executable "/opt/homebrew/bin/git")
    ))

(use-package diff-hl
  :hook
  (after-init . global-diff-hl-mode))

(use-package smerge-mode
  :straight (:type built-in)
  :bind
  (:map smerge-mode-map
    ("C-c m" . smerge-keep-mine)
    ("C-c o" . smerge-keep-other)
    ("C-c b" . smerge-keep-base)
    ("C-c a" . smerge-keep-all)
    ("C-c c" . smerge-keep-current)
    ("C-c n" . smerge-next)
    ("C-c p" . smerge-prev)))

(use-package ediff
  :straight (:type built-in)
  :commands (ediff-buffers ediff-files ediff-buffers3 ediff-files3)
  :custom
  (ediff-keep-variants nil)
  (ediff-make-buffers-readonly-at-startup nil)
  (ediff-merge-revisions-with-ancestor t)
  (ediff-show-clashes-only t)
  (ediff-diff-options "")
  (ediff-custom-diff-options "-u")
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  (ediff-split-window-function 'split-window-vertically))

(use-package diff-mode
  :straight (:type built-in)
  :custom
  (diff-default-read-only t)
  (diff-advance-after-apply-hunk t)
  (diff-update-on-the-fly t)
  (diff-refine nil)
  (diff-font-lock-prettify t)
  (diff-font-lock-syntax 'hunk-also))

(provide 'tools-vc)
