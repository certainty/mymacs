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
  (compilation-scroll-output 'first-error)
  (compilation-max-output-line-length nil)
  :config
  (add-to-list 'compilation-error-regexp-alist-alist
               '(my/ruby-rspec
                 "^ *# \\([^:\n]+\\):\\([0-9]+\\):in " 1 2))
  (add-to-list 'compilation-error-regexp-alist 'my/ruby-rspec)

  (defun my/compilation-add-project-root-to-search-path (process)
    "Add the current project root to compilation source-file lookup paths."
    (when-let* ((buffer (process-buffer process)))
      (with-current-buffer buffer
        (when-let* ((project (project-current nil)))
          (let ((root (project-root project)))
            (setq-local compilation-search-path
                        (cons root
                              (delete root compilation-search-path))))))))
  (add-hook 'compilation-start-hook
            #'my/compilation-add-project-root-to-search-path))

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
          (eldoc-display-in-buffer docs interactive)))))

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
  ;; GPR files get their own server (ALS handles one language per process),
  ;; but also through `alr exec' so the alire environment is set up.
  (add-to-list 'eglot-server-programs
               '(gpr-ts-mode "alr" "exec" "ada_language_server" "--language-gpr"))
  (add-to-list 'eglot-server-programs
               '(swift-ts-mode "sourcekit-lsp")))

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
(use-package rspec-mode
  :ensure t
  :pin "melpa"
  :commands (rspec-mode rspec-verifiable-mode rspec-enable-appropriate-mode)
  :bind
  (:map rspec-verifiable-mode-keymap
        ("v" . rspec-verify)
        ("s" . rspec-verify-single)
        ("a" . rspec-verify-all)
        ("r" . rspec-rerun)
        ("t" . rspec-toggle-spec-and-target))
  :custom
  (rspec-key-command-prefix (kbd "C-c t"))
  :init
  (my/push-display-buffer-rule
   "^\\*rspec-compilation.*\\*"
   (my/bottom-window-config 'rspec-compilation-mode))
  :config
  (defun my/rspec-bundle-p ()
    "Return non-nil when Bundler is enabled and an ancestor has a Gemfile."
    (and rspec-use-bundler-when-possible
         (locate-dominating-file default-directory "Gemfile")))
  (advice-add 'rspec-bundle-p :override #'my/rspec-bundle-p))

(use-package minitest
  :ensure t
  :pin "melpa"
  :commands (minitest-mode minitest-enable-appropriate-mode)
  :bind
  (:map minitest-mode-map
        ("v" . minitest-verify)
        ("s" . minitest-verify-single)
        ("a" . minitest-verify-all)
        ("r" . minitest-rerun)
        ("t" . minitest-toggle-test-and-target))
  :custom
  (minitest-keymap-prefix (kbd "C-c t"))
  :init
  (my/push-display-buffer-rule
   "^\\*Minitest.*\\*"
   (my/bottom-window-config 'minitest-compilation-mode)))

(use-package ruby-ts-mode
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook
  (ruby-ts-mode . eglot-ensure)
  (ruby-mode . ruby-ts-mode)
  :bind
  (:map ruby-ts-mode-map
        ("C-c a" . +find-alternate-file))
  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil)

  :init
  (defun my/ruby-enable-minitest-mode ()
    "Enable Minitest mode for test files without the RSpec keymap."
    (when (and buffer-file-name
               (string-match-p "\\(?:_\\|-\\)test\\.rb\\'"
                               buffer-file-name))
      (when (bound-and-true-p rspec-verifiable-mode)
        (rspec-verifiable-mode -1))
      (minitest-mode 1)))

  ;; Minitest's autoloads don't include `ruby-ts-mode'.  RSpec also enables
  ;; its project keymap on every Ruby file, so disable that map for Minitest
  ;; test files before enabling Minitest's map.
  (dolist (hook '(ruby-mode-hook enh-ruby-mode-hook))
    (remove-hook hook #'rspec-enable-appropriate-mode)
    (remove-hook hook #'minitest-enable-appropriate-mode))
  (add-hook 'ruby-ts-mode-hook #'my/ruby-enable-minitest-mode t)

  (setf (alist-get 'ruby-ts-mode my/alternate-file-mappings)
        '((:source ("app" "")
           :test ("spec" "test" "test/unit" "test/system")
           :suffixes ("_spec" "_test"))
          (:source ("lib")
           :test ("spec/lib" "test/lib" "test/unit" "test/system")
           :suffixes ("_spec" "_test")))))

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

  (defun my/setup-ada ()
    (my-project-compilation-search-path)
    (setq-local ada-ts-mode-indent-offset 3)
    (setq-local tab-width 3)
    (setq-local indent-tabs-mode nil))

  :hook
  (ada-ts-mode . eglot-ensure)
  (ada-ts-mode . my/setup-ada))

(use-package gpr-ts-mode
  :ensure t
  :pin "melpa"
  :mode ("\\.gpr\\'" "\\.cgpr\\'")
  ;; eglot-server-programs has a gpr-ts-mode entry (see above) that starts
  ;; the server via `alr exec'; don't load gpr-ts-lspclient-eglot, which
  ;; would register a second, alire-unaware `ada_language_server' entry.
  :hook (gpr-ts-mode . eglot-ensure))

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

;;; Lisp in general
(use-package zoutline
  :ensure t
  :pin "melpa")

(use-package hydra
  :ensure t
  :pin "melpa")

(use-package lispy
  :hook
  (lisp-mode . lispy-mode)
  (emacs-lisp-mode . lispy-mode)
  :ensure t
  :pin "melpa")

;;; Common Lisp
(use-package sly
  :ensure t
  :pin "melpa"
  :hook
  (sly-mode . my/sly-eldoc-idle-delay)
  :custom
  (inferior-lisp-program "sbcl")
  (sly-complete-symbol-function #'sly-flex-completions)
  (sly-lisp-implementation 'sbcl)
  (sly-lisp-implementations
   '((sbcl ("sbcl") :coding-system utf-8-unix)
     (ros ("ros" "-Q" "run") :coding-system utf-8-unix)))
  (sly-contribs '(sly-fancy sly-stickers sly-scratch sly-mrepl sly-autodoc sly-trace-dialog))
  (sly-common-lisp-style 'modern)

  :preface
  (defun my/sly-eldoc-idle-delay ()
    "Restore automatic eldoc display in sly buffers.
`sly-autodoc-mode' shows arglists through `eldoc-mode', whose
global `eldoc-idle-delay' disables automatic display; use a small
buffer-local value instead."
    (setq-local eldoc-idle-delay 0.5))

  :init
  (add-to-list 'auto-mode-alist '("\\.ros\\'" . lisp-mode)))

(use-package sly-asdf
  :ensure t
  :pin "melpa"
  :after sly
  :init
  (add-to-list 'sly-contribs 'sly-asdf 'append))

(use-package sly-quicklisp
  :ensure t
  :pin "melpa"
  :hook sly-mode)

;; (use-package sly-repl-ansi-color
;;   :ensure t
;;   :after sly
;;   :pin "melpa"
;;   :config
;;   (add-to-list 'sly-contribs 'sly-repl-ansi-color))

(use-package sly-overlay
  :ensure t
  :pin "melpa")


(provide 'my-programming)
;;; my-programming.el ends here
