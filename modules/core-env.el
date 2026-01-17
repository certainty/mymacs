;;; core-env.el --- Setup the environment -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defvar *my/required-environment-variables* '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME" "JAVA_HOME" "SBT_HOME"))

(use-package emacs
  :init
  (add-to-list 'exec-path (expand-file-name "~/.local/bin")))

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :demand t
  :custom
  (exec-path-from-shell-variables *my/required-environment-variables*)
  (exec-path-from-shell-arguments '("-l"))
  (exec-path-from-shell-check-startup-files nil)
  :config
  (exec-path-from-shell-initialize))

(defun my/show-path ()
  "Show current PATH and exec-path."
  (interactive)
  (with-help-window "*PATH*"
    (princ "Environment PATH:\n")
    (princ (getenv "PATH"))
    (princ "\n\n")
    (princ "Emacs exec-path:\n")
    (dolist (path exec-path)
      (princ (format "%s\n" path)))))

(defun my/reload-environment ()
  "Reload environment from shell and mise."
  (interactive)
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize))
  (when (fboundp 'mise-activate)
    (mise-activate))
  (message "Environment reloaded"))

(use-package mise
  :straight (:host github :repo "liuyinz/mise.el")
  :hook (after-init . global-mise-mode)
  :custom
  (mise-auto-activate t))

(provide 'core-env)
;;; core-env.el ends here
