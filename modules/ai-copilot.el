;;; ai-copilot.el --- copilot support -*- lexical-binding: t; -*-


(use-package copilot
  :straight (:host github :repo "copilot-emacs/copilot.el" :files ("*.el"))
  :preface
  (define-prefix-command '+copilot)
  (define-key +ai (kbd "c") (cons "+copilot" +copilot))
  (defun +copilot-auto-trigger ()
    "Toggles copilot automatic trigger"
    (interactive)
    (if copilot-idle-delay
      (progn
        (setq copilot-idle-delay nil)
        (message "copilot auto-trigger disabled"))
      (progn
        (setq copilot-idle-delay 0.5)
        (message "copilot auto-trigger enabled"))))
  :bind
  (:map +toggle
    ("c" . +copilot-auto-trigger))
  (:map +goto/act
    ("c" . copilot-complete))
  (:map +copilot
    ("C" . copilot-mode)
    ("i" . copilot-install-server)
    ("p" . copilot-panel-complete)
    ("l" . copilot-login)
    ("x" . copilot-logout))
  (:map copilot-mode-map
    ("M-y" . copilot-accept-completion)
    ("M-Y" . copilot-accept-completion-by-word)
    ("C-M-y" . copilot-accept-completion-by-line)
    ("M-]" . copilot-next-completion)
    ("M-[" . copilot-previous-completion)
    ("C-c C-c" . copilot-clear-completion)
    ("C-c C-r" . copilot-reject-completion))
  :custom
  (copilot-idle-delay nil)
  :init
  (add-hook 'prog-mode-hook 'copilot-mode))

(provide 'ai-copilot)
