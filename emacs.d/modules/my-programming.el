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
                '(ada-ts-mode "alr" "exec" "ada_language_server")))

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
               '(scala "https://github.com/tree-sitter/tree-sitter-scala" "v0.22.5")))

;;;; diagnostics
(use-package flymake
  :bind
  (:map my/leader-map
        ("D" . flymake-show-project-diagnostics))
  (:map goto-map
        ("n e" . flymake-goto-next-error)
        ("p e" . flymake-goto-prev-error))
  (:map flymake-mode-map
        ("M-n" . flymake-goto-next-error)
        ("M-p" . flymake-goto-prev-error))
  :custom
  (flymake-indicator-type 'margins)
  (flymake-margin-indicator-position 'left-margin)
  (flymake-mode-line-lighter ""))

;;;; ruby
(require 'my-dev-ruby)

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
(require 'my-dev-scala)

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
  :hook
  (ada-ts-mode . eglot-ensure)
  (ada-ts-mode . my-project-compilation-search-path))

(use-package gpr-ts-mode
  :ensure t
  :pin "melpa"
  :mode ("\\.gpr\\'" "\\.cgpr\\'")
  :hook (gpr-ts-mode . eglot-ensure)
  :config
  (require 'gpr-ts-lspclient-eglot))

;;;; erlang
(use-package erlang-ts
  :ensure t
  :pin "melpa"
  :mode (("\\.erl\\'" . erlang-ts-mode)
         ("\\.app\\.src\\'" . erlang-ts-mode)
         ("\\.escript\\'" . erlang-ts-mode)
         ("\\.hrl\\'" . erlang-ts-mode)
         ("\\.xrl\\'" . erlang-ts-mode)
         ("\\.yrl\\'" . erlang-ts-mode))
  :hook (erlang-ts-mode . eglot-ensure))

;;;; elixir
(use-package elixir-ts-mode
  :mode ("\\.elixir\\'" "\\.ex\\'" "\\.exs\\'" "mix\\.lock\\'")
  :hook (elixir-ts-mode . eglot-ensure)
  :custom
  (elixir-ts-indent-offset 2))

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

;;;; mise
(use-package mise
  :ensure t
  :demand t
  :pin "melpa"
  :config
  (global-mise-mode 1))


(provide 'my-programming)
;;; my-programming.el ends here
