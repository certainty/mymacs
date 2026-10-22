;;; my-ai.el --- simple ai integration -*- lexical-binding: t; -*-

(when my/gptel-enabled
  (use-package gptel
    :ensure t
    :pin "melpa"
    :commands (gptel)
    :custom
    (gptel-default-mode 'org-mode)
    (gptel-org-branching-context t)
    (gptel-confirm-tool-calls nil)
    
    :config
    (defvar my/gptel-backend-mistral
      (gptel-make-openai "MistralLeChat"
        :host "api.mistral.ai"
        :endpoint "/v1/chat/completions"
        :protocol "https"
        :key (auth-source-pass-get 'secret "mistral.emacs")
        :stream t
        :models
        '("mistral-medium-latest"
          "mistral-large-latest"
          "pixtral-large-latest"
          "devstral-latest"
          "devstral-medium-latest"
          "codestral-latest"
          "magistral-medium-latest"
          "zai-glm-5-3"
          )))
    
    (setopt gptel-backend my/gptel-backend-mistral)
    (setopt gptel-model 'mistral-medium-latest)))


(when my/agent-shell-enabled
  (use-package agent-shell
    :ensure t
    :pin "melpa"
    :commands (agent-shell agent-shell-openai-start-codex
                           agent-shell-project-buffers)
    :bind
    (:map my/project-prefix-map
          ("a" . my/agent-shell-toggle-or-start-codex)
          ("A" . agent-shell-codex))
    :init
    (defun my/agent-shell-toggle-or-start-codex ()
      "Toggle the project agent shell, or start Codex when none is running."
      (interactive)
      (if (agent-shell-project-buffers)
          (agent-shell)
        (agent-shell-openai-start-codex)))

    (defalias 'agent-shell-codex 'agent-shell-openai-start-codex)
    :config
    (my/push-display-buffer-rule
     ".* Agent @ .*"
     (my/side-window-config 'agent-shell-mode))

    (setopt agent-shell-openai-authentication
            (agent-shell-openai-make-authentication :login t))
    (setopt agent-shell-write-inhibit-minor-modes '(aggressive-indent-mode))

    (defun my/agent-shell-completion-setup ()
      "Use minibuffer completion UI for in-buffer agent-shell completion."
      (setq-local completion-in-region-function #'consult-completion-in-region))

    (add-hook 'agent-shell-mode-hook #'my/agent-shell-completion-setup)

    (defun my/agent-shell-dot-subdir (subdir)
      (let* ((cwd (string-remove-suffix "/" (agent-shell-cwd)))
             (sanitized (replace-regexp-in-string "/" "-" (string-remove-prefix "/" cwd))))
        (expand-file-name subdir (locate-user-emacs-file (concat "agent-shell/" sanitized)))))

    (setopt agent-shell-dot-subdir-function #'my/agent-shell-dot-subdir)))

(provide 'my-ai)
