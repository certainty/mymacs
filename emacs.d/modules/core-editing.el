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
  :hook prog-mode
  :custom
  (display-line-numbers-type t)
  (display-line-numbers-width-start t))

;;; Embark - Context-sensitive actions
(use-package embark
  :ensure t
  :bind
  (:map mymacs-mode-map
    ("C-." . embark-act)
    ("C-," . embark-dwim))
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
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  ;; TODO: do I really need this here again?
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
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;;; Whitespace management
(defun my/delete-trailing-whitespace ()
  "Delete trailing whitespace in buffers where it is appropriate."
  (unless (or buffer-read-only
              (derived-mode-p 'diff-mode 'special-mode))
    (save-excursion
      (delete-trailing-whitespace))))

(defun my/enable-trailing-whitespace-cleanup ()
  "Clean trailing whitespace before saving the current buffer."
  (add-hook 'before-save-hook #'my/delete-trailing-whitespace nil t))

(add-hook 'prog-mode-hook #'my/enable-trailing-whitespace-cleanup)
(add-hook 'text-mode-hook #'my/enable-trailing-whitespace-cleanup)

(provide 'core-editing)
;;; core-editing.el ends here
