;; -*- lexical-binding: t; -*-
;;

(use-package gptel
  :config
  (setopt gptel-expert-commands t
    gptel-default-mode 'org-mode
    gptel-org-branching-context t
    gptel-include-reasoning t)

  (when (my/featurep 'context-private)
    (setopt
      gptel-model 'qwen2.5-coder:7b
      gptel-backend (gptel-make-ollama "Ollama" :host "localhost:11434" :stream t :models '(qwen2.5-coder:14b qwen2.5-coder:7b qwen2.5-coder:latest gemma3:latest llama3.1:latest deepseek-r1:latest))))

  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response)

  (require 'gptel-integrations))

(use-package llm-tool-collection
  :straight  (:type git  :host github :repo "skissue/llm-tool-collection")
  :after gptel
  :config
  (mapcar (apply-partially #'apply #'gptel-make-tool)
    (llm-tool-collection-get-tag 'editing)))

(use-package elysium
  :custom
  (elysium-window-size 0.33)
  (elysium-window-style 'vertical))


(provide 'ai-gptel)
