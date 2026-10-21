;;; my-ai.el --- simple ai integration -*- lexical-binding: t; -*-

(use-package gptel
  :if my/gptel-enabled
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
  
  (setq gptel-model my/gptel-backend-mistral)
  (setq gptel-model 'mistral-medium-latest))


(use-package agent-shell
  :if my/agent-shell-enabled
  :ensure t
  :pin "melpa"
  :bind
  (:map my/project-prefix-map
        ("c" . agent-shell-openai-start-codex))
  :config
  (my/push-display-buffer-rule
   ".* Agent @ .*"
   (my/side-window-config 'agent-shell-mode))

  (setopt agent-shell-openai-authentication
          (agent-shell-openai-make-authentication :login t))
  (setopt agent-shell-write-inhibit-minor-modes '(aggressive-indent-mode))

  (defun my/agent-shell-dot-subdir (subdir)
    (let* ((cwd (string-remove-suffix "/" (agent-shell-cwd)))
           (sanitized (replace-regexp-in-string "/" "-" (string-remove-prefix "/" cwd))))
      (expand-file-name subdir (locate-user-emacs-file (concat "agent-shell/" sanitized)))))

  (setopt agent-shell-dot-subdir-function #'my/agent-shell-dot-subdir)
  )
(provide 'my-ai)
