;;; ai-copilot.el --- copilot support -*- lexical-binding: t; -*-

(use-package copilot
  :straight (:host github :repo "copilot-emacs/copilot.el" :files ("*.el"))
  :general
  (:keymaps 'copilot-mode-map
    "M-y" 'copilot-accept-completion
    "M-]" 'copilot-next-completion
    "M-[" 'copilot-previous-completion
    "C-c C-c" 'copilot-clear-completion
    "C-c C-r" 'copilot-reject-completion)
  :init
  (add-hook 'prog-mode-hook 'copilot-mode))

(provide 'ai-copilot)
