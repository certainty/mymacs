;;; core-keys.el --- Keybinding infrastructure -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;; Evil is the way :)
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
    evil-want-keybinding nil
    evil-undo-system 'undo-redo
    evil-want-C-u-scroll t
    evil-want-C-d-scroll t
    evil-respect-visual-line-mode t)
  :config
  (evil-mode 1)
  (evil-global-set-key 'insert (kbd "C-y") nil) ;; free up C-y in insert mode
  (evil-global-set-key 'motion (kbd "C-y") nil)
  (evil-global-set-key 'normal (kbd "C-y") nil)
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line))

(use-package evil-collection
  :demand t
  :after evil
  :config
  (evil-collection-init))

(use-package general
  :demand t
  :config
  (general-create-definer leader-def
    :states '(normal visual)
    :keymaps 'mymacs-mode-map
    :prefix "SPC"
    :non-normal-prefix "C-SPC"
    :global-prefix "C-c")

  (general-create-definer local-leader-def
    :states '(normal visual)
    :prefix "SPC m"
    :non-normal-prefix "C-SPC m")

  (leader-def
    "TAB" '(:ignore t :which-key "workspaces")
    "a" '(:ignore t :which-key "ai")
    "n" '(:ignore t :which-key "notes")
    "x" '(:ignore t :which-key "execute")
    "f" '(:ignore t :which-key "files")
    "b" '(:ignore t :which-key "buffers")
    "s" '(:ignore t :which-key "search")
    "g" '(:ignore t :which-key "goto")
    "o" '(:ignore t :which-key "org")
    "p" '(:ignore t :which-key "project")
    "t" '(:ignore t :which-key "toggle")
    "v" '(:ignore t :which-key "vc")
    "w" '(:ignore t :which-key "window")
    "u" 'universal-argument))

(use-package which-key
  :straight (:type built-in)
  :hook after-init
  :custom
  (which-key-sort-order 'which-key-prefix-then-key-order)
  (which-key-max-display-columns 10)
  (which-key-show-early-on-C-h t)
  (which-key-show-prefix nil)
  (which-key-idle-delay .75)
  (which-key-idle-secondary-delay 0.05)
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-setup-minibuffer)
  (which-key-separator " • ")
  (which-key-prefix-prefix nil))


(when (eq system-type 'darwin)
  (setopt mac-command-modifier 'super
    mac-option-modifier 'meta
    mac-right-option-modifier 'none))

(provide 'core-keys)
;;; core-keys.el ends here
