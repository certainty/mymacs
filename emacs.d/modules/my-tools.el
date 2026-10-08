;;; my-tools.el --- various tools -*- lexical-binding: t; -*-

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


;;;; PMD
(use-package consult-pmd
  :if my/pmd-enabled
  :commands +pmd-cache-clear
  :bind
  (:map my/pmd-prefix-map
        ("," . +pmd-projects)
        ("t" . +pmd-teams)
        ("p" . +pmd-people)
        ("s" . +pmd-servicegroups)
        ("c" . +pmd-cache-clear))
  :custom
  (pmd-base-url my/pmd-base-url)
  :load-path "user-lisp")


(provide 'my-tools)
;;; my-tools.el ends here
