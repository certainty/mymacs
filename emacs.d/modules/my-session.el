;;; my-session.el --- Automatic refresh and minibuffer history -*- lexical-binding: t; -*-

;;;; auto-revert
(use-package autorevert
  :custom
  (auto-revert-verbose nil)
  :init
  (global-auto-revert-mode 1))

;;;; minibuffer
(use-package minibuffer
  :custom
  (enable-recursive-minibuffers t)
  :init
  (minibuffer-depth-indicate-mode))

(use-package savehist
  :custom
  (history-length 200)
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100)
  :init
  (add-hook 'emacs-startup-hook #'savehist-mode))

(provide 'my-session)
;;; my-session.el ends here
