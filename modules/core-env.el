;;; core-env.el --- Setup the environment -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defvar *my/required-environment-variables* '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME" "JAVA_HOME" "SBT_HOME"))

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :custom
  (exec-path-from-shell-variables *my/required-environment-variables*)
  (exec-path-from-shell-arguments '("-l"))
  (exec-path-from-shell-check-startup-files nil)
  :config
  (exec-path-from-shell-initialize))

;;;; Environment file management
(defun my/generate-env-file ()
  "Generate .env file from current shell environment.
Similar to doom emacs sync."
  (interactive)
  (let ((env-file (expand-file-name ".env" user-emacs-directory))
        (shell (or (getenv "SHELL") "/bin/zsh")))
    (message "Generating environment file from %s..." shell)
    (with-temp-file env-file
      (insert "# Generated environment file\n")
      (insert "# Run M-x my/generate-env-file to regenerate\n\n")
      (dolist (var *my/required-environment-variables*)
        (let ((value (getenv var)))
          (when value
            (insert (format "%s=%s\n" var value))))))
    (message "Environment file generated: %s" env-file)))

(defun my/load-env-file (&optional file)
  "Load environment variables from FILE (default: ~/.emacs.d/.env)."
  (interactive)
  (let ((env-file (or file (expand-file-name ".env" user-emacs-directory))))
    (if (not (file-exists-p env-file))
        (message "Environment file not found: %s" env-file)
      (with-temp-buffer
        (insert-file-contents env-file)
        (goto-char (point-min))
        (let ((count 0))
          (while (re-search-forward "^\\([^#][^=]+\\)=\\(.+\\)$" nil t)
            (let ((key (match-string 1))
                  (value (match-string 2)))
              (setenv key value)
              (when (string= key "PATH")
                (setq exec-path (split-string value path-separator t)))
              (setq count (1+ count))))
          (message "Loaded %d environment variables from %s" count env-file))))))

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
  (exec-path-from-shell-initialize)
  (when (fboundp 'mise-activate)
    (mise-activate))
  (message "Environment reloaded"))

;;; MISE setup
(use-package mise
  :straight (:host github :repo "liuyinz/mise.el")
  :hook (after-init . global-mise-mode)
  :custom
  (mise-auto-activate t))

(provide 'core-env)
;;; core-env.el ends here
