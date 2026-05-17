;;; ai-aci.el --- AI Code Interface integration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; AI Code Interface provides the unified AI coding workflow.
;; Backend selection is controlled by `my/ai-aci-backend'.
;;
;;; Code:

(defun my/ai-aci-backend-symbol ()
  "Return the AI Code backend symbol selected by `my/ai-aci-backend'."
  (pcase my/ai-aci-backend
    ('codex 'codex)
    ('opencode-go 'opencode)
    ('eca 'eca)
    (_ (user-error "Unknown AI Code backend: %s" my/ai-aci-backend))))

(defun my/ai-aci-configure-backend ()
  "Apply the configured AI Code backend."
  (when (fboundp 'ai-code-set-backend)
    (ai-code-set-backend (my/ai-aci-backend-symbol))))

(when (or my/enable-ai my/ai-enable-aci)
  (use-package ai-code
    :straight (:type git :host github :repo "tninja/ai-code-interface.el")
    :commands (ai-code-menu
               ai-code-set-backend
               ai-code-select-backend
               ai-code-install-backend-skills)
    :config
    (my/ai-aci-configure-backend))

  (when (eq my/ai-aci-backend 'eca)
    (use-package eca
      :straight (:type git :host github :repo "editor-code-assistant/eca-emacs")
      :commands (eca
                 eca-session
                 eca-chat-open
                 eca-chat-send-prompt
                 eca-chat--get-last-buffer))))

(provide 'ai-aci)
;;; ai-aci.el ends here
