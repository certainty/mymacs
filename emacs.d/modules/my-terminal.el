;;; my-terminal.el --- Terminal integration -*- lexical-binding: t; -*-

;;;; terminal
(use-package clipetty
  :ensure t
  :pin "melpa"
  :config
  (global-clipetty-mode 1))

(use-package vterm
  :ensure t
  :pin "melpa"
  :commands (vterm vterm-send-string vterm-send-return))

(use-package vterm-toggle
  :ensure t
  :pin "melpa"
  :bind
  (:map my/leader-map
        ("$" . vterm-toggle))
  :custom
  (vterm-toggle-scope 'project)
  (vterm-toggle-project-root t)
  :init
  (push `("\\*vterm.*\\*" . ,(my/side-window-config)) display-buffer-alist))

(provide 'my-terminal)
;;; my-terminal.el ends here
