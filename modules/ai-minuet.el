;;; ai-minuet.el --- Minuet -*- lexical-binding: t; -*-

(use-package minuet
  :bind
  ((:map mymacs-mode-map
     ("C-M-i" . minuet-complete-with-minibuffer)
     ("M-i" . minuet-show-suggestion))
    (:map minuet-active-mode-map
      ("C-p" . minuet-previous-suggestion)
      ("C-n" . minuet-next-suggestion)
      ("M-y" . minuet-accept-suggestion)
      ("M-a" . minuet-accept-suggestion-line)
      ("C-g" . minuet-dismiss-suggestion)))

  :custom
  (minuet-provider 'openai-fim-compatible)
  (minuet-context-window 1024)
  (minuet-context-ratio 0.75)
  (minuet-request-timeout 4.0)
  (minuet-n-completions 1)
  (minuet-show-error-message-on-minibuffer t)
  (minuet-auto-suggestion-debounce-delay 0.4)
  (minuet-auto-suggestion-throttle-delay 1.2)

  :config
  (plist-put minuet-openai-fim-compatible-options :end-point
    "http://127.0.0.1:11434/v1/completions")
  (plist-put minuet-openai-fim-compatible-options :name "Ollama")
  (plist-put minuet-openai-fim-compatible-options :api-key "USER")
  (plist-put minuet-openai-fim-compatible-options :model "qwen2.5-coder:latest")
  (minuet-set-optional-options minuet-openai-fim-compatible-options :max_tokens 96)
  (minuet-set-optional-options minuet-openai-fim-compatible-options :temperature 0))

(provide 'ai-minuet)

;;; ai-minuet.el ends here
