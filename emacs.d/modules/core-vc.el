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
  :custom
  (vc-follow-symlinks t)

  :preface
  (defconst my/vc-async-buffer-name-regexp
    "^\\*vc-[[:alnum:]-]+ : .*\\*$"
    "Regexp matching asynchronous VC process buffers.")

  (defun my/vc-async-buffer-p (&optional buffer)
    "Return non-nil when BUFFER is an asynchronous VC process buffer."
    (with-current-buffer (or buffer (current-buffer))
      (and (derived-mode-p 'compilation-mode)
           (string-match-p my/vc-async-buffer-name-regexp
                           (buffer-name (current-buffer))))))

  (defun my/vc-close-buffer-windows (buffer)
    "Close all live windows currently showing BUFFER."
    (when (buffer-live-p buffer)
      (dolist (window (get-buffer-window-list buffer nil t))
        (when (window-live-p window)
          (quit-window nil window)))))

  (defun my/vc-maybe-close-async-buffer (buffer status)
    "Close BUFFER's window when STATUS indicates successful completion."
    (when (and my/vc-auto-close-async-buffers
               (buffer-live-p buffer)
               (string-prefix-p "finished" status)
               (my/vc-async-buffer-p buffer))
      (run-with-timer my/vc-auto-close-async-buffers-delay
                      nil
                      #'my/vc-close-buffer-windows
                      buffer)))

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

  (add-hook 'compilation-finish-functions #'my/vc-maybe-close-async-buffer)

  :init
  (my/with-popper!
    my/vc-async-buffer-name-regexp
    "\\*vc-change-log\\*"
    "\\*vc-log\\*"
    "\\*vc-annotate\\*")
  (my/register-side-popup my/vc-async-buffer-name-regexp nil t)
  (my/register-side-popup "\\*vc-diff\\*" nil t))

;;; Magit
(use-package magit
  :ensure t
  :commands (magit-status magit-file-dispatch magit-log-buffer-file magit-log-all)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  (magit-tramp-pipe-stty-settings 'pty)
  :config
  (when (eq system-type 'darwin)
    (setopt magit-git-executable "/opt/homebrew/bin/git")))


(use-package consult-gh
  :ensure nil
  :bind
  (:map +vc
    ("b" . consult-gh-dashboard)
    ("/" . consult-gh-search-repo-list)
    ("*" . consult-gh-search-code)
    ("," . consult-gh-pr-list))

  :custom
  (consult-gh-default-clone-directory "~/tmp")
  (consult-gh-show-preview t)
  (consult-gh-preview-key "C-o")
  (consult-gh-repo-action #'consult-gh--repo-browse-files-action)
  (consult-gh-large-file-warning-threshold 2500000)
  (consult-gh-confirm-name-before-fork nil)
  (consult-gh-confirm-before-clone t)
  (consult-gh-notifications-show-unread-only nil)
  (consult-gh-default-interactive-command #'consult-gh-transient)
  (consult-gh-prioritize-local-folder nil)
  (consult-gh-group-dashboard-by :reason)
  :config
  (add-to-list 'savehist-additional-variables 'consult-gh--known-orgs-list)
  (add-to-list 'savehist-additional-variables 'consult-gh--known-repos-list)
  :after consult)

(use-package consult-gh-embark
  :ensure nil
  :after consult-gh
  :config
  (consult-gh-embark-mode +1))

;;; Magit Delta (Modern diff highlighting)
;; Requires `delta` CLI installed on your system.
;; (use-package magit-delta
  :ensure t
;;   :hook (magit-mode . magit-delta-mode))

;;; Difftastic (Structural diffs)
;; Requires `difft` CLI installed on your system.
(use-package difftastic
  :ensure nil
  :after magit)

;;; Gutter indicators
(use-package diff-hl
  :ensure t
  :hook
  ((after-init . global-diff-hl-mode)
    (magit-post-refresh . diff-hl-magit-post-refresh)))

;;; Ediff (side-by-side merge/diff)
(use-package ediff
  :custom
  (ediff-split-window-function #'split-window-horizontally)
  (ediff-window-setup-function #'ediff-setup-windows-plain))

;;; Merge conflict resolution
(use-package smerge-mode
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
  :ensure t
  :mode ("/\\.\\(docker\\|fd\\|rg\\|ag\\|hg\\)?ignore\\'" . gitignore-mode)
  :mode ("/\\.dumbjump\\'" . gitignore-mode))

(use-package diffview
  :ensure t)

(provide 'core-vc)
;;; core-vc.el ends here
