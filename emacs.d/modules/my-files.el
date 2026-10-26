;;; my-files.el --- Files, recent files, Ibuffer and Dired -*- lexical-binding: t; -*-

;;; Files
(use-package files
  :bind
  (:map my/leader-map
        ("F" . find-file))
  :custom
  (make-backup-files nil)
  (auto-save-default nil)
  (create-lockfiles nil)
  (find-file-visit-truename t))

(use-package ffap
  :bind
  (:map my/open-prefix-map
        ("." . ffap)))

(use-package alternate-file
  :demand t
  :load-path "user-lisp")

(use-package links
  :commands (+links-bookmarks +links-project-repository
             +links-project-pull-requests
             +links-current-branch-pull-request
             +links-current-branch-pull-request-info)
  :bind
  (:map my/open-prefix-map
        ("l" . +links-bookmarks))
  (:map my/repository-prefix-map
        ("r" . +links-project-repository)
        ("p" . +links-current-branch-pull-request)
        ("P" . +links-project-pull-requests)
        ("i" . +links-current-branch-pull-request-info))
  :load-path "user-lisp")

;;;; recent
(use-package recentf
  :bind
  (:map mymacs-mode-map ("C-x R" . recentf-open))
  :custom
  (recentf-max-saved-items 200)
  (recentf-exclude '(".gz" ".xz" ".zip" "COMMIT_EDITMSG"))
  :init
  (add-hook 'emacs-startup-hook #'recentf-mode))


;;;; diredx
(use-package dired
  :hook (dired-mode . hl-line-mode)
  :commands (dired dired-jump dired-find-alternate-file)
  :custom
  (dired-listing-switches
   (if (and (eq system-type 'darwin)
            (not (executable-find "gls")))
       "-agho"
     "-agho --group-directories-first"))
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-auto-revert-buffer #'dired-directory-changed-p)
  (dired-mouse-drag-files t)
  (global-auto-revert-non-file-buffers t)
  (dired-dwim-target t)
  :init
  (when-let* ((gls (and (eq system-type 'darwin)
                        (executable-find "gls"))))
    (setq insert-directory-program gls))
  :bind
  (:map my/leader-map
        ("." . dired-jump)))

(use-package shell
  :custom
  (shell-command-prompt-show-cwd t))

(use-package wdired
  :commands wdired-change-to-wdired-mode
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(provide 'my-files)
;;; my-files.el ends here
