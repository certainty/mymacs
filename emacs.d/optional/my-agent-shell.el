;;; my-agent-shell.el --- Agent shell configuration helpers -*- lexical-binding: t; -*-

;;; Code:

(use-package acp
  :if my/agent-shell-enabled
  :ensure t
  :pin "melpa")

(use-package agent-shell
  :if my/agent-shell-enabled
  :ensure t
  :pin "melpa"
  :config
  (require 'agent-shell-openai))
(defgroup my-agent-shell nil
  "Local agent-shell configuration."
  :group 'mymacs)

(defcustom my-agent-shell-codex-model "gpt-5.4"
  "Default agent-shell Codex model."
  :type '(choice (const nil) string)
  :set (lambda (symbol value)
         (set-default symbol value)
         (when (boundp 'agent-shell-openai-default-model-id)
           (setopt agent-shell-openai-default-model-id value)))
  :group 'my-agent-shell)

(defcustom my-agent-shell-codex-session-mode "agent"
  "Default agent-shell Codex session mode."
  :type '(choice (const nil) string)
  :set (lambda (symbol value)
         (set-default symbol value)
         (when (boundp 'agent-shell-openai-default-session-mode-id)
           (setopt agent-shell-openai-default-session-mode-id value)))
  :group 'my-agent-shell)

;;;###autoload
(defun +agent-shell-command ()
  "Show command used to start local Codex ACP."
  (interactive)
  (let ((command (car agent-shell-openai-codex-acp-command)))
    (kill-new command)
    (message "%s" command)))

;;;###autoload
(defun +agent-shell-check ()
  "Check local Codex ACP executable."
  (interactive)
  (if-let ((program (executable-find (car agent-shell-openai-codex-acp-command))))
      (message "codex-acp=%s" program)
    (user-error "codex-acp is not on exec-path")))

;;;###autoload
(defun +agent-shell ()
  "Start local Codex agent shell."
  (interactive)
  (agent-shell-openai-start-codex))

(when my/agent-shell-enabled
  (setopt agent-shell-openai-default-model-id my-agent-shell-codex-model
          agent-shell-openai-default-session-mode-id my-agent-shell-codex-session-mode
          agent-shell-command-prefix nil
          agent-shell-path-resolver-function nil))

(provide 'my-agent-shell)

;;; my-agent-shell.el ends here
