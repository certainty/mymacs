;;; my-evil.el --- evil mode -*- lexical-binding: t; -*-
(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-want-minibuffer nil
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

(use-package evil-collection
  :hook (after-init . evil-collection-init)
  :after evil)

(use-package evil-args
  :after evil)
(use-package evil-easymotion
  :after evil)

(use-package evil-embrace
  :after evil)

(use-package evil-escape
  :hook after-init)

(use-package evil-exchange)

(use-package evil-surround
  :hook (after-init . global-evil-surround-mode)
  :after evil-embrace
  :config
  (evil-embrace-enable-evil-surround-integration))

(use-package evil-visualstar
  :hook (after-init . global-evil-visualstar-mode))

(use-package evil-traces
  :hook after-init)

(use-package evil-nerd-commenter
  :init
  (evilnc-default-hotkeys))

(use-package evil-indent-plus
  :init
  (evil-indent-plus-default-bindings))

(provide 'my-evil)
