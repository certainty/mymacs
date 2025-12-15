;;; my-tools-pass.sel --- pass -*- lexical-binding: t; -*-

(use-package pass
  :after epa
  :init
  (auth-source-pass-enable))

(use-package epa
  :config
  (setq epg-pinentry-mode 'loopback))

(provide 'my-tools-pass)
