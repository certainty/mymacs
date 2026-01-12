;; -*- lexical-binding: t; -*-


(use-package gptel
  :general
  (leader-def
    "aa" '(:ignore t :which-key "ai")
    "aaa" 'gptel-send
    "aaA" 'gptel
    "aam" 'gptel-menu
    "aar" 'gptel-rewrite
    "aa." 'gptel-add
    "aaf" 'gptel-add-file)
  :config
  (setopt gptel-expert-commands t
    gptel-default-mode 'org-mode
    gptel-org-branching-context t
    gptel-include-reasoning t)

  (setopt gptel-model 'claude-sonnet-4
    gptel-backend (gptel-make-gh-copilot "Copilot"))

  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response)

  (add-to-list 'display-buffer-alist
    '((lambda (bufname action)
        (with-current-buffer bufname
          gptel-mode))
       (display-buffer-in-side-window)
       (side . right)
       (window-width . 0.33)))

  (require 'gptel-integrations))

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
