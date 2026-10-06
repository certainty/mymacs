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

(defun my/match-pair ()
  "Jump to the matching delimiter or string boundary."
  (interactive)
  (let ((after (char-after))
        (before (char-before)))
    (cond
     ((and after (eq (char-syntax after) ?\())
      (goto-char (1- (scan-sexps (point) 1))))
     ((and after (eq (char-syntax after) ?\)))
      (goto-char (scan-sexps (1+ (point)) -1)))
     ((and before (eq (char-syntax before) ?\)))
      (goto-char (scan-sexps (point) -1)))
     ((nth 1 (syntax-ppss))
      (goto-char (nth 1 (syntax-ppss))))
     (t
      (user-error "No matching delimiter at point")))))

(use-package embrace
  :ensure t
  :pin "melpa"
  :commands (embrace-add embrace-change embrace-delete embrace-commander)
  :bind
  (:map mymacs-mode-map
        ("C-c e" . embrace-commander)))

;;;; core editing / structural
;; Expreg expands regions; Easy-kill selects and kills things at point.
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
        ("C-)" . paredit-forward-slurp-sexp)
        ("C-(" . paredit-backward-slurp-sexp)
        ("C-j" . nil)
        ("M-s" . nil) ;; free the search map
        ) 
  (:repeat-map my/paredit-slurp-repeat-map
               (")" . paredit-forward-slurp-sexp)
               ("(" . paredit-backward-slurp-sexp))
  :load-path "vendor")

(use-package substitute
  :ensure t
  :bind ("C-;" . substitute-target-in-buffer)
  :config
  (setq substitute-fixed-letter-case t)
  (add-hook 'substitute-post-replace-functions #'substitute-report-operation)
  (add-hook 'substitute-post-replace-functions #'sacha-substitute-save-common-edits))

;;;; embark
(use-package embark
  :ensure t
  :bind
  (:map mymacs-mode-map
        ("C-." . embark-act)
        ("C-," . embark-dwim)
        ("C-c ." . embark-act)
        ("C-c ," . embark-dwim))
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
