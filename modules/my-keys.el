;;; my-keys.el --- key setup -*- lexical-binding: t; -*-

;;; General

(use-package general
  :after evil
  :demand t
  :ensure (:wait t) ; required to make sure we hook into elpaca / use-package
  :config
  (defmacro my/define-general-map (infix)
    "Define a general keymap and corresponding definer using INFIX symbol."
    (let* ((prefix-map (intern (format "my-%s-keymap" infix)))
         (definer (intern (format "my/bind-%s-map" infix))))
      `(progn
         (general-define-key
          :states '(normal visual motion)
          :prefix-map ',prefix-map)
         (general-create-definer ,definer
           :keymaps ',prefix-map))))

 (general-define-key
    :states '(normal visual motion)
    :global-prefix "M-SPC"
    :prefix-map 'my-local-leader-keymap)

  (general-create-definer my/bind-local-leader
    :keymaps 'my-local-leader-keymap)

  (my/define-general-map point-leader)
  (my/define-general-map help)
  (my/define-general-map project)
  (my/define-general-map buffer)
  (my/define-general-map file)
  (my/define-general-map ux)
  (my/define-general-map vcs)
  (my/define-general-map diagnostics)
  (my/define-general-map window)
  (my/define-general-map lsp)
  (my/define-general-map open)
  (my/define-general-map writing)
  (my/define-general-map gtd)
  (my/define-general-map ai)

  (general-define-key
   :states '(normal visual motion)
   :prefix-map 'goto-map)

  (general-create-definer my/bind-goto-map
    :keymaps 'goto-map)

  (general-define-key
   :states '(normal visual motion)
   :prefix-map 'search-map)

  (general-create-definer my/bind-search-map
    :keymaps 'search-map)

  (general-define-key
    :states '(normal visual motion)
    :prefix-map 'my-global-leader-keymap
    :global-prefix "C-SPC"
    :prefix "SPC"
    "x" '("M-x" . execute-extended-command)
    "SPC" '("File" . project-find-file)
    "!" '(:keymap my-diagnostics-keymap :which-key "+diagnostics")
    "a" '(:keymap my-ai-keymap :which-key "+ai")
    "m" '(:keymap my-local-leader-keymap :which-key "+leader/local")
    "." '(:keymap my-point-leader-keymap :which-key "+leader/point")
    "h" '(:keymap my-help-keymap :which-key "+help")
    "c" '(:keymap my-lsp-keymap :which-key "+lsp")
    "b" '(:keymap my-buffer-keymap :which-key "+buffer")
    "f" '(:keymap my-file-keymap :which-key "+file")
    "n" '(:keymap my-writing-keymap :which-key "+write")
    "p" '(:keymap my-project-keymap :which-key "+project")
    "s" '(:keymap search-map :which-key "+search")
    "t" '(:keymap my-gtd-keymap :which-key "+gtd")
    "g" '(:keymap goto-map :which-key "+goto")
    "o" '(:keymap my-open-keymap :which-key "+open")
    "u" '(:keymap my-ux-keymap :which-key "+ux")
    "v" '(:keymap my-vcs-keymap :which-key "+vcs")
    "w" '(:keymap my-window-keymap :which-key "+window"))

  (general-create-definer my/bind-global-leader
    :keymaps 'my-global-leader-keymap))

;;; Which-Key
(use-package which-key
  :demand t
  :ensure nil
  :custom
  (which-key-sort-order 'which-key-prefix-then-key-order)
  (which-key-max-display-columns 10)
  (which-key-show-early-on-C-h t)
  (which-key-show-prefix t)
  (which-key-idle-delay .75)
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-separator " • ")
  (which-key-prefix-prefix nil)
  :config
  (which-key-mode 1)
  (which-key-setup-minibuffer))

(provide 'my-keys)
