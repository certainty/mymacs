;;; my-ai.el --- simple ai integration -*- lexical-binding: t; -*-

(when my/gptel-enabled
  (use-package macher
    :ensure t
    :pin "melpa"
    :custom
    (macher-action-buffer-ui 'org)

    :hook
    ;; Set up action buffer behavior to your liking.  Alternately, do
    ;; this more generally in your `gptel-mode-hook'.
    (macher-action-buffer-setup
     . (lambda ()
         ;; Auto-scroll responses.
         (setq-local window-point-insertion-type t)
         ;; Wrap lines.
         (visual-line-mode 1)))

     :config
     (macher-install)
     (macher-enable)
     (my/push-display-buffer-rule
      "\\*macher:.*\\*" (my/side-window-config 'special-mode))
     (my/push-display-buffer-rule
      "\\*macher-patch:.*\\*" (my/side-window-config 'special-mode)))

    
  (use-package gptel
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

    (gptel-make-preset 'json
      :pre (lambda ()
             (setq-local gptel--schema
                         (buffer-substring-no-properties
                          (point) (point-max)))
             (delete-region (point) (point-max)))
      :include-reasoning nil)

    (gptel-make-preset 'websearch
      :description  "Search only"
      :temperature  0.7
      :tools        '("search_web" "read_url" "get_youtube_meta"))
    
    (cond
     ((string-equal my/gptel-provider "mistral")
      (setq gptel-backend my/gptel-backend-mistral)
      (setq gptel-model 'mistral-medium-latest))
     ((string-equal my/gptel-provider "openai")
      (setq gptel-backend (gptel-make-openai-oauth "OpenAI sub"))
      (setq gptel-mode 'gpt-6-luna)))))

(provide 'my-ai)
