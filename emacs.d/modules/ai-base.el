;;; ai-base.el --- AI agent interaction via ACP -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Agent-shell provides a native Emacs comint shell for interacting with
;; LLM agents via the Agent Client Protocol (ACP).  Configured here for
;; OpenCode as the primary agent.
;;
;; Requirements:
;;   - opencode CLI installed: https://opencode.ai/
;;   - Authenticated via `opencode auth login'
;;
;; TRAMP Awareness:
;;   Agent-shell runs locally as a subprocess (uses shell-maker/comint).
;;   The opencode agent process itself runs on the local machine but can
;;   access and edit remote files when working in TRAMP buffers via
;;   Emacs' buffer-local context.
;;
;;; Code:

;;; Agent Shell with OpenCode via ACP

(use-package agent-shell
  :commands (agent-shell
             agent-shell-new-shell
             agent-shell-toggle
             agent-shell-opencode-start-agent)
  :custom
  ;; Use opencode as the default agent
  (agent-shell-preferred-agent-config (agent-shell-opencode-make-agent-config))
  ;; Prompt for session handling on new shells
  (agent-shell-session-strategy 'prompt)
  :config
  ;; Register as side popup if the helper exists
  (when (fboundp 'my/register-side-popup)
    (my/register-side-popup 'agent-shell-mode t nil)))

(provide 'ai-base)
;;; ai-base.el ends here
