;;; my-dev-ruby.el --- Ruby workflow configuration -*- lexical-binding: t; -*-

;; Commentary:
;;
;;; Code:

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

(defun my/ruby--test-framework (&optional file)
  "Return the Ruby test framework for FILE or the current buffer.
Return `rspec' for RSpec specs, `minitest' for Minitest tests, or nil when
the buffer does not look like a Ruby test file."
  (cond
   ((my/ruby--spec-file-p file) 'rspec)
   ((my/ruby--minitest-file-p file) 'minitest)
   (t nil)))

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

(defun +ruby-rspec-dwim ()
  "Run the current Ruby location explicitly with RSpec."
  (interactive)
  (my/ruby--run-rspec
   (or (my/ruby--rspec-target (line-number-at-pos))
       (read-string "RSpec target: "))))

(defun +ruby-rspec-file ()
  "Run the current Ruby file explicitly with RSpec."
  (interactive)
  (my/ruby--run-rspec
   (or (my/ruby--rspec-target)
       (read-string "RSpec target: "))))

(defun +ruby-minitest-dwim ()
  "Run the current Ruby location explicitly with Minitest."
  (interactive)
  (pcase-let ((`(,file ,test-name)
               (or (my/ruby--minitest-target (my/ruby--minitest-test-name))
                   (list (read-string "Minitest file: ") nil))))
    (my/ruby--run-minitest file test-name)))

(defun +ruby-minitest-file ()
  "Run the current Ruby file explicitly with Minitest."
  (interactive)
  (pcase-let ((`(,file ,test-name)
               (or (my/ruby--minitest-target)
                   (list (read-string "Minitest file: ") nil))))
    (my/ruby--run-minitest file test-name)))

(defun +ruby-test-dwim ()
  "Run the current Ruby test, dispatching between RSpec and Minitest."
  (interactive)
  (pcase (my/ruby--test-framework)
    ('rspec
     (+ruby-rspec-dwim))
    ('minitest
     (+ruby-minitest-dwim))
    (_
     (user-error "Not visiting an RSpec or Minitest test file"))))

(defun +ruby-test-file ()
  "Run the current Ruby test file."
  (interactive)
  (pcase (my/ruby--test-framework)
    ('rspec
     (+ruby-rspec-file))
    ('minitest
     (+ruby-minitest-file))
    (_
     (user-error "Not visiting an RSpec or Minitest test file"))))

;;;; ruby
(use-package ruby-ts-mode
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook
  (ruby-ts-mode . eglot-ensure)
  (ruby-mode . ruby-ts-mode)
  :bind
  (:map ruby-ts-mode-map
        ("C-c a" . +find-alternate-file)
        ("C-c t t" . +ruby-test-dwim)
        ("C-c t o" . +ruby-test-file)
        ("C-c t r" . +ruby-rspec-dwim)
        ("C-c t m" . +ruby-minitest-dwim))
  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil)
  :init
  (setf (alist-get 'ruby-ts-mode my/alternate-file-mappings)
        '((:source ("app" "")
           :test ("spec" "test" "test/unit" "test/system")
           :suffixes ("_spec" "_test"))
          (:source ("lib")
           :test ("spec/lib" "test/lib" "test/unit" "test/system")
           :suffixes ("_spec" "_test")))))

(provide 'my-dev-ruby)
;;; my-dev-ruby.el ends here
