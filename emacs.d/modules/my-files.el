;;; my-files.el --- Files, recent files, Ibuffer and Dired -*- lexical-binding: t; -*-

;;; Files
(use-package files
  :custom
  (make-backup-files nil)
  (auto-save-default nil)
  (create-lockfiles nil)
  (find-file-visit-truename t))

(use-package alternate-file
  :demand t
  :load-path "user-lisp")

(use-package links
  :commands (+links-bookmarks +links-project-repository
             +links-project-pull-requests
             +links-current-branch-pull-request)
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

;;;; ibuffer

(use-package ibuffer
  :hook (ibuffer-mode . my/ibuffer-setup)
  :commands (ibuffer)
  :custom
  (ibuffer-show-empty-filter-groups nil)
  (ibuffer-saved-filter-groups
   '(("default"
      ("Emacs"
       (or
        (name . "^\\*scratch\\*$")
        (name . "^\\*Messages\\*$")
        (name . "^\\*Warnings\\*$")
        (name . "^\\*Backtrace\\*$")
        (name . "^\\*Completions\\*$")
        (name . "^\\*Embark Collect.*\\*$")))
      ("Text"
       (or
        (mode . markdown-ts-mode)
        (mode . text-mode)))
      ("Directories" (mode . dired-mode))
      ("Shells"
       (or
        (mode . shell-mode)
        (mode . eshell-mode)
        (mode . eat-mode)
        (mode . term-mode)
        (name . "^\\*eat.*\\*$")))
      ("Code" (predicate . (derived-mode-p 'prog-mode)))
      ("Version control"
       (or
        (mode . vc-dir-mode)
        (mode . diff-mode)
        (mode . log-view-mode)))
      ("Help and diagnostics"
       (or
        (mode . help-mode)
        (mode . compilation-mode)
        (mode . grep-mode)
        (mode . occur-mode)
        (mode . flymake-diagnostics-buffer-mode)
        (mode . xref--xref-buffer-mode))))))
  :preface
  (defun my/ibuffer-setup ()
    "Apply stable defaults to Ibuffer buffers."
    (require 'ibuf-ext)
    (ibuffer-switch-to-saved-filter-groups "default")
    (ibuffer-auto-mode 1)))

;;;; dired

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
  (global-auto-revert-non-file-buffers t)
  (dired-dwim-target t)
  :init
  (when-let* ((gls (and (eq system-type 'darwin)
                        (executable-find "gls"))))
    (setq insert-directory-program gls))
  :bind
  (:map my/leader-map
        ("." . dired-jump)))

(use-package wdired
  :commands wdired-change-to-wdired-mode
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

(provide 'my-files)
;;; my-files.el ends here
