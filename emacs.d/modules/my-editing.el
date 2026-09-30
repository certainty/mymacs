;;; my-editing.el --- Editing and Embark configuration -*- lexical-binding: t; -*-

;;; Editing

;;;; handling pairs (quotes, parens, etc.)
(use-package elec-pair
  :bind
  (:map mymacs-mode-map
        ("C-z" . delete-pair))
  :custom
  (delete-pair-blink-delay 0.0)
  (delete-pair-push-mark t)
  :init
  (electric-pair-mode))

;;;; core editing / structural
;; TODO: do we still need it since we have easy-kill enabled?
(use-package expreg
  :ensure t
  :bind
  (:map mymacs-mode-map
        ("C-=" . expreg-expand)
        ("C--" . expreg-contract)))

(use-package paredit
  :hook
  (emacs-lisp-mode . paredit-mode)
  (lisp-mode . paredit-mode)
  :bind
  (:map paredit-mode-map
        ("C-j" . nil))
  :load-path "vendor")

;;;; embark
(use-package embark
  :ensure t
  :bind
  (:map mymacs-mode-map
        ("C-c ." . embark-act)
        ("C-c ," . embark-dwim))
  (:map icomplete-minibuffer-map
        ("C-c ." . embark-act)
        ("C-c ," . embark-dwim)
        ("C-c C-c" . embark-collect)
        ("C-c C-e" . embark-export)
        ("C-c C-m" . embark-select)
        ("C-c C-a" . embark-act-all))
  (:map minibuffer-mode-map
        ("C-c C-c" . embark-collect)
        ("C-c C-e" . embark-export)
        ("C-c C-m" . embark-select)
        ("C-c C-a" . embark-act-all))
  (:map minibuffer-local-map
        ("C-c C-c" . embark-collect)
        ("C-c C-e" . embark-export)
        ("C-c C-m" . embark-select)
        ("C-c C-a" . embark-act-all))
  :custom
  (embark-indicators '(embark-minimal-indicator
                       embark-highlight-indicator
                       embark-isearch-highlight-indicator))
  (prefix-help-command 'embark-prefix-help-command)
  :init
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameter (mode-line-format . none)))))

(use-package embark-consult
  :after consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(provide 'my-editing)
;;; my-editing.el ends here
