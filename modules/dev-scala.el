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
  :general
  (local-leader-def
    :keymaps 'scala-ts-mode-map
    "b" '(:ignore t :which-key "build")
    "bb" 'sbt-start
    "bc" 'sbt-do-compile
    "bt" 'sbt-do-test
    "br" 'sbt-do-run
    "bC" 'sbt-do-clean
    "bp" 'sbt-do-package

    "t" '(:ignore t :which-key "test")
    "tt" 'sbt-do-test
    "to" 'sbt-do-test-only
    "tq" 'sbt-do-test-quick


    "h" '(:ignore t :which-key "help")
    "hh" 'eldoc-doc-buffer
    "ht" 'eglot-type-hierarchy)
  :custom
  (scala-ts-mode-indent-offset 2))

;;;; SBT Mode
(use-package sbt-mode
  :defer t
  :commands (sbt-start sbt-command)
  :general
  (local-leader-def
    :keymaps 'scala-ts-mode-map
    "s" '(:ignore t :which-key "sbt")
    "ss" 'sbt-start
    "sc" 'sbt-command
    "sr" 'sbt-run-previous-command)
  :custom
  (sbt:program-name "sbt")
  (sbt:default-command-flags '("-Dsbt.supershell=false"))
  :config
  ;; WORKAROUND: allows using SPACE when in the minibuffer
  (substitute-key-definition
    'minibuffer-complete-word
    'self-insert-command
    minibuffer-local-completion-map)

  ;; sbt-supershell causes issues with Emacs
  (setq sbt:prefer-nested-projects t))

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

;;;; Scala REPL support
(defun scala-run-main ()
  "Run Scala main class with sbt."
  (interactive)
  (let ((main-class (read-string "Main class: ")))
    (sbt-command (format "runMain %s" main-class))))

(defun scala-test-only ()
  "Run specific Scala test."
  (interactive)
  (let ((test-class (read-string "Test class: ")))
    (sbt-command (format "testOnly %s" test-class))))

(provide 'dev-scala)
;;; dev-scala.el ends here
