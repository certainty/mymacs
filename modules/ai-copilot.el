;;; ai-copilot.el --- copilot support -*- lexical-binding: t; -*-

(use-package copilot
  :straight (:host github :repo "copilot-emacs/copilot.el" :files ("*.el"))
  :general
  (leader-def
    "ac" '(:ignore t :which-key "copilot")
    "acC" 'copilot-mode
    "aci" 'copilot-install-server
    "acp" 'copilot-panel-complete
    "acl" 'copilot-login
    "acx" 'copilot-logout)
  (:keymaps 'copilot-mode-map
    "M-y" 'copilot-accept-completion
    "M-]" 'copilot-next-completion
    "M-[" 'copilot-previous-completion
    "C-c C-c" 'copilot-clear-completion
    "C-c C-r" 'copilot-reject-completion)
  :init
  (add-hook 'prog-mode-hook 'copilot-mode))

(provide 'ai-copilot)
