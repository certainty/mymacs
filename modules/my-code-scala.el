;;; my-code-scala.el --- Scala -*- lexical-binding: t; -*-
(use-package scala-ts-mode
  :interpreter ("scala" . scala-mode)
  :hook (scala-ts-mode . eglot-ensure)
  :init
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(scala-mode . ("metals")))
    (add-to-list 'eglot-server-programs '(scala-ts-mode . ("metals")))))

(use-package sbt-mode
  :after scala-ts-mode
  :general
  (sbt-mode-map
   "C-c s" '("SBT hydra" . sbt-hydra))
  :config
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
  (setq sbt:program-options '("-Dsbt.supershell=false")))

(provide 'my-code-scala)
