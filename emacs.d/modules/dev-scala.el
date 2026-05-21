;;; dev-scala.el --- Scala development -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Scala support via scala-ts-mode and Metals (eglot).  Uses sbt-mode
;; for REPL interaction.  Test/compile targets are provided by
;; projection-multi-compile (detects build.sbt).
;;
;;; Code:

;;; Scala test helpers
(declare-function project-current "project")
(declare-function project-root "project")
(declare-function eglot-current-server "eglot")
(declare-function sbt-command "sbt-mode" (command))
(defvar eglot-server-programs)

(defun my/scala--project-root ()
  "Return the current project root for Scala commands."
  (when-let* ((project (project-current nil)))
    (project-root project)))

(defun my/scala--top-level-name ()
  "Return the current Scala spec class name in the buffer."
  (save-excursion
    (goto-char (point-min))
    (or (when (re-search-forward
                "^\\s-*\\(?:case\\s-+\\)?\\(?:class\\|object\\|trait\\)\\s-+\\([[:word:]_][[:word:]_0-9]*\\)\\s-+extends\\s-+.*\\<Specification\\>"
                nil t)
          (match-string-no-properties 1))
      (when (re-search-forward
              "^\\s-*\\(?:case\\s-+\\)?\\(?:class\\|object\\|trait\\)\\s-+\\([[:word:]_][[:word:]_0-9]*\\)"
              nil t)
        (match-string-no-properties 1)))))

(defun my/scala--package-from-path (&optional file)
  "Infer a Scala package from FILE relative to the project root."
  (let* ((path (or file buffer-file-name))
          (root (and path (my/scala--project-root)))
          (rel (and root (file-relative-name path root))))
    (when (and rel
            (string-match
              "\\`src/\\(?:test\\|it\\)/scala/\\(.+\\)/[^/]+\\.scala\\'" rel))
      (replace-regexp-in-string "/" "." (match-string 1 rel)))))

(defun my/scala--spec-target ()
  "Return the fully qualified test target for the current Scala file."
  (let* ((package (or (my/scala--package-from-path)
                    (save-excursion
                      (goto-char (point-min))
                      (when (re-search-forward
                              "^\\s-*package\\s-+\\([[:word:]_.]+\\)"
                              nil t)
                        (match-string-no-properties 1)))))
          (name (or (my/scala--top-level-name)
                  (and buffer-file-name (file-name-base buffer-file-name)))))
    (if package
      (format "%s.%s" package name)
      name)))

(defun my/scala--run-test-target (target)
  "Run sbt testOnly for TARGET through `compile'."
  (let ((default-directory (or (my/scala--project-root) default-directory)))
    (compile (format "sbt testOnly %s" (shell-quote-argument target)))))

(defun +scala-run-main ()
  "Run a Scala main class with sbt."
  (interactive)
  (let ((main-class (read-string "Main class: ")))
    (sbt-command (format "runMain %s" main-class))))

(defun +scala-test-only ()
  "Run the current Scala test or prompt for a class name."
  (interactive)
  (let ((test-class (or (and buffer-file-name (my/scala--spec-target))
                      (read-string "Test class: "))))
    (my/scala--run-test-target test-class)))

;;; Scala tree-sitter mode
(use-package scala-ts-mode
  :straight t
  :mode ("\\.scala\\'" "\\.sc\\'" "\\.sbt\\'")
  :hook (scala-ts-mode . eglot-ensure)
  :custom
  (scala-ts-mode-indent-offset 2)
  :config
  (keymap-set scala-ts-mode-map "C-c C-k" #'sbt-do-clean)
  (keymap-set scala-ts-mode-map "C-c C-c" #'sbt-do-compile)
  (keymap-set scala-ts-mode-map "C-c C-t" #'sbt-do-test)
  (keymap-set scala-ts-mode-map "C-c C-o" #'+scala-test-only)
  (keymap-set scala-ts-mode-map "C-c C-r" #'sbt-command)
  (keymap-set scala-ts-mode-map "C-c C-x" #'+scala-run-main))

;;; SBT (build tool / REPL)
(use-package sbt-mode
  :straight t
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
    minibuffer-local-completion-map))

;;; Metals LSP configuration
(defun my/scala-metals-contact ()
  "Build the Eglot contact spec for Metals."
  (append
    (list my/scala-metals-command)
    (mapcar (lambda (arg) (format "-J%s" arg)) my/scala-metals-java-options)
    my/scala-metals-server-arguments
    (list :initializationOptions my/scala-metals-initialization-options)))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(scala-ts-mode . ,(my/scala-metals-contact))))

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
