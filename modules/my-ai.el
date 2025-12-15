;;; my-ai.el --- AI -*- lexical-binding: t; -*-

;;; copilot
(use-package track-changes)
(use-package copilot
  :hook (prog-mode . copilot-mode)
  :general
  (:states 'insert
   "C-." '("ai complete" . copilot-complete))
  :config
  (setq warning-suppress-types '((copilot)))
  (setq copilot-idle-delay nil)
  (setq copilot-enable-predicates nil))

;;; Gptel
(use-package gptel
  :commands (gptel-send gptel-menu gptel)
  :general
  (my-ai-keymap
   "a" '("chat" . gptel)
   "m" '("menu" . gptel-menu)
   "." '("send" . gptel-send))
  :init
  (defun is-gptel-buffer-p (buffer-name _action)
    (with-current-buffer (get-buffer buffer-name)
      (bound-and-true-p gptel-mode)))

  :custom
  (gptel-expert-commands t)
  (gptel-default-mode 'org-mode)
  (gptel-org-branching-context t)
  (gptel-model 'claude-sonnet-4)
  (gptel-include-reasoning t)

  :config
  (setq gptel-backend (gptel-make-gh-copilot "Copilot"))
  (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response)

  ;; presets
  (gptel-make-preset 'o4mini
    :description "O4mini"
    :backend "Copilot"
    :model 'o4-mini
    :use-context 'system)

  (gptel-make-preset 'coder
    :description "Coding expert"
    :backend "Copilot"
    :model 'claude-opus-4
    :use-context 'system)

  (gptel-make-preset 'reviewer
    :description "Code review"
    :backend "Copilot"
    :model 'gemini-2.5-pro
    :use-context 'system)

  (gptel-make-preset 'architect
    :description "Preset for software architecture tasks"
    :backend "Copilot"
    :model 'claude-sonnet-4
    :use-context 'system))

(use-package gptel-quick
  :ensure (gptel-quick :host github :repo "karthink/gptel-quick")
  :custom
  (gptel-quick-use-context t)
  (gptel-quick-word-count 20)

  :init
  (with-eval-after-load 'embark
    (keymap-set embark-general-map "?" #'gptel-quick)
    (keymap-set embark-symbol-map "?" #'gptel-quick)
    (keymap-set embark-region-map "?" #'gptel-quick)))

(provide 'my-ai)
