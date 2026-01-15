;;; tools-secrets.el --- Manage secrets and encryption -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package epa
  :straight (:type built-in)
  :init
  (setq auth-sources
    `((:source ,(my/authinfo-path))))
  (setq epa-pinentry-mode 'ask)
  (setq epg-pinentry-mode 'ask)
  (setenv "GPG_AGENT_INFO" nil) ;force pinentry in emacs
  (setenv "GPG_TTY" "/dev/tty"))

(provide 'tools-secrets)
