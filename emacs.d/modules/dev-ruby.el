;;; dev-ruby.el --- Ruby development -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Ruby support via ruby-ts-mode (built-in) and ruby-lsp (eglot).
;; Formatting is handled by rufo via reformatter.
;; Test/compile targets are provided by projection-multi-compile.
;;
;;; Code:

;;; Ruby test helpers
(declare-function project-current "project")
(declare-function project-root "project")

(defun my/ruby--project-root ()
  "Return the current project root for Ruby commands."
  (when-let* ((project (project-current nil)))
    (project-root project)))

(defun my/ruby--bundle-exec-prefix ()
  "Return \"bundle exec\" when the project has a Gemfile."
  (let ((root (or (my/ruby--project-root) default-directory)))
    (if (file-exists-p (expand-file-name "Gemfile" root))
        "bundle exec"
      "")))

(defun my/ruby--spec-file-p (&optional file)
  "Return non-nil when FILE looks like an RSpec spec file."
  (let ((path (or file buffer-file-name)))
    (and path
         (string-match-p "/spec/.*_spec\\.rb\\'" path))))

(defun my/ruby--minitest-file-p (&optional file)
  "Return non-nil when FILE looks like a Minitest file."
  (let ((path (or file buffer-file-name)))
    (and path
         (string-match-p "/test/.*_test\\.rb\\'" path))))

(defun my/ruby--rspec-target (&optional line)
  "Return the RSpec target for the current buffer and optional LINE."
  (let ((file (and buffer-file-name
                   (file-relative-name buffer-file-name
                                       (or (my/ruby--project-root)
                                           default-directory)))))
    (cond
     ((not file) nil)
     ((my/ruby--spec-file-p file)
      (if line
          (format "%s:%d" file line)
        file))
     (t file))))

(defun my/ruby--minitest-test-name ()
  "Return the nearest Minitest test method name before point."
  (save-excursion
    (when (re-search-backward
           "^\\s-*def\\s-+\\(test_[[:word:]_]+\\)\\_>"
           nil t)
      (match-string-no-properties 1))))

(defun my/ruby--minitest-target (&optional test-name)
  "Return the Minitest FILE and optional TEST-NAME for the current buffer."
  (let ((file (and buffer-file-name
                   (file-relative-name buffer-file-name
                                       (or (my/ruby--project-root)
                                           default-directory)))))
    (cond
     ((not file) nil)
     ((my/ruby--minitest-file-p file)
      (list file test-name))
     (t (list file nil)))))

(defun my/ruby--run-rspec (target)
  "Run RSpec TARGET from the current project root."
  (let ((default-directory (or (my/ruby--project-root) default-directory)))
    (compile (format "%s rspec %s"
                     (let ((prefix (my/ruby--bundle-exec-prefix)))
                       (if (string= prefix "") "" (concat prefix " ")))
                     (shell-quote-argument target)))))

(defun my/ruby--run-minitest (file &optional test-name)
  "Run Minitest FILE and optional TEST-NAME from the current project root."
  (let ((default-directory (or (my/ruby--project-root) default-directory))
        (prefix (my/ruby--bundle-exec-prefix)))
    (compile
     (concat (if (string= prefix "") "" (concat prefix " "))
             "ruby -Ilib:test "
             (shell-quote-argument file)
             (when test-name
               (concat " -n "
                       (shell-quote-argument (format "/%s/" test-name))))))))

(defun +ruby-test-dwim ()
  "Run the current Ruby test, dispatching between RSpec and Minitest."
  (interactive)
  (cond
   ((my/ruby--spec-file-p)
    (my/ruby--run-rspec
     (or (my/ruby--rspec-target (line-number-at-pos))
         (read-string "RSpec target: "))))
   ((my/ruby--minitest-file-p)
    (pcase-let ((`(,file ,test-name)
                 (or (my/ruby--minitest-target (my/ruby--minitest-test-name))
                     (list (read-string "Minitest file: ") nil))))
      (my/ruby--run-minitest file test-name)))
   (buffer-file-name
    (my/ruby--run-rspec (read-string "Ruby test target: ")))
   (t
    (user-error "Not visiting a Ruby file"))))

(defun +ruby-test-file ()
  "Run the current Ruby test file."
  (interactive)
  (cond
   ((my/ruby--spec-file-p)
    (my/ruby--run-rspec
     (or (my/ruby--rspec-target)
         (read-string "RSpec target: "))))
   ((my/ruby--minitest-file-p)
    (pcase-let ((`(,file ,test-name)
                 (or (my/ruby--minitest-target)
                     (list (read-string "Minitest file: ") nil))))
      (my/ruby--run-minitest file test-name)))
   (buffer-file-name
    (my/ruby--run-rspec (read-string "Ruby test target: ")))
   (t
    (user-error "Not visiting a Ruby file"))))

;;; Ruby tree-sitter mode
(use-package ruby-ts-mode
  :straight (:type built-in)
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook ((ruby-ts-mode . eglot-ensure)
         (ruby-ts-mode . (lambda () (setq-local my/external-formatter #'+rufo-buffer))))
  :bind
  (:map ruby-ts-mode-map
        ("C-c C-t" . +ruby-test-dwim)
        ("C-c C-o" . +ruby-test-file))
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
