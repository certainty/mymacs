;;; dev-scala.el --- Scala configuration with Metals -*- lexical-binding: t -*-

;;; Commentary:
;; Scala development with tree-sitter, Metals LSP, and sbt

;;; Code:

;;;; Scala Tree-sitter Mode
(use-package scala-ts-mode
  :mode (("\\.scala\\'" . scala-ts-mode)
          ("\\.sc\\'" . scala-ts-mode)
          ("\\.sbt\\'" . scala-ts-mode))
  :hook (scala-ts-mode . eglot-ensure)
  :preface
  (defun +scala-run-main ()
    "Run Scala main class with sbt."
    (interactive)
    (let ((main-class (read-string "Main class: ")))
      (sbt-command (format "runMain %s" main-class))))

  (defun +scala-test-only ()
    "Run specific Scala test."
    (interactive)
    (let ((test-class (read-string "Test class: ")))
      (sbt-command (format "testOnly %s" test-class))))


  :custom
  (scala-ts-mode-indent-offset 2)

  :config
  (use-package sbt-mode
    :demand t
    :custom
    (sbt:program-name "sbt")
    (sbt:default-command-flags '("-Dsbt.supershell=false"))

    :bind
    (:map scala-ts-mode-map
      ("C-c C-k" . sbt-do-clean)
      ("C-c C-c" . sbt-do-compile)
      ("C-c C-t" . sbt-do-test)
      ("C-c C-o" . +scala-test-only)
      ("C-c C-r" . sbt-command)
      ("C-c C-x" . +scala-run-main))


    :config
    ;; WORKAROUND: allows using SPACE when in the minibuffer
    (substitute-key-definition
      'minibuffer-complete-word
      'self-insert-command
      minibuffer-local-completion-map)

    ;; sbt-supershell causes issues with Emacs
    (setq sbt:prefer-nested-projects t)))

;;;; Metals Configuration
;; Metals (Scala LSP) works via Eglot
;; Make sure metals-emacs is installed and in PATH
(with-eval-after-load 'eglot
  ;; Add Metals to eglot server programs
  (add-to-list 'eglot-server-programs
    '(scala-ts-mode . ("metals")))

  ;; Metals-specific settings
  (defclass eglot-metals (eglot-lsp-server) ()
    :documentation "Metals LSP server for Scala.")

  (cl-defmethod eglot-initialization-options ((server eglot-metals))
    "Metals initialization options."
    `(:isHttpEnabled t
       :statusBarProvider "log-message"
       :compilerOptions
       (:snippetAutoIndent t
         :overrideDefFormat "unicode")
       :scalafixConfigPath ".scalafix.conf")))


(provide 'dev-scala)
;;; dev-scala.el ends here
