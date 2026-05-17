;;; ai-eca.el --- ECA integration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; ECA is configured through its own `ECA_CONFIG' environment variable and
;; user config files.  This module only bridges `my/ai-eca-backend' into that
;; environment so auth/provider choice stays centralised in `core-config.el'.
;;
;;; Code:

(require 'json)

(defconst my/eca-go-models
  '("opencode-go/kimi-k2.6"
    "opencode-go/glm-5.1"
    "opencode-go/deepseek-v4-pro"
    "opencode-go/mimo-v2.5-pro"
    "opencode-go/qwen3.6-plus")
  "Reasonable OpenCode Go model defaults exposed to ECA.")

(defun my/ai-eca-config ()
  "Return an ECA configuration object for `my/ai-eca-backend'.

The Codex/OpenAI path intentionally returns nil so ECA can use its own
`/login' flow when you do not want to preseed an API key."
  (pcase my/ai-eca-backend
    ('codex nil)
    ('opencode-go
     (let ((models (mapcar (lambda (model)
                             (cons model (make-hash-table :test 'equal)))
                           my/eca-go-models)))
       (list (cons "defaultModel" (car my/eca-go-models))
             (cons "providers"
                   (list (cons "opencode-go"
                               (list (cons "api" "openai-chat")
                                     (cons "url" "https://opencode.ai/zen/go/v1")
                                     (cons "key" "${env:OPENCODE_API_KEY}")
                                     (cons "fetchModels" :false)
                                     (cons "models" models))))))))
    ('eca nil)
    (_ (user-error "Unknown ECA backend: %s" my/ai-eca-backend))))

(defun my/ai-eca-apply-config ()
  "Inject ECA config into the environment when needed."
  (let ((config (my/ai-eca-config)))
    (when config
      (setenv "ECA_CONFIG"
              (json-serialize config :null-object nil :false-object :false :true-object :true)))))

(when (or my/enable-ai my/ai-enable-eca)
  (use-package eca
    :straight (:type git :host github :repo "editor-code-assistant/eca-emacs")
    :commands (eca
               eca-transient-menu
               eca-session
               eca-chat-open
               eca-chat-send-prompt
               eca-chat--get-last-buffer)
    :init
    (my/ai-eca-apply-config)))

(provide 'ai-eca)
;;; ai-eca.el ends here
