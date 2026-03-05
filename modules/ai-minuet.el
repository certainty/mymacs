;;; ai-minuet.el --- Minuet + Ollama configuration -*- lexical-binding: t; -*-

(require 'subr-x)


(use-package minuet
  :preface
  (define-prefix-command '+minuet)
  (define-key +ai (kbd "m") (cons "+minuet" +minuet))

  :bind
  (:map +minuet
    ("m" . minuet-complete-with-minibuffer)
    ("s" . minuet-show-suggestion)
    ("n" . minuet-next-suggestion)
    ("p" . minuet-previous-suggestion)
    ("a" . minuet-accept-suggestion)
    ("l" . minuet-accept-suggestion-line)
    ("d" . minuet-dismiss-suggestion))
  (:map +goto/act
    ("c" . minuet-complete-with-minibuffer))

  :custom
  (minuet-provider 'openai-fim-compatible)
  (minuet-context-window 8000)
  (minuet-context-ratio 0.7)
  (minuet-request-timeout 5)
  (minuet-n-completions 2)
  (minuet-add-single-line-entry t)
  (minuet-show-error-message-on-minibuffer t)
  (minuet-after-cursor-filter-length 20)
  (minuet-before-cursor-filter-length 3)
  (minuet-auto-suggestion-throttle-delay 1.2)
  (minuet-auto-suggestion-debounce-delay 0.6)

  :config
  (plist-put minuet-openai-fim-compatible-options :end-point "http://localhost:11434/v1/completions")
  (plist-put minuet-openai-fim-compatible-options :name "Ollama")
  (plist-put minuet-openai-fim-compatible-options :api-key "TERM")
  (plist-put minuet-openai-fim-compatible-options :model "qwen2.5-coder")
  (minuet-set-optional-options minuet-openai-fim-compatible-options :top_p 0.9)
  (minuet-set-optional-options minuet-openai-fim-compatible-options :max_tokens 128))

(provide 'ai-minuet)

;;; ai-minuet.el ends here
