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

(provide 'my-ai)
