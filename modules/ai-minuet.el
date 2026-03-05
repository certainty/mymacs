;;; ai-minuet.el --- Minuet + Ollama configuration -*- lexical-binding: t; -*-

(require 'subr-x)

(defgroup my/minuet nil
  "Minuet completion helpers."
  :group 'applications)

(defcustom my/minuet-ollama-host nil
  "Host (and optional port) for Ollama's HTTP server.
When nil, fall back to $OLLAMA_HOST or `localhost:11434'."
  :type '(choice (const :tag "Use environment" nil) string)
  :group 'my/minuet)

(defcustom my/minuet-ollama-model "qwen2.5-coder:3b"
  "Default Ollama model used for Minuet completions."
  :type 'string
  :group 'my/minuet)

(defcustom my/minuet-ollama-api-key-var "TERM"
  "Environment variable name to read for the Ollama placeholder key.
When nil, the environment is ignored."
  :type '(choice (const :tag "Do not use environment" nil) string)
  :group 'my/minuet)

(defcustom my/minuet-ollama-api-key-placeholder "ollama-placeholder"
  "Fallback API key string passed to Minuet when no environment variable is set."
  :type 'string
  :group 'my/minuet)

(defun my/minuet--ollama-api-key ()
  "Return a placeholder API key for Ollama.
If `my/minuet-ollama-api-key-var' resolves to an environment variable, use its
value; otherwise fall back to `my/minuet-ollama-api-key-placeholder'."
  (or (and my/minuet-ollama-api-key-var
           (getenv my/minuet-ollama-api-key-var))
      my/minuet-ollama-api-key-placeholder))

(defun my/minuet--ollama-endpoint ()
  "Return the full endpoint URL for the Ollama completions API."
  (let* ((raw (or my/minuet-ollama-host (getenv "OLLAMA_HOST") "localhost:11434"))
         (raw (string-remove-suffix "/" raw)))
    (if (string-prefix-p "http" raw)
        (format "%s/v1/completions" raw)
      (format "http://%s/v1/completions" raw))))

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
  (let ((endpoint (my/minuet--ollama-endpoint)))
    (plist-put minuet-openai-fim-compatible-options :end-point endpoint)
    (plist-put minuet-openai-fim-compatible-options :name (format "Ollama (%s)" my/minuet-ollama-model))
    (plist-put minuet-openai-fim-compatible-options :model my/minuet-ollama-model)
    (plist-put minuet-openai-fim-compatible-options :api-key #'my/minuet--ollama-api-key)
    (minuet-set-optional-options minuet-openai-fim-compatible-options :max_tokens 128)
    (minuet-set-optional-options minuet-openai-fim-compatible-options :top_p 0.9)))

(provide 'ai-minuet)

;;; ai-minuet.el ends here
