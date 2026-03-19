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

  (defconst my/gptel-lmstudio-model
    (intern "mistralai/ministral-3-3b")
    "Default lmstudio model.")

  (defun my/gptel--openrouter-key ()
    (auth-source-pass-get 'secret "emacs-openrouter"))

  (defvar my/gptel-openrouter-backend nil
    "Registered OpenRouter backend for gptel.")

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
                     ("X-Title" . "mymacs"))))))

  (setq my/gptel-lmstudio-backend
    (gptel-make-openai
      "LM Studio"
      :host "127.0.0.1:1234"
      :endpoint "/v1/chat/completions"
      :key "not-needed"
      :models '(mistralai/ministral-3-3b)))

  (setopt gptel-expert-commands t
    gptel-default-mode 'org-mode
    gptel-org-branching-context t
    gptel-include-reasoning t)

  (setopt gptel-backend my/gptel-lmstudio-backend)
  (setopt gptel-model my/gptel-lmstudio-model)

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
