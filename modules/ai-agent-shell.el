;;; ai-agent-shell.el --- Agent Shell integration -*- lexical-binding: t; -*-

(define-prefix-command '+agent-shell)
(define-key +ai (kbd "s") (cons "+agent-shell" +agent-shell))


(use-package agent-shell
  :straight (agent-shell :type git :host github :repo "xenodium/agent-shell")
  :ensure-system-package
  ((codex-acp . "brew install codex-acp"))

  :bind
  ((:map my/leader-map
     ("," . agent-shell-openai-start-codex))
    (:map +agent-shell
      ("t" . agent-shell-toggle)
      ("a" . agent-shell)
      ("A" . agent-shell-new-shell)
      ("p" . agent-shell-prompt-compose)
      ("s" . agent-shell-send-screenshot)
      ("h" . agent-shell-help-menu))
    (:map agent-shell-mode-map
      ("R" . agent-shell-rename-buffer)
      ("c" . agent-shell-clear-buffer)))

  :custom
  (agent-shell-session-strategy 'reuse)
  (agent-shell-show-welcome-message nil)
  ;; (agent-shell-prefer-viewport-interaction t) ; experimental interface
  (agent-shell-preferred-agent-config #'agent-shell-openai-make-agent-config)

  :init
  (my/window-rule! agent-shell-mode :align right :size 0.45 :select t)
  (my/window-rule! agent-shell-viewport-edit-mode :align right :size 0.45 :select t)

  (my/with-popper! 'agent-shell-mode)
  (my/with-popper! 'agent-shell-viewport-edit-mode)

  :config
  (setopt agent-shell-openai-authentication (agent-shell-openai-make-authentication :login t))
  (setq agent-shell-text-file-capabilities '(read-text-file write-text-file)))

(use-package agent-review
  :straight (agent-review :type git :host github :repo "nineluj/agent-review")
  :after agent-shell
  :bind
  (:map +agent-shell
    ("r" . agent-review))
  :commands agent-review)

(use-package agent-shell-attention
  :straight (agent-shell-attention :type git :host github :repo "ultronozm/agent-shell-attention.el")
  :after agent-shell
  :bind
  (:map +agent-shell
    ("d" . agent-shell-attention-dashboard)
    ("j" . agent-shell-attention-jump))
  :custom
  (agent-shell-attention-indicator-location 'mode-line-misc-info)
  (agent-shell-attention-render-function #'agent-shell-attention-render-active)
  :config
  (agent-shell-attention-mode 1))

(use-package agent-shell-manager
  :straight (agent-shell-manager :type git :host github :repo "jethrokuan/agent-shell-manager")
  :after agent-shell
  :bind
  (:map +agent-shell
    ("m" . agent-shell-manager-toggle))
  :custom
  (agent-shell-manager-side 'bottom)
  (agent-shell-manager-transient t)
  :commands agent-shell-manager-toggle)

(provide 'ai-agent-shell)

;;; ai-agent-shell.el ends here
