;;; dev-ruby.el --- Ruby development -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Ruby support via ruby-ts-mode (built-in) and ruby-lsp (eglot).
;; Formatting is handled by rufo via reformatter.
;; Test/compile targets are provided by projection-multi-compile.
;;
;;; Code:

;;; Ruby tree-sitter mode
(use-package ruby-ts-mode
  :straight (:type built-in)
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook ((ruby-ts-mode . eglot-ensure)
         (ruby-ts-mode . (lambda () (setq-local my/external-formatter #'+rufo-buffer))))
  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil)
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(ruby-ts-mode . ("ruby-lsp")))))

;;; Formatter: rufo
(eval-and-compile
  (defun +rufo-success-p (retcode)
    "Check if rufo succeeded (0 or 3)."
    (member retcode '(0 3))))

(reformatter-define +rufo
  :program "rufo"
  :lighter " rufo"
  :exit-code-success-p +rufo-success-p)

(provide 'dev-ruby)
;;; dev-ruby.el ends here
