;;; tools-vc.el --- Configure emacs vc  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:
(use-package vc
  :straight (:type built-in)
  :general
  (leader-def
    "vv" 'project-vc-dir
    "ve" 'vc-edif
    "v." 'vc-dir)

  (local-leader-def
    :keymaps 'vc-dir-mode-map
    "b" '(:ignore t :which-key "branch")
    "bb" 'vc-create-branch
    "bs" 'vc-switch-branch
    "z" '(:ignore t :which-key "stash")
    "zp" 'vc-git-stash-pop-at-point
    "zz" 'vc-git-stash
    "zs" 'vc-git-stash-snapshot
    :keymaps 'vc-annotate-mode-map
    "a" 'vc-annotate-toggle-annotation-visibility
    :keymaps 'log-view-mode-map
    "o" 'vc-log-outgoing
    "i" 'vc-log-incoming
    "f" 'vc-log-search
    "F" 'vc-update
    "P" 'vc-push
    :keymaps 'vc-git-stash-shared-map
    "za" 'vc-git-stash-apply-at-point
    "zk" 'vc-git-stash-delete-at-point
    "zp" 'vc-git-stash-pop-at-point)
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

  (add-to-list 'display-buffer-alist
    '("\\*\\vc-\\(incoming\\|outgoing\\|git : \\).*"
       (display-buffer-reuse-mode-window display-buffer-below-selected)
       (window-height . 0.1)
       (dedicated . t)
       (preserve-size . (t . t)))))

(use-package agitate
  :hook
  ((diff-mode . agitate-diff-enable-outline-minor-mode))
  :general
  (leader-def
    "vd" 'agitate-diff-buffer-or-file
    "vb" 'agitate-vc-git-grep
    "vS" 'agitate-vc-git-show
    "vsf" 'agitate-vc-git-find-revision)
  (local-leader-def
    :keymaps 'vc-dir-mode-map
    "s" '(:ignore t :which-key "search")
    "ss" 'agitate-vc-git-grep
    "sS" 'agitate-vc-git-grep-symbol-at-point
    "sF" 'agitate-vc-git-find-revision
    "sB" 'agitate-vc-git-blame
    "sC" 'agitate-vc-git-commit-search)

  :config
  (advice-add #'vc-git-push :override #'agitate-vc-git-push-prompt-for-remote)

  (setq agitate-log-edit-informative-show-root-log nil
    agitate-log-edit-informative-show-files nil)

  (agitate-log-edit-informative-mode))



(use-package diff-hl
  :hook
  (after-init . global-diff-hl-mode))

(use-package smerge-mode
  :straight (:type built-in)
  :general
  (leader-def
    "vm" '(:ignore t :which-key "merge")
    "vmm" 'smerge-mode
    "vmM" 'smerge-keep-mine
    "vmo" 'smerge-keep-other
    "vmb" 'smerge-keep-base
    "vma" 'smerge-keep-all
    "vmc" 'smerge-keep-current
    "vmn" 'smerge-next
    "vmp" 'smerge-prev))

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
