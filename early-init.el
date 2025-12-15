;;; early-init.el --- Bootstrap before init.el -*- lexical-binding: t; -*-

;;; Performance and native compilation
(setq read-process-output-max (* 1024 1024)
        comp-deferred-compilation t
        comp-async-report-warnings-errors nil)

(setq native-comp-jit-compilation t
        native-comp-warning-on-missing-source t
        native-comp-async-report-warnings-errors t
        package-enable-at-startup nil)

;; Prefer newest .el over .elc
(setq load-prefer-newer t)

;;; Environment setup (from env.el)
(defvar my/env nil
  "User environment key-value alist loaded from env.el.")

(let ((env-file (expand-file-name "env.el" user-emacs-directory)))
  (when (file-exists-p env-file)
    (load env-file nil t)
    (when (boundp 'my/env)
      (dolist (pair my/env)
        (let* ((key (symbol-name (car pair)))
               (val (expand-file-name (cdr pair))))
          (setenv key val)
          (when (string-equal key "PATH")
            (setq exec-path
                  (delete-dups (append (parse-colon-path val) exec-path)))))))))

;;; Frame/UI minimalism for faster init

(setq frame-inhibit-implied-resize t
        inhibit-startup-screen t
        inhibit-startup-echo-area-message user-login-name
        inhibit-startup-buffer-menu t
        inhibit-splash-screen t
        inhibit-x-resources t
        default-frame-alist
        '((menu-bar-lines . 0)
          (tool-bar-lines . 0)
          (vertical-scroll-bars . nil)
          (fullscreen . maximized)))

;;; Avoid package.el;
(setq package-enable-at-startup nil)
