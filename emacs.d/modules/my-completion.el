;;; my-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Completion
;; Vertico, Orderless, and Marginalia provide minibuffer completion,
;; matching, and annotations.  Corfu provides in-buffer completion.

;;;; Minibuffer

(use-package vertico
  :ensure t
  :config
  (setq completion-in-region-function #'consult-completion-in-region)
  :init
  (vertico-mode))


(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

(use-package minibuffer
  :custom
  (completion-sort 'historical)
  (completion-eager-update t)
  (completion-eager-display nil)
  (completion-auto-select t)
  (completion-auto-help nil)
  (completions-max-height 8)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completions-format 'vertical))

(use-package icomplete
  :bind
  (:map icomplete-fido-mode-map
        ("M-i" . icomplete-fido-exit)))

;;;; In-buffer completion
(use-package corfu
  :ensure t
  :demand t
  :custom
  (corfu-auto t)
  (global-corfu-minibuffer nil)
  :init
  (setq-default abbrev-mode t)
  :config
  (global-corfu-mode 1))

(provide 'my-completion)
;;; my-completion.el ends here
