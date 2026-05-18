;;; core-editing.el --- Editing fundamentals -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Basic editing settings, snippet support (yasnippet), action menu
;; (embark), and whitespace management.
;;
;;; Code:

(use-package emacs
  :custom
  (show-paren-delay 0)
  :init
  (show-paren-mode 1)
  (electric-pair-mode -1)
  (electric-indent-mode -1)
  (global-auto-revert-mode 1))

(use-package display-line-numbers
  :straight (:type built-in)
  :hook prog-mode
  :custom
  (display-line-numbers-type t)
  (display-line-numbers-width-start t))

;;; Embark - Context-sensitive actions
(use-package embark
  :bind
  (:map mymacs-mode-map
    ("C-." . embark-act)
    ("C-," . embark-dwim))
  (:map minibuffer-local-map
    ("C-c C-c" . embark-collect)
    ("C-c C-e" . embark-export)
    ("C-c C-m" . embark-select)
    ("C-c C-a" . embark-act-all))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  (keymap-set global-map "C-." 'embark-act)
  (keymap-set global-map "C-," 'embark-dwim)

  (with-eval-after-load 'vertico
    (keymap-set vertico-map "C-." 'embark-act)
    (keymap-set vertico-map "C-," 'embark-dwim))

  (add-to-list 'display-buffer-alist
    '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
       nil
       (window-parameters (mode-line-format . none))))

  :custom
  ;; Use Vertico to list Embark actions directly in the minibuffer.
  (embark-prompter #'embark-completing-read-prompter)
  (embark-indicators
    '(embark-highlight-indicator
       embark-isearch-highlight-indicator)))

(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;;; Whitespace management
(use-package ws-butler
  :straight nil
  :load-path "vendor"
  :hook (after-init . ws-butler-global-mode))

(provide 'core-editing)
;;; core-editing.el ends here
