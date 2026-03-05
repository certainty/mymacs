;;; ai-gptel.el --- gptel -*- lexical-binding: t; -*-


(use-package gptel
  :preface
  (define-prefix-command '+gptel)
  (define-key +ai (kbd "a") (cons "+gptel" +gptel))

  :bind
  (:map +goto/act
    ("A" . gptel))
  (:map +gptel
    ("a" . gptel)
    ("m" . gptel-menu)
    ("s" . gptel-send)
    ("r" . gptel-rewrite)
    ("." . gptel-add)
    ("f" . gptel-add-file))
  (:map gptel-mode-map
    ("C-c C-s" . gptel-stop-streaming)
    ("C-c C-c" . gptel-send)
    ("C-c C-r" . gptel-rewrite)
    ("C-c C-a" . gptel-add)
    ("C-c C-f" . gptel-add-file))

  :config
  (defun my/gptel--ollama-backend ()
    (when (executable-find "ollama")
      (gptel-make-ollama
        "Ollama"
        :host "127.0.0.1:11434"
        :protocol "http"
        :endpoint "/api/chat"
        :models '(qwen2.5-coder:latest)
        :stream t)))

  (defun my/gptel--select-backend ()
    (let ((ollama (my/gptel--ollama-backend)))
      (if ollama
        (setopt gptel-backend ollama
          gptel-model (intern "qwen2.5-coder:latest"))
        (message "gptel: Ollama backend not available. Ensure `ollama` is installed and the server is running."))))

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
  :preface
  (define-prefix-command '+elysium)
  (define-key +ai (kbd "e") (cons "+elysium" +elysium))

  :bind
  (:map +elysium
    ("e" . elysium-query)
    ("c" . elysium-add-context)
    ("w" . elysium-toggle-window)
    ("a" . elysium-keep-all-suggested-changes)
    ("d" . elysium-discard-all-suggested-changes))
  :custom
  (elysium-window-size 0.33)
  (elysium-window-style 'vertical))

(provide 'ai-gptel)
