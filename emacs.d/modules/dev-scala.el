;;; dev-scala.el --- Scala development -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Scala support via scala-ts-mode and Metals (eglot).  Uses sbt-mode
;; for REPL interaction.  Test/compile targets are provided by
;; projection-multi-compile (detects build.sbt).
;;
;;; Code:

;;; Scala tree-sitter mode
(use-package scala-ts-mode
  :mode ("\\.scala\\'" "\\.sc\\'" "\\.sbt\\'")
  :hook (scala-ts-mode . eglot-ensure)
  :custom
  (scala-ts-mode-indent-offset 2))

;;; SBT (build tool / REPL)
(use-package sbt-mode
  :commands (sbt-start sbt-command sbt-do-compile sbt-do-test sbt-do-clean)
  :custom
  (sbt:program-name "sbt")
  (sbt:default-command-flags '("-Dsbt.supershell=false"))
  (sbt:prefer-nested-projects t)
  :config
  ;; Allow spaces in sbt minibuffer input
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)

  :bind
  (:map scala-ts-mode-map
        ("C-c C-k" . sbt-do-clean)
        ("C-c C-c" . sbt-do-compile)
        ("C-c C-t" . sbt-do-test)
        ("C-c C-o" . +scala-test-only)
        ("C-c C-r" . sbt-command)
        ("C-c C-x" . +scala-run-main))

  :preface
  (defun +scala-run-main ()
    "Run Scala main class with sbt."
    (interactive)
    (let ((main-class (read-string "Main class: ")))
      (sbt-command (format "runMain %s" main-class))))

  ;; TODO: add function to test this, which extracts the test class from the current file, including support for specs2
  (defun +scala-test-only ()
    "Run specific Scala test."
    (interactive)
    (let ((test-class (read-string "Test class: ")))
      (sbt-command (format "testOnly %s" test-class)))))

;;; Metals LSP configuration
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(scala-ts-mode . ("metals")))

  (defclass eglot-metals (eglot-lsp-server) ()
    :documentation "Metals LSP server for Scala.")

  (cl-defmethod eglot-initialization-options ((_server eglot-metals))
    "Metals initialization options."
    `(:isHttpEnabled t
                     :statusBarProvider "log-message"
                     :compilerOptions (:snippetAutoIndent t
                                                          :overrideDefFormat "unicode")
                     :scalafixConfigPath ".scalafix.conf")))

;;; Dape integration (debug via Metals DAP)
;;
;; Metals exposes DAP through a custom LSP request. We ask eglot to start
;; a debug session, then connect dape to the returned URI.

(defun my/metals-debug-start (no-debug)
  "Request a debug adapter session from Metals via eglot.
If NO-DEBUG is non-nil, run without breakpoints (run mode)."
  (interactive "P")
  (unless (and (fboundp 'eglot-current-server) (eglot-current-server))
    (user-error "Eglot is not active in this buffer"))
  (let* ((server (eglot-current-server))
         (params `(:targets [(:uri ,(concat "file://" (buffer-file-name)))]
                            :noDebug ,(if no-debug t :json-false)
                            :dataKind "scala-main-class"
                            :data (:class "" :arguments [] :jvmOptions []
                                          :environmentVariables [] :shellCommand "")))
         (response (jsonrpc-request server :metals/debugAdapterStart params)))
    (when-let* ((uri (plist-get response :uri)))
      (let* ((parsed (url-generic-parse-url uri))
             (host (url-host parsed))
             (port (url-port parsed)))
        (dape `(metals-attach
                modes (scala-ts-mode)
                host ,host
                port ,port
                :type "scala"
                :request "attach"
                :name "Metals Debug"))))))

(defun +scala-debug ()
  "Start a Metals debug session (respects breakpoints)."
  (interactive)
  (my/metals-debug-start nil))

(defun +scala-run ()
  "Run via Metals without debugging (ignores breakpoints)."
  (interactive)
  (my/metals-debug-start t))

(provide 'dev-scala)
;;; dev-scala.el ends here
