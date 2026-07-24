;; -*- lexical-binding: t; -*-

;;; Code:

(require 'use-package)

(use-package agent-shell
  :ensure t
  :pin "melpa"
  :commands (agent-shell
             agent-shell-openai-start-codex)
  :custom
  (agent-shell-openai-default-model-id my/agent-shell-codex-model)
  (agent-shell-openai-default-session-mode-id my/agent-shell-codex-effort))

(provide 'my-agent-shell)
