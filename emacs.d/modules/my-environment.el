;;; my-environment.el --- Shell environment at startup -*- lexical-binding: t; -*-

;;; Environment setup (to start emacs from launcher)

(defconst my/required-environment-variables
  '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME" "JAVA_HOME" "SBT_HOME" "LD_LIBRARY_PATH" "C_INCLUDE_PATH" "LIBRARY_PATH")
  "Environment variables imported from the shell.")

(use-package exec-path-from-shell
  :ensure t
  :pin "nongnu"
  :custom
  (exec-path-from-shell-variables my/required-environment-variables)
  (exec-path-from-shell-arguments '("-l" "-i"))
  (exec-path-from-shell-check-startup-files nil)
  :config
  (exec-path-from-shell-initialize))

;;;; mise
(defun my/mise-run-task (task)
  "Run mise TASK in the current project with `compile'."
  (require 'project)
  (let ((default-directory (project-root (project-current t))))
    (compile (concat "mise " task))))

(defun my/mise-setup ()
  "Run the mise setup task."
  (interactive)
  (my/mise-run-task "setup"))

(defun my/mise-checks ()
  "Run the mise checks task."
  (interactive)
  (my/mise-run-task "checks"))

(defun my/mise-build ()
  "Run the mise build task."
  (interactive)
  (my/mise-run-task "build"))

(defun my/mise-autofix ()
  "Run the mise autofix task."
  (interactive)
  (my/mise-run-task "autofix"))

(use-package mise
  :ensure t
  :demand t
  :pin "melpa"
  :bind
  (:map my/mise-prefix-map
        ("s" . my/mise-setup)
        ("c" . my/mise-checks)
        ("b" . my/mise-build)
        ("a" . my/mise-autofix)
        ("m" . compile))
  :config
  (global-mise-mode 1))

(provide 'my-environment)
;;; my-environment.el ends here
