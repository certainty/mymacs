;;; dev-go.el --- Go configuration -*- lexical-binding: t -*-

;;; Code:

;;;; Go Tree-sitter Mode
(use-package go-ts-mode
  :straight (:type built-in)
  :mode (("\\.go\\'" . go-ts-mode))
  :hook (go-ts-mode . eglot-ensure)

  :bind
  (:map go-ts-mode-map
    ("C-c ." . '+go-test-current-test)
    ("C-c t" . '+go-test-current-file)
    ("C-c T" . '+go-test-current-project)
    ("C-c r" . '+go-run)
    ("C-c b" . '+go-build)
    ("C-c c" . 'compile))
  :custom
  (go-ts-mode-indent-offset 2)

  :config
  (add-hook 'go-ts-mode-hook
    (lambda ()
      (setq-local my/external-formatter #'gofmt
        my/format-policy 'external))))

;;;; Go Mode utilities
(use-package go-mode
  :commands (gofmt
              go-import-add
              go-remove-unused-imports
              go-goto-imports))

;;;; Go testing functions
(defun +go-test-current-test ()
  "Run the test at point."
  (interactive)
  (let ((test-name (which-function)))
    (if test-name
      (compile (format "go test -v -run %s" test-name))
      (message "No test function found at point"))))

(defun +go-test-current-file ()
  "Run all tests in the current file."
  (interactive)
  (compile "go test -v ."))

(defun +go-test-current-project ()
  "Run all tests in the current project."
  (interactive)
  (compile "go test -v ./..."))

(defun +go-test-current-benchmark ()
  "Run benchmarks in the current package."
  (interactive)
  (compile "go test -v -bench=. -benchmem"))

(defun +go-test-current-coverage ()
  "Run tests with coverage in the current package."
  (interactive)
  (compile "go test -v -cover ./..."))

(defun +go-run ()
  "Run the current Go file or main package."
  (interactive)
  (let ((file (buffer-file-name)))
    (if (string-match "_test\\.go$" file)
      (go-test-current-file)
      (compile (format "go run %s" file)))))

(defun +go-build ()
  "Build the current package."
  (interactive)
  (compile "go build"))

(provide 'dev-go)
;;; dev-go.el ends here
