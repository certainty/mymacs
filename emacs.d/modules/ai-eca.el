;;; ai-eca.el --- ECA integration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; ECA is loaded directly and uses its own native configuration and login flow.
;;
;;; Code:

(when (or my/enable-ai my/ai-enable-eca)
  (use-package eca
    :straight (:type git :host github :repo "editor-code-assistant/eca-emacs")
    :commands (eca
               eca-transient-menu
               eca-session
               eca-chat-open
               eca-chat-send-prompt
               eca-chat--get-last-buffer)))

(provide 'ai-eca)
;;; ai-eca.el ends here
