;;; core-completion.el --- Completion -*- lexical-binding: t; -*-
;;
;;; Code:

;;; Minibuffer
(use-package emacs
  :init
  (setq enable-recursive-minibuffers t)
  (minibuffer-depth-indicate-mode 1))

(use-package savehist
  :straight (:type built-in)
  :hook (after-init . savehist-mode)
  :custom
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100))

(use-package vertico
  :init
  (vertico-mode)
  :custom
  (vertico-cycle t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (orderless-matching-styles
    '(orderless-initialism  orderless-literal orderless-prefixes))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion orderless)))))

(use-package marginalia
  :hook after-init)


(use-package nerd-icons-completion
  :after (marginalia nerd-icons)
  :hook
  ((after-init . nerd-icons-completion-mode)
    (marginalia-mode . 'nerd-icons-completion-marginalia-setup)))

;;; In-Buffer
(use-package corfu
  :hook
  ((after-init . global-corfu-mode)
    (corfu-mode . corfu-popupinfo-mode)
    (org-mode . (lambda () (setq-local corfu-auto nil))))
  :bind
  (:map corfu-map
    ("C-y" . corfu-insert)
    ("TAB" . corfu-next)
    ("<tab>" . corfu-next)
    ("S-TAB" . corfu-previous)
    ("<backtab>" . corfu-previous)
    ("C-SPC" . corfu-show))
  :custom
  (corfu-auto t)
  (corfu-quit-no-match 'separator)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-min-width 20)
  (corfu-bar-width 0.5)
  (corfu-count 10)
  (corfu-cycle t)
  (corfu-preselect 'valid)
  (corfu-popupinfo-delay '(1.25 . 0.5))

  :config
  (with-eval-after-load 'savehist
    (use-package corfu-history
      :straight (:type built-in)
      :hook corfu-mode)
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history))

  (diminish 'corfu-mode))

(use-package nerd-icons-corfu
  :after corfu
  :init
  (with-eval-after-load 'corfu
    (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)))

(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-style 'nerd-icons)
  (kind-icon-use-icons t)
  (kind-icon-default-face 'corfu-default)
  (kind-icon-blend-background nil)

  :init
  (with-eval-after-load 'corfu
    (add-to-list 'corfu-margin-formatters 'kind-icon-margin-formatter)))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package prescient
  :custom
  (completion-preview-sort-function #'prescient-completion-sort))

(use-package corfu-prescient
  :hook after-init
  :after corfu)

(use-package vertico-prescient
  :hook after-init
  :after vertico)

(provide 'core-completion)
;;; core-completion.el ends here
