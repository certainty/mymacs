;;; dev-ruby.el --- Ruby configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Ruby development with tree-sitter, eglot, and ERB support

;;; Code:

;;;; Ruby Mode
(use-package ruby-ts-mode
  :straight (:type built-in)
  :mode (("\\.rb\\'" . ruby-ts-mode)
          ("Rakefile\\'" . ruby-ts-mode)
          ("Gemfile\\'" . ruby-ts-mode)
          ("\\.rake\\'" . ruby-ts-mode)
          ("\\.gemspec\\'" . ruby-ts-mode)
          ("Guardfile\\'" . ruby-ts-mode)
          ("\\.ru\\'" . ruby-ts-mode))
  :hook (ruby-ts-mode . eglot-ensure)
  :general
  (local-leader-def
    :keymaps 'ruby-ts-mode-map
    "t" '(:ignore t :which-key "test")
    "ta" 'ruby-test-run-all
    "tt" 'ruby-test-run
    "ts" 'ruby-test-run-at-point)
  :custom
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
