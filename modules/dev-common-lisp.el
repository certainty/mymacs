;;; dev-common-lisp.el --- bring the power of common lisp  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package sly
  :hook (sly-mode . corfu-mode)
  :custom
  (sly-lisp-implementation 'sbcl)
  (inferior-lisp-program "sbcl")
  (sly-complete-symbol-function #'sly-flex-completions)

  :init
  (my/window-rule! sly-mrepl-mode :align right :size 0.4 :select t)
  (my/with-popper! "^\\*sly-compilation")
  (my/with-popper! "^\\*sly-mrepl")
  (add-to-list 'auto-mode-alist '("\\.ros\\'" . lisp-mode))

  :config
  (setopt sly-lisp-implementations
    `((sbcl ("sbcl") :coding-system utf-8-unix)))

  (setq sly-contribs '(sly-fancy sly-stickers sly-scratch sly-mrepl sly-autodoc sly-trace-dialog))
  (setopt sly-common-lisp-set-style 'modern)
  :preface
  (defun +open-repl-select ()
    "Select the Common Lisp implementation to use."
    (interactive)
    (let ((current-prefix-arg '-))
      (call-interactively #'sly)))

  (defun +open-repl ()
    "Open the Sly REPL."
    (interactive)
    (call-interactively #'sly))

  (defun +reload-project ()
    "Restart the Sly session and reload a chosen system."
    (interactive)
    (sly-restart-inferior-lisp)
    (cl-labels ((recurse (attempt)
                  (sleep-for 1)
                  (condition-case nil
                    (sly-eval "PONG")
                    (error (if (= 5 attempt)
                             (error "Failed to reload Lisp project in 5 attempts.")
                             (recurse (1+ attempt)))))))
      (recurse 1)
      (sly-asdf-load-system)))

  (defun my/setup-common-lisp ()
    (if (file-exists-p "~/.local/share/quicklisp/log4sly-setup.el")
      (progn
        (load "~/.local/share/quicklisp/log4sly-setup.el")
        (global-log4sly-mode 1))
      (message "log4sly not found"))))

(use-package sly-asdf
  :after sly
  :init
  (add-to-list 'sly-contribs 'sly-asdf 'append))

(use-package sly-quicklisp
  :hook sly-mode
  :init
  (add-to-list 'sly-contribs 'sly-quicklisp 'append))

(use-package sly-macrostep
  :init
  (add-to-list 'sly-contribs 'sly-macrostep))

(use-package sly-repl-ansi-color
  :init
  (add-to-list 'sly-contribs 'sly-repl-ansi-color))

(use-package sly-overlay)

(provide 'dev-common-lisp)
