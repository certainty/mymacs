;;; my-code-essentials.el --- Base coding setup -*- lexical-binding: t; -*-


;;; Buffer position
(use-package emacs
  :ensure nil
  :init
  (add-to-list 'display-buffer-alist
               '("\\*\\(Backtrace\\|Compile-log\\|Messages\\|Warnings\\)\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.33)
                 (window-parameters
                  (no-delete-other-windows . nil))))

  (add-to-list 'display-buffer-alist
               '("\\*shell:"
               (display-buffer-below-selected)
               (window-height . 12)))

  (add-to-list 'display-buffer-alist
               '("\\*\\(eldoc\\)\\*"
                 (display-buffer-reuse-window display-buffer-in-side-window)
                 (window-width . 30)
                 (window-parameters . ((no-other-window . t)
                                       (no-delete-other-windows . t)))
                 (dedicated . t)
                 (side . bottom)
                  (slot . 5))))


;;; parens
(use-package paren
  :ensure nil
  :hook (prog-mode . show-paren-mode)
  :custom
  (show-paren-delay 0))

(use-package highlight-parentheses
  :hook prog-mode)

;;; todo
(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :custom
  (hl-todo-keyword-faces
    `(("TODO" warning bold)
       ("FIXME" error bold)
       ("HACK" warning bold)
       ("DISCUSS" success bold)
       ("DEBUG" success bold)
       ("NOTE" success bold))))


;;; devdocs
(use-package devdocs
  :general
  (my-help-keymap
    "c g" '("find" . devdocs-lookup)
    "c i" '("install" . devdocs-install)
    "c u" '("install" . devdocs-update-all)))

(provide 'my-code-essentials)
