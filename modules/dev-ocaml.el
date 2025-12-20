;;; dev-ocaml.el --- Let the types be with you -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package tuareg
  :mode (("\\.ocamlinit\\'" . tuareg-mode)))

(use-package dune)

(use-package opam-switch-mode
  :hook
  (tuareg-mode . opam-switch-mode))

(use-package ocp-indent
  :config
  (add-hook 'ocaml-eglot-hook 'ocp-setup-indent))


(use-package ocaml-eglot
  :after tuareg
  :hook
  (tuareg-mode . ocaml-eglot)
  (ocaml-eglot . eglot-ensure)
  :config
  (setq ocaml-eglot-syntax-checker 'flymake))

(provide 'dev-ocaml)
