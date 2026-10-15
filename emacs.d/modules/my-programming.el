;;; my-programming.el --- Programming and language configuration -*- lexical-binding: t; -*-

;;; Programming
(use-package emacs
  :hook (prog-mode . display-line-numbers-mode)
  :custom
  (eldoc-help-at-pt t))

(use-package xref
  :custom
  (xref-show-definitions-function #'xref-show-definitions-buffer))

;;;; compilation mode colors
(use-package compile
  :custom
  (compilation-scroll-output t)
  (compilation-max-output-line-length nil))

(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package eldoc
  :custom
  (eldoc-idle-delay 1000000)
  (eldoc-echo-area-use-multiline-p t)
  :bind
  (:map prog-mode-map
        ("C-c l h" . eldoc))
  :config
  (defun my/eldoc-display-manually-only (docs interactive)
    (when interactive
      (or (eldoc-display-in-echo-area docs interactive)
          (eldoc-display-in-buffer docs interactive))))
  ;(setq eldoc-display-functions '(my/eldoc-display-manually-only))
  )

(use-package eglot
  :hook (markdown-ts-mode . eglot-ensure)
  :bind
  (:map eglot-mode-map
        ("C-c l" . my/eglot-prefix-map))
  (:prefix-map
   my/eglot-prefix-map
   :prefix "C-c l"
   ("a" . eglot-code-actions)
   ("r" . eglot-rename)
   ("f" . eglot-format-buffer)
   ("F" . eglot-format))

  :custom
  (eglot-documentation-renderer 'markdown-ts-view-mode)
  (eglot-code-action-indications nil)
  (read-process-output-max (* 1024 1024))
  :config
  (add-to-list 'eglot-server-programs
               '(markdown-ts-mode "zk" "lsp"))
  (add-to-list 'eglot-server-programs
               '((ruby-mode ruby-ts-mode)
                 "ruby-lsp"))
  (add-to-list 'eglot-server-programs
               '((elixir-mode elixir-ts-mode heex-ts-mode)
                 "expert" "--stdio"))
  (add-to-list 'eglot-server-programs
               '(scala-ts-mode
                 "metals"
                 :initializationOptions
                 (:isHttpEnabled t)))
  (add-to-list 'eglot-server-programs
               '(ada-ts-mode "alr" "exec" "ada_language_server"))
  (add-to-list 'eglot-server-programs
               '(swift-ts-mode "sourcekit-lsp")))

;;; copilot / ai
(use-package copilot
  :ensure t
  :pin "melpa"
  :bind
  (:map copilot-completion-map
        ("M-y" . copilot-accept-completion)
        ("C-M-y" . copilot-accept-completion-by-word)
        ("M-n" . copilot-next-completion)
        ("M-p" . copilot-previous-completion)))

;;; snippets
;; these also act as a provider for eglot
(declare-function yas-reload-all "yasnippet")

(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all))

(use-package treesit
  :custom
  (treesit-auto-install-grammar 'ask)
  (treesit-enabled-modes t)
  (treesit-font-lock-level 4)
  :config
  
  (add-to-list 'treesit-language-source-alist
               '(scala  "https://github.com/tree-sitter/tree-sitter-scala" "v0.22.5"))
  (add-to-list 'treesit-language-source-alist
               '(swift  "https://github.com/alex-pinkus/tree-sitter-swift" "0.7.3-with-generated-files")))

;;;; diagnostics
(use-package flymake
  :bind
  (:map my/leader-map
        ("D" . flymake-show-project-diagnostics))
  (:map flymake-mode-map
        ("M-n" . flymake-goto-next-error)
        ("M-p" . flymake-goto-prev-error))
  :custom
  (flymake-indicator-type 'margins)
  (flymake-margin-indicator-position 'left-margin)
  (flymake-mode-line-lighter ""))

(use-package apheleia
  :ensure t
  :pin "melpa"
  :config
  (setf (alist-get 'swift-format apheleia-formatters)
        '("swift-format" "--assume-filename" filepath "-"))
  (setf (alist-get 'swift-ts-mode apheleia-mode-alist) '(swift-format)))

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
           :suffixes ("_spec" "_test"))))

  :config
  (defvar-local my/ruby-project-test-runner nil
    "Project-specific Ruby test runner, or nil to infer it from the file.")

  (defun my/ruby--valid-test-runner-p (value)
    "Return non-nil when VALUE is a supported Ruby test runner."
    (memq value '(rspec minitest)))

  (put 'my/ruby-project-test-runner 'safe-local-variable
       #'my/ruby--valid-test-runner-p)

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
Use the project-specific runner when set; otherwise infer it from FILE.
Return `rspec', `minitest', or nil when no runner can be determined."
    (or my/ruby-project-test-runner
        (cond
         ((my/ruby--spec-file-p file) 'rspec)
         ((my/ruby--minitest-file-p file) 'minitest)
         (t nil))))

  (defun my/ruby-set-project-test-runner (runner)
    "Set the current project's Ruby test RUNNER in its .dir-locals.el."
    (interactive
     (list (intern (completing-read "Ruby test runner: " '("minitest" "rspec")
                                    nil t))))
    (unless (my/ruby--valid-test-runner-p runner)
      (user-error "Unsupported Ruby test runner: %S" runner))
    (let ((root (my/ruby--project-root)))
      (unless root
        (user-error "The current buffer is not in a project"))
      (add-dir-local-variable 'ruby-ts-mode 'my/ruby-project-test-runner runner
                              (expand-file-name ".dir-locals.el" root))
      ;; Directory locals are normally applied when buffers are visited.  Update
      ;; already-open Ruby buffers too, so the choice takes effect immediately.
      (dolist (buffer (buffer-list))
        (with-current-buffer buffer
          (when (and buffer-file-name
                     (file-in-directory-p buffer-file-name
                                          (file-name-as-directory root))
                     (derived-mode-p 'ruby-ts-mode 'ruby-mode))
            (setq-local my/ruby-project-test-runner runner))))
      (setq-local my/ruby-project-test-runner runner)
      (message "Ruby test runner for %s set to %s"
               (abbreviate-file-name root) runner)))

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
       (user-error "Not visiting an RSpec or Minitest test file")))))

;;;; go lang
(use-package go-ts-mode
  :mode "\\.go\\'"
  :hook (go-ts-mode . eglot-ensure)
  :init
  (setq-default go-ts-mode-indent-offset 4))

;;;; templates
(use-package mmm-mode
  :ensure t
  :custom
  (mmm-global-mode 'maybe)
  :init
  (require 'mmm-auto)
  :config
  (mmm-add-classes
   '((gotmpl
      :submode go-ts-mode
      :face mmm-code-submode-face
      :front "{{-?"
      :back "-?}}"
      :end-not-begin t)))
  (mmm-add-mode-ext-class 'yaml-ts-mode nil 'gotmpl)
  (mmm-add-mode-ext-class nil "\\.gotmpl\\'" 'gotmpl))

;;;; scala
(use-package scala-ts-mode
  :ensure t
  :pin "melpa"
  :mode ("\\.scala\\'" "\\.sc\\'" "\\.sbt\\'")
  :hook ((scala-ts-mode . my/scala-eglot-setup)
         (scala-ts-mode . eglot-ensure))
  :bind
  (:map scala-ts-mode-map
        ("C-c a" . +find-alternate-file)
        ("C-c C-t" . +scala-test-only))
  :preface
  (defun my/scala-eglot-setup ()
    "Disable Metals on-type formatting in Scala buffers."
    (setq-local eglot-ignored-server-capabilities
                (cons :documentOnTypeFormattingProvider
                      eglot-ignored-server-capabilities)))
  :init
  (setf (alist-get 'scala-ts-mode my/alternate-file-mappings)
        '((:source ("src/main/scala")
           :test ("src/test/scala" "src/it/scala")
           :suffixes ("Spec" "Suite" "Test"))))


  :config
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
      (compile (format "sbt %s"
                       (shell-quote-argument (format "testOnly %s" target) t)))))


  (defun +scala-test-only ()
    "Run the current Scala test or prompt for a class name."
    (interactive)
    (let ((test-class (or (and buffer-file-name (my/scala--spec-target))
                          (read-string "Test class: "))))
      (my/scala--run-test-target test-class))))

;;;; ada
(use-package ada-ts-mode
  :ensure t
  :pin "melpa"
  :preface
  (defun my-project-compilation-search-path ()
    (when-let* ((project (project-current))
                (root (project-root project))
                (src (expand-file-name "src" root)))
      (setq-local compilation-search-extra-path (list src))))

  (defun my-setup-ada ()
    (my-project-compilation-search-path)
    (setq-local ada-ts-mode-indent-offset 3)
    (setq-local indent-tabs-mode nil))

  :hook
  (ada-ts-mode . eglot-ensure)
  (ada-ts-mode . my-setup-ada))

(use-package gpr-ts-mode
  :ensure t
  :pin "melpa"
  :mode ("\\.gpr\\'" "\\.cgpr\\'")
  :hook (gpr-ts-mode . eglot-ensure)
  :config
  (require 'gpr-ts-lspclient-eglot))

;;;; erlang
;; (use-package erlang-ts
;;   :ensure t
;;   :pin "melpa"
;;   :mode (("\\.erl\\'" . erlang-ts-mode)
;;          ("\\.app\\.src\\'" . erlang-ts-mode)
;;          ("\\.escript\\'" . erlang-ts-mode)
;;          ("\\.hrl\\'" . erlang-ts-mode)
;;          ("\\.xrl\\'" . erlang-ts-mode)
;;          ("\\.yrl\\'" . erlang-ts-mode))
;;   :hook (erlang-ts-mode . eglot-ensure))

(use-package emacs
  :mode (("rebar\\.conf" . erlang-mode)
         ("\\.erl\\'" . erlang-mode)
         ("\\.app\\.src\\'" . erlang-mode)
         ("\\.hrl\\'" . erlang-mode)
         ("\\.xrl\\'" . erlang-mode)
         ("\\.yrl\\'" . erlang-mode))
  :hook (erlang-mode .  eglot-ensure))



;;;; elixir
(use-package elixir-ts-mode
  :mode ("\\.elixir\\'" "\\.ex\\'" "\\.exs\\'" "mix\\.lock\\'")
  :hook (elixir-ts-mode . eglot-ensure)
  :custom
  (elixir-ts-indent-offset 2))

;;;; swift
(use-package swift-ts-mode
  :ensure t
  :pin "melpa"
  :mode "\\.swift\\'"
  :interpreter "swift"

  :hook
  (swift-ts-mode . eglot-ensure)
  (swift-ts-mode . apheleia-mode)
  :bind
  (:map swift-ts-mode-map
        ("C-c b" . my/swift-build)
        ("C-c t" . my/swift-test)
        ("C-c x" . my/swift-run)
        ("C-c f" . my/swift-format-buffer))
  :config
  (defun my/swift-build () "Run Swift Package Manager build." (interactive) (compile "swift build"))
  (defun my/swift-test () "Run Swift Package Manager tests." (interactive) (compile "swift test"))
  (defun my/swift-run () "Run the Swift Package Manager executable." (interactive) (compile "swift run"))
  (defun my/swift-format-buffer ()
    "Format the current Swift buffer with swift-format."
    (interactive)
    (when (derived-mode-p 'swift-ts-mode)
      (call-process-region (point-min) (point-max) "swift-format" t t nil "--assume-filename" (or buffer-file-name "main.swift"))
      (indent-region (point-min) (point-max)))))

(use-package heex-ts-mode
  :mode "\\.[hl]?eex\\'"
  :hook (heex-ts-mode . eglot-ensure))

;;;; yaml
(use-package yaml-ts-mode
  :mode ("\\.ya?ml\\'" "\\.yaml\\.gotmpl\\'" "\\.yaml\\.erb\\'" "\\.yml\\.gotmpl\\'" "\\.yml\\.erb\\'"))

;;;; json
(use-package json-ts-mode
  :mode ("\\.json\\'" "\\.json\\.gotmpl\\'" "\\.json\\.erb\\'"))

;;;; web
(use-package html-ts-mode
  :mode ("\\.html\\'" "\\.html\\.erb\\'" "\\.html\\.gotmpl\\'"))

(use-package css-mode
  :mode ("\\.css\\'" "\\.css\\.erb\\'" "\\.css\\.gotmpl\\'"))

(use-package adoc-mode
  :ensure t
  :pin "nongnu"
  :hook (adoc-mode . flymake-mode))


(provide 'my-programming)
;;; my-programming.el ends here
