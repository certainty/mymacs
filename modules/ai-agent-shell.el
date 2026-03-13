;;; ai-agent-shell.el --- Agent Shell integration -*- lexical-binding: t; -*-

(use-package shell-maker
  :straight (:type git :host github :repo "xenodium/shell-maker"))

(use-package chatgpt-shell
  :straight (:type git :host github :repo "xenodium/chatgpt-shell" :files ("chatgpt-shell*.el"))
  :config
  (when (my/context-work-p)
    (setopt chatgpt-shell-openai-key
      (lambda ()
        (auth-source-pass-get 'secret "emacs-chatgpt"))))

  (when (my/context-private-p)
    (setopt chatgpt-shell-openrouter-key
      (lambda ()
        (auth-source-pass-get 'secret "emacs-openrouter")))

    (setopt chatgpt-shell-models
      (append (chatgpt-shell-openrouter-models)
        (when (executable-find "ollama")
          (chatgpt-shell-ollama-models))))))

(use-package agent-shell
  :straight (agent-shell :type git :host github :repo "xenodium/agent-shell")
  :bind
  ((:map agent-shell-mode-map
     ("C-c C-r" . agent-shell-rename-buffer)
     ("C-c C-l" . agent-shell-clear-buffer)))

  :custom
  (agent-shell-session-strategy 'reuse)
  (agent-shell-show-welcome-message nil)
  ;; (agent-shell-prefer-viewport-interaction t) ; experimental interface
  (agent-shell-preferred-agent-config (if (my/context-private-p) 'opencode 'codex))

  :init
  (my/window-rule! agent-shell-mode :align right :size 0.45 :select t)
  (my/window-rule! agent-shell-viewport-edit-mode :align right :size 0.45 :select t)

  (my/with-popper! 'agent-shell-mode)
  (my/with-popper! 'agent-shell-viewport-edit-mode)

  :config
  (when (my/context-work-p)
    (setopt agent-shell-openai-authentication
      (agent-shell-openai-make-authentication :login t)))

  (when (my/context-private-p)
    (setopt agent-shell-opencode-authentication
      (agent-shell-opencode-make-authentication :login t)))

  (setq agent-shell-text-file-capabilities '(read-text-file write-text-file)))

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
