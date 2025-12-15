;;; my-mode.el --- Mymacs mode -*- lexical-binding: t; -*-

(define-minor-mode mymacs-mode
    "Minor mode for mymacs, which gives a home for my customizations and keybindings."
    :global t
    :lighter " λ"
    :keymap (make-sparse-keymap))

(use-package emacs
  :ensure nil
  :hook
  (find-file . mymacs-mode)
  (after-init . mymacs-mode)
  :custom
  (user-full-name my-full-name)
  (custom-file (expand-file-name "custom.el" user-emacs-directory)))

(provide 'my-mode)
