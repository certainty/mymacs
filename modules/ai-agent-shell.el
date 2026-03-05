;;; ai-agent-shell.el --- Agent Shell integration -*- lexical-binding: t; -*-

(use-package agent-shell
  :straight (agent-shell :type git :host github :repo "xenodium/agent-shell")
  :preface
  (define-prefix-command '+agent-shell)
  (define-key +ai (kbd "s") (cons "+agent-shell" +agent-shell))

  :bind
  (:map +agent-shell
    ("a" . agent-shell)
    ("s" . agent-shell-opencode-start-agent)
    ("n" . agent-shell-new-shell)
    ("r" . agent-shell-rename-buffer)
    ("c" . agent-shell-clear-buffer)
    ("t" . agent-shell-toggle)
    ("h" . agent-shell-help-menu)
    ("A" . agent-shell-attention-jump)
    ("R" . agent-review)
    ("M" . agent-shell-manager-toggle))

  :custom
  (agent-shell-session-strategy 'reuse)
  (agent-shell-show-welcome-message nil)
  (agent-shell-preferred-agent-config #'agent-shell-opencode-make-agent-config)

  :init
  (my/window-rule! agent-shell-mode :align right :size 0.38 :select t)
  (my/with-popper! 'agent-shell-mode)

  :config
  (setq agent-shell-text-file-capabilities '(read-text-file write-text-file)))

(use-package agent-shell-opencode
  :straight nil
  :ensure nil
  :after agent-shell
  :config
  (setopt agent-shell-opencode-authentication
    (agent-shell-opencode-make-authentication :none t)))

(use-package agent-review
  :straight (agent-review :type git :host github :repo "nineluj/agent-review")
  :after agent-shell
  :commands agent-review)

(use-package agent-shell-attention
  :straight (agent-shell-attention :type git :host github :repo "ultronozm/agent-shell-attention.el")
  :after agent-shell
  :custom
  (agent-shell-attention-indicator-location 'mode-line-misc-info)
  (agent-shell-attention-render-function #'agent-shell-attention-render-active)
  :config
  (agent-shell-attention-mode 1))

(use-package agent-shell-manager
  :straight (agent-shell-manager :type git :host github :repo "jethrokuan/agent-shell-manager")
  :after agent-shell
  :custom
  (agent-shell-manager-side 'bottom)
  (agent-shell-manager-transient t)
  :commands agent-shell-manager-toggle)

(provide 'ai-agent-shell)

;;; ai-agent-shell.el ends here
