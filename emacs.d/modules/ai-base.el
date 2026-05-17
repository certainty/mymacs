;;; ai-base.el --- AI assistant integration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; AI Code Interface is the main frontend.  It provides one stable menu and
;; backend selection layer, while ECA remains available as an optional backend.
;; Backend choice is centralized in `core-config.el' via `my/ai-provider'.
;;
;;; Code:

(defun my/ai-code-backend ()
  "Return the `ai-code' backend symbol selected by `my/ai-provider'."
  (pcase my/ai-provider
    ('codex 'codex)
    ('opencode-go 'opencode)
    ('eca 'eca)
    (_ (user-error "Unknown AI provider: %s" my/ai-provider))))

(defun my/ai-configure-backend ()
  "Apply the configured AI backend."
  (when (fboundp 'ai-code-set-backend)
    (ai-code-set-backend (my/ai-code-backend))))

(defun my/ai-menu ()
  "Open the AI assistant menu."
  (interactive)
  (if (fboundp 'ai-code-menu)
      (ai-code-menu)
    (user-error "AI Code menu is not available")))

;; Preserve the existing leader-key entry points while moving the
;; implementation to ai-code-interface.el.
(defalias 'agent-shell #'my/ai-menu)
(defalias 'agent-shell-new-shell #'my/ai-menu)
(defalias 'agent-shell-toggle #'my/ai-menu)

(use-package ai-code
  :straight (:type git :host github :repo "tninja/ai-code-interface.el")
  :commands (ai-code-menu
             ai-code-set-backend
             ai-code-select-backend
             ai-code-install-backend-skills)
  :config
  (my/ai-configure-backend))

(use-package eca
  :straight (:type git :host github :repo "editor-code-assistant/eca-emacs")
  :commands (eca
             eca-session
             eca-chat-open
             eca-chat-send-prompt
             eca-chat--get-last-buffer))

(provide 'ai-base)
;;; ai-base.el ends here
