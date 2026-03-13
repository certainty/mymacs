;;; ai-gptel.el --- gptel -*- lexical-binding: t; -*-


(use-package gptel
  :bind
  (:map gptel-mode-map
    ("C-c C-s" . gptel-stop-streaming)
    ("C-c C-c" . gptel-send)
    ("C-c C-r" . gptel-rewrite)
    ("C-c C-a" . gptel-add)
    ("C-c C-f" . gptel-add-file))

  :config
  (defconst my/gptel-private-openrouter-model
    (intern "qwen/qwen3-coder")
    "Default OpenRouter model for private context.")

  (defconst my/gptel-ollama-model
    (intern "qwen2.5-coder:latest")
    "Default Ollama model.")

  (defun my/gptel--openrouter-key ()
    (auth-source-pass-get 'secret "emacs-openrouter"))

  (defvar my/gptel-openrouter-backend nil
    "Registered OpenRouter backend for gptel.")

  (defvar my/gptel-ollama-backend nil
    "Registered Ollama backend for gptel.")

  (when (my/context-private-p)
    (when-let* ((key (my/gptel--openrouter-key)))
      (setq my/gptel-openrouter-backend
            (gptel-make-openai
              "OpenRouter"
              :host "openrouter.ai"
              :endpoint "/api/v1/chat/completions"
              :stream t
              :models (list my/gptel-private-openrouter-model)
              :key (lambda () key)
              :header (lambda ()
                        `(("Authorization" . ,(concat "Bearer " key))
                           ("HTTP-Referer" . "https://github.com/certainty/mymacs")
                           ("X-Title" . "mymacs")))))))

  (when (executable-find "ollama")
    (setq my/gptel-ollama-backend
          (gptel-make-ollama
            "Ollama"
            :host "127.0.0.1:11434"
            :protocol "http"
            :endpoint "/api/chat"
            :models (list my/gptel-ollama-model)
            :stream t)))

  (setopt gptel-expert-commands t
    gptel-default-mode 'org-mode
    gptel-org-branching-context t
    gptel-include-reasoning t)

  (cond
    ((and (my/context-private-p) my/gptel-openrouter-backend)
     (setopt gptel-backend my/gptel-openrouter-backend
       gptel-model my/gptel-private-openrouter-model))
    (my/gptel-ollama-backend
     (setopt gptel-backend my/gptel-ollama-backend
       gptel-model my/gptel-ollama-model)))

  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response)

  (require 'gptel-integrations)

  :init
  (my/window-rule! gptel-mode :align right :size 0.33 :select t)
  (my/with-popper! 'gptel-mode))

(use-package llm-tool-collection
  :straight  (:type git  :host github :repo "skissue/llm-tool-collection")
  :after gptel
  :config
  (mapcar (apply-partially #'apply #'gptel-make-tool)
    (llm-tool-collection-get-tag 'editing)))

(provide 'ai-gptel)
