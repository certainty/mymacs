;;; my-environment.el --- Shell environment at startup -*- lexical-binding: t; -*-

;;; Environment setup (to start emacs from launcher)
(use-package exec-path-from-shell
  ;; :if (memq window-system '(mac ns))
  :ensure t
  :pin "nongnu"
  :custom
  (exec-path-from-shell-variables my/required-environment-variables)
  (exec-path-from-shell-arguments '("-l" "-i"))
  (exec-path-from-shell-check-startup-files nil)
  :preface
  (defconst my/required-environment-variables
    '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME" "JAVA_HOME" "SBT_HOME" "LD_LIBRARY_PATH" "C_INCLUDE_PATH" "LIBRARY_PATH")
    "Environment variables imported from the shell on macOS.")
  :config
  (exec-path-from-shell-initialize))
(provide 'my-environment)
;;; my-environment.el ends here
