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
    :states '(normal visual insert emacs)
    :keymaps 'mymacs-mode-map
    :prefix "SPC"
    :non-normal-prefix "C-SPC")

  (general-create-definer local-leader-def
    :states '(normal visual)
    :keymaps 'override
    :prefix "SPC m"
    :non-normal-prefix "C-SPC m")

  (leader-def
   "TAB" '(:ignore t :which-key "workspaces")
   "f" '(:ignore t :which-key "files")
   "b" '(:ignore t :which-key "buffers")
   "m" '(:ignore t :which-key "mode")
   "M" '(:ignore t :which-key "mymacs")
   "s" '(:ignore t :which-key "search")
   "g" '(:ignore t :which-key "goto")
   "p" '(:ignore t :which-key "project")
   "W" '(:ignore t :which-key "writing")
   "o" '(:ignore t :which-key "open")
   "t" '(:ignore t :which-key "toggle")
   "v" '(:ignore t :which-key "vc")
   "w" '(:ignore t :which-key "window")))

(use-package which-key
  :straight (:type built-in)
  :demand t
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
  (which-key-prefix-prefix nil)
  :config
  (which-key-mode))


(when (eq system-type 'darwin)
  (setopt mac-command-modifier 'super
          mac-option-modifier 'meta
          mac-right-option-modifier 'none))

(provide 'core-keys)
;;; core-keys.el ends here
