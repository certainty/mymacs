;;; my-tools-asdf.el --- Manage versions -*- lexical-binding: t; -*-
(use-package asdf
  :ensure (asdf :host github :repo "tabfugnic/asdf.el")
  :hook (elpaca-after-init . asdf-enable))

(use-package envrc
  :hook (elpaca-after-init . envrc-global-mode))

(provide 'my-tools-asdf)
