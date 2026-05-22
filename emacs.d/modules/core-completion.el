;;; core-completion.el --- Completion setup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Minibuffer completion (vertico, orderless, marginalia) and in-buffer
;; completion (corfu, cape).  This module also sets up prescient for
;; sorting and filtering.
;;
;;; Code:

;;; Minibuffer
(use-package emacs
  :init
  (setq enable-recursive-minibuffers t)
  (minibuffer-depth-indicate-mode 1))

(use-package savehist
  :hook (after-init . savehist-mode)
  :custom
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100))

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle t)
  :config
  (vertico-multiform-mode)
  (add-to-list 'vertico-multiform-categories '(embark-keybinding grid)))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (orderless-matching-styles
    '(orderless-initialism orderless-literal orderless-prefixes))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion orderless)))))

(use-package marginalia
  :ensure t
  :hook after-init)

(use-package nerd-icons-completion
  :ensure nil
  :after (marginalia nerd-icons)
  :hook
  ((after-init . nerd-icons-completion-mode)
    (marginalia-mode . nerd-icons-completion-marginalia-setup)))

;;; In-Buffer
(use-package corfu
  :ensure t
  :preface
  (defun my/disable-corfu-auto ()
    "Disable automatic corfu popup in the current buffer."
    (setq-local corfu-auto nil))
  :hook
  ((after-init . global-corfu-mode)
    (org-mode . my/disable-corfu-auto))
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

  :config)
(with-eval-after-load 'savehist
  (use-package corfu-history
    :ensure nil
    :hook corfu-mode)
  (corfu-history-mode 1)
  (add-to-list 'savehist-additional-variables 'corfu-history))

(diminish 'corfu-mode)

(use-package nerd-icons-corfu
  :ensure nil
  :init
  (with-eval-after-load 'corfu
    (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)))

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package prescient
  :ensure nil
  :custom
  (completion-preview-sort-function #'prescient-completion-sort))

(use-package corfu-prescient
  :ensure nil
  :hook after-init
  :after corfu)

(use-package vertico-prescient
  :ensure nil
  :hook after-init
  :after vertico)

(provide 'core-completion)
;;; core-completion.el ends here
