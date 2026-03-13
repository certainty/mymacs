;;; dev-elixir.el --- Elixir configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Elixir and HEEx development with tree-sitter and Eglot.

;;; Code:

(defun my/elixir-project-root ()
  "Return the current Elixir project root, or nil if none was found."
  (when-let* ((file (buffer-file-name)))
    (locate-dominating-file file "mix.exs")))

(defun my/elixir--compile (command)
  "Run COMMAND from the nearest Mix project root."
  (let ((default-directory (or (my/elixir-project-root) default-directory)))
    (compile command)))

(defun +elixir-test-project ()
  "Run the full Mix test suite for the current project."
  (interactive)
  (my/elixir--compile "mix test"))

(defun +elixir-test-file ()
  "Run Mix tests for the current file."
  (interactive)
  (unless-let* ((file (buffer-file-name))
                (root (my/elixir-project-root)))
    (user-error "Current buffer is not inside a Mix project"))
  (my/elixir--compile
   (format "mix test %s"
           (shell-quote-argument
            (file-relative-name file root)))))

(defun +elixir-test-at-point ()
  "Run the Mix test nearest point."
  (interactive)
  (unless-let* ((file (buffer-file-name))
                (root (my/elixir-project-root)))
    (user-error "Current buffer is not inside a Mix project"))
  (my/elixir--compile
   (format "mix test %s:%d"
           (shell-quote-argument
            (file-relative-name file root))
           (line-number-at-pos))))

(defun my/elixir-mode-setup ()
  "Configure shared Elixir editing defaults."
  (setq-local compile-command "mix test")
  (setq-local my/format-policy 'eglot))

(use-package elixir-ts-mode
  :straight (:type built-in)
  :mode (("\\.ex\\'" . elixir-ts-mode)
          ("\\.exs\\'" . elixir-ts-mode))
  :hook ((elixir-ts-mode . eglot-ensure)
         (elixir-ts-mode . subword-mode)
         (elixir-ts-mode . my/elixir-mode-setup))
  :bind
  (:map elixir-ts-mode-map
    ("C-c ." . +elixir-test-at-point)
    ("C-c t" . +elixir-test-file)
    ("C-c T" . +elixir-test-project)
    ("C-c c" . compile)))

(use-package heex-ts-mode
  :straight (:type built-in)
  :mode (("\\.heex\\'" . heex-ts-mode))
  :hook ((heex-ts-mode . eglot-ensure)
         (heex-ts-mode . subword-mode)
         (heex-ts-mode . my/elixir-mode-setup))
  :bind
  (:map heex-ts-mode-map
    ("C-c T" . +elixir-test-project)
    ("C-c c" . compile)))

(with-eval-after-load 'eglot
  (dolist (mode '(elixir-ts-mode heex-ts-mode))
    (add-to-list 'eglot-server-programs `(,mode . ("elixir-ls")))))

(provide 'dev-elixir)
;;; dev-elixir.el ends here
