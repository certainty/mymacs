;;; dev-ruby.el --- Ruby configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Ruby development with tree-sitter, eglot, and ERB support

;;; Code:

;;;; Ruby Mode

(defun rufo-success-p (retcode)
  (member retcode '(0 3)))

(reformatter-define rufo
  :program "rufo"
  :lighter " Rufo"
  :exit-code-success-p rufo-success-p)

(add-hook 'ruby-ts-mode-hook
  (lambda ()
    (setq-local my/external-formatter #'rufo-buffer
      my/format-policy 'dwim)))

(use-package ruby-ts-mode
  :straight (:type built-in)
  :mode (("\\.rb\\'" . ruby-ts-mode)
          ("Rakefile\\'" . ruby-ts-mode)
          ("Gemfile\\'" . ruby-ts-mode)
          ("\\.rake\\'" . ruby-ts-mode)
          ("\\.gemspec\\'" . ruby-ts-mode)
          ("Guardfile\\'" . ruby-ts-mode)
          ("\\.ru\\'" . ruby-ts-mode))
  :hook
  (ruby-ts-mode . eglot-ensure)
  (ruby-ts-mode . subword-mode)

  :bind
  (:map ruby-ts-mode-map
    ("C-c ." . ruby-test-run-at-point)
    ("C-c t" . ruby-test-run)
    ("C-c T" . ruby-test-run-all)
    ("C-c c" . compile))

  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil))

;;;; Ruby Test Runner
(defun ruby-test-run ()
  "Run current test file."
  (interactive)
  (let ((file (buffer-file-name)))
    (compile (format "ruby -Itest %s" file))))

(defun ruby-test-run-at-point ()
  "Run test at point."
  (interactive)
  (let ((file (buffer-file-name))
         (line (line-number-at-pos)))
    (compile (format "ruby -Itest %s --line %d" file line))))

(defun ruby-test-run-all ()
  "Run all tests in project."
  (interactive)
  (compile "rake test"))

;;;; Web-mode for ERB files
(with-eval-after-load 'web-mode
  (add-to-list 'web-mode-comment-formats '("erb" . "<%#"))
  (setq web-mode-enable-engine-detection t)
  (setopt web-mode-engines-alist '(("erb" . "\\.erb\\'"))))

(provide 'dev-ruby)
;;; dev-ruby.el ends here
