;;; core-env.el --- Environment setup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Ensure PATH and other environment variables are available to Emacs,
;; especially on macOS where GUI Emacs does not inherit shell environment.
;; Also loads mise for runtime version management.
;;
;;; Code:

(defconst my/required-environment-variables
  '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME" "JAVA_HOME" "SBT_HOME")
  "Environment variables to import from the shell on macOS.")

(use-package emacs
  :init
  (let ((path (expand-file-name "~/.local/bin")))
    (add-to-list 'exec-path path)
    (setenv "PATH" (concat path path-separator (getenv "PATH")))))

(use-package exec-path-from-shell
  :ensure nil
  :if (memq window-system '(mac ns))
  :custom
  (exec-path-from-shell-variables my/required-environment-variables)
  ;; Use an interactive login shell so tool managers like mise contribute
  ;; the same PATH ordering that terminal sessions use.
  (exec-path-from-shell-arguments '("-l" "-i"))
  (exec-path-from-shell-check-startup-files nil)
  :config
  (exec-path-from-shell-initialize))

(defun +show-path ()
  "Show current PATH and exec-path."
  (interactive)
  (with-help-window "*PATH*"
    (princ "Environment PATH:\n")
    (princ (getenv "PATH"))
    (princ "\n\n")
    (princ "Emacs exec-path:\n")
    (dolist (path exec-path)
      (princ (format "%s\n" path)))))

(defun +reload-environment ()
  "Reload environment from shell and mise."
  (interactive)
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize))
  (when (fboundp 'mise-activate)
    (mise-activate))
  (message "Environment reloaded"))

(use-package mise
  :ensure nil
  :if (locate-library "mise")
  :hook (after-init . global-mise-mode)
  :custom
  (mise-auto-activate t))

(provide 'core-env)
;;; core-env.el ends here
