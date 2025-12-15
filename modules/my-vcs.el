;;; my-vc.el --- VCS -*- lexical-binding: t; -*-

;;; VC
(use-package vc
  :ensure nil
  :general
  (my-vcs-keymap
   "B" '("Blame" . vc-annotate)
   "e" '("Ediff" . vc-ediff)
   "k" '("Delete" . vc-delete-file)
   "G" '("Log search" . vc-log-search)
   "t" '("Tag" . vc-create-tag)
   "d" '("Diff" . vc-diff)
   "v" '("Here" . vc-dir-root)
   "z p" '("Pop" . vc-git-stash-pop)
   "z z" '("Stash" . vc-git-stash-stash))
  :bind
  (:map goto-map
    ("v" . project-vc-dir))
  (:map vc-dir-mode-map
    ("t" . vc-create-tag)
    ("O" . vc-log-outgoing)
    ("o" . vc-dir-find-file-other-window)
    ("d" . vc-diff)
    ("k" . vc-dir-delete-file)
    ("G" . vc-revert))
   (:map vc-git-stash-shared-map
    ("a" . vc-git-stash-apply-at-point)
    ("c" . vc-git-stash)
    ("k" . vc-git-stash-delete-at-point) ; symmetry with `vc-dir-delete-file'
    ("p" . vc-git-stash-pop-at-point)
    ("s" . vc-git-stash-snapshot))
   (:map vc-annotate-mode-map
    ("M-q" . vc-annotate-toggle-annotation-visibility)
    ("C-c C-c" . vc-annotate-goto-line)
    ("<return>" . vc-annotate-find-revision-at-line))
   (:map log-edit-mode-map
    ("M-s" . nil)) ; I use M-s for my search commands

   (:map log-view-mode-map
    ("<tab>" . log-view-toggle-entry-display)
    ("<return>" . log-view-find-revision)
    ("s" . vc-log-search)
    ("o" . vc-log-outgoing)
    ("f" . vc-log-incoming)
    ("F" . vc-update)
    ("P" . vc-push))
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

(use-package embark-vc)

;;; Agitate

(use-package agitate
  :hook
  ((diff-mode . agitate-diff-enable-outline-minor-mode))
  :general
  (my-search-keymap
   "v" '("Revision" . agitate-vc-git-grep))
  (my-vcs-keymap
   "d"  '("Diff" . agitate-diff-buffer-or-file)
   "s" '("Search" . agitate-vc-git-grep)
   "r" '("Find Rev" . agitate-vc-git-find-revision)
   "S" '("Show" . agitate-vc-git-show))

  :bind
  (:map diff-mode-map
   ("C-c C-b" . agitate-diff-refine-cycle) ; replace `diff-refine-hunk'
   ("C-c C-n" . agitate-diff-narrow-dwim)
   ("L" . vc-print-root-log)
   ("v" . vc-next-action)
   :map log-view-mode-map
   ("w" . agitate-log-view-kill-revision)
   ("W" . agitate-log-view-kill-revision-expanded)
   :map vc-git-log-view-mode-map
   ("c" . agitate-vc-git-format-patch-single)
   :map log-edit-mode-map
   ("C-c C-i C-n" . agitate-log-edit-insert-file-name)
   ("C-c C-i C-e" . agitate-log-edit-emoji-commit)
   ("C-c C-i C-c" . agitate-log-edit-conventional-commit))

  :config
  (advice-add #'vc-git-push :override #'agitate-vc-git-push-prompt-for-remote)

  (setq agitate-log-edit-informative-show-root-log nil
    agitate-log-edit-informative-show-files nil)

  (agitate-log-edit-informative-mode))

;;; Magit

;; Magit does not build currently (need to get from master)

(use-package transient)
(use-package magit
  :general
  (my-vcs-keymap
   "g" '("Magit" . magit-status))
  :custom
  (git-commit-summary-max-length 100)
  (git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line))
  (magit-diff-refine-hunk t)
  (with-editor-emacsclient-executable "emacsclient")
  ;; this causes lag in buffers
  (magit-auto-revert-mode t)

  :config
  (setopt magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1)
  (add-to-list 'magit-no-confirm 'stage-all-changes)
  (add-to-list 'display-buffer-alist
             '("\\magit:"
                (display-buffer-same-window))))

;;; Diff

 (use-package diff-hl
   :hook
   (elpaca-after-init . global-diff-hl-mode))

(use-package ediff
  :ensure nil
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
  :ensure nil
  :custom
  (diff-default-read-only t)
  (diff-advance-after-apply-hunk t)
  (diff-update-on-the-fly t)
  (diff-refine nil)
  (diff-font-lock-prettify t)
  (diff-font-lock-syntax 'hunk-also))


;;; Smerge

(use-package smerge-mode
  :ensure nil
  :bind
  (:map smerge-mode-map
     ("C-c v m m" . smerge-keep-mine)
     ("C-c v m o" . smerge-keep-other)
     ("C-c v m b" . smerge-keep-base)
     ("C-c v m a" . smerge-keep-all)
     ("C-c v m c" . smerge-keep-current)
     ("C-c v m n" . smerge-next)
     ("C-c v m p" . smerge-prev))

    (:repeat-map smerge-repeat-map
      ("n" . smerge-next)
      ("p" . smerge-prev)))

(provide 'my-vcs)
