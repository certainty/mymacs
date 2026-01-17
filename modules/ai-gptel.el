(use-package gptel
  :general
  (leader-def
    "aa" '(:ignore t :which-key "ai")
    "aa" 'gptel-send
    "aA" 'gptel
    "am" 'gptel-menu
    "ar" 'gptel-rewrite
    "a." 'gptel-add
    "af" 'gptel-add-file)

  :config
  (defun my/gptel--openrouter-key ()
    (my/lookup-password :host "openrouter.ai" :user "apikey"))

  (defun my/gptel--openrouter-backend ()
    (when-let ((api-key (my/gptel--openrouter-key)))
      (gptel-make-openai "OpenRouter"
        :host "openrouter.ai"
        :endpoint "/api/v1/chat/completions"
        :stream t
        :key api-key
        :models '(
                   openai/gpt-5.1-codex
                   openai/gpt-5.1-codex-mini
                   openai/gpt-5.2-chat
                   openai/gpt-4o-mini
                   openai/gpt-5-nano

                   anthropic/claude-opus-4.5
                   anthropic/claude-sonnet-4
                   anthropic/claude-haiku-4.5
                   anthropic/claude-3.5-haiku
                   google/gemini-3-flash-preview
                   google/gemini-2.5-pro
                   qwen/qwen3-coder-plus))))

  (defun my/gptel--ollama-backend ()
    (when (executable-find "ollama")
      (gptel-make-ollama "Ollama"
        :host (or (getenv "OLLAMA_HOST") "localhost")
        :stream t
        :models '("llama3" "llama3.1" "phi3" "mistral"))))

  (defun my/gptel--select-backend ()
    (cond
      ((my/context-work-p)
        (setopt gptel-model 'claude-sonnet-4
          gptel-backend (gptel-make-gh-copilot "Copilot")))
      ((my/context-private-p)
        (let ((openrouter (my/gptel--openrouter-backend))
               (ollama (my/gptel--ollama-backend)))
          (when openrouter
            (setopt gptel-backend openrouter
              gptel-model 'gpt-5-nano))
          (unless gptel-backend
            (when ollama
              (setopt gptel-backend ollama
                gptel-model 'llama3)))
          (unless gptel-backend
            (message "gptel: no private backend configured. Add an OpenRouter token to secrets/authinfo.gpg or ensure Ollama is running."))))))

  (setopt gptel-expert-commands t
    gptel-default-mode 'org-mode
    gptel-org-branching-context t
    gptel-include-reasoning t)

  (my/gptel--select-backend)

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

(use-package elysium
  :general
  (leader-def
    "ae" '(:ignore t :which-key "elysium")
    "aee" 'elysium-query
    "aec" 'elysium-add-context
    "aew" 'elysium-toggle-window
    "aea" 'elysium-keep-all-suggested-changes
    "aed" 'elysium-discard-all-suggested-changes)

  :custom
  (elysium-window-size 0.33)
  (elysium-window-style 'vertical))

(provide 'ai-gptel)
