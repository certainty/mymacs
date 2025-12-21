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
  (with-eval-after-load 'popper
    (cl-pushnew 'sly-mrepl-mode popper-reference-buffers))

  (add-to-list 'auto-mode-alist '("\\.ros\\'" . lisp-mode))

  :config
  (setopt sly-lisp-implementations
    `((sbcl ("sbcl") :coding-system utf-8-unix)))

  (setq sly-contribs '(sly-fancy sly-stickers sly-scratch sly-mrepl sly-autodoc sly-trace-dialog))
  (setopt sly-common-lisp-set-style 'modern)

  (add-to-list 'display-buffer-alist
    '("^\\*sly-compilation"
       (display-buffer-reuse-window
         display-buffer-in-side-window)
       (side . bottom)
       (reusable-frames . visible)
       (window-height . 0.3)))

  (add-to-list 'display-buffer-alist
    '("^\\*sly-mrepl"
       (display-buffer-reuse-window
         display-buffer-in-side-window)
       (side . right)
       (reusable-frames . visible)
       (window-height . 0.4)))

  :preface
  (defun my/select-implementation ()
    "Select the Common Lisp implementation to use."
    (interactive)
    (let ((current-prefix-arg '-))
      (call-interactively #'sly)))

  (defun my/open-repl ()
    "Open the Sly REPL."
    (interactive)
    (require 'sly)
    (if (sly-connected-p)
      (sly-mrepl)
      (sly nil nil t)
      (cl-labels ((recurse (attempt)
                    (sleep-for 1)
                    (cond ((sly-connected-p) (sly-mrepl))
                      ((> attempt 5) (error "Failed to start Slynk process."))
                      (t (recurse (1+ attempt))))))
        (recurse 1))))


  (defun my/reload-project ()
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
      (message "log4sly not found")))

  :general
  (local-leader-def
    :keymaps 'sly-mode-map
    "e" '(:ignore t :which-key "export")
    "es" 'sly-export-symbol-at-point
    "eS" 'sly-export-struct
    "ec" 'sly-export-class

    "!" '(:ignore t :which-key "diagnostics")
    "!c" 'sly-remove-notes
    "!n" 'sly-next-note
    "!e" 'sly-next-error

    "c" '(:ignore t :which-key "compile")
    "cc" 'sly-compile-defun
    "cf" 'sly-compile-file
    "cs" 'sly-compile-and-load-file
    "cr" 'sly-compile-region
    "cl" 'sly-load-file

    "h" '(:ignore t :which-key "help")
    "h." 'sly-describe-symbol
    "hh" 'hyperspec-lookup
    "h~" 'hyperspec-lookup-format
    "#"  'hyperspec-lookup-reader-macro
    "d"  'sly-documentation-lookup

    "x" '(:ignore t :which-key "xref")
    "xa" 'sly-apropos
    "xp" 'sly-apropos-package
    "x<" 'sly-who-calls
    "x>" 'sly-calls-who
    "xx" 'sly-who-references
    "xm" 'sly-who-macroexpands
    "xs" 'sly-who-sets
    "xS" 'sly-who-specializes

    "r" '(:ignore t :which-key "repl")
    "rr" 'my/open-repl
    "rc" 'my/select-implementation
    "rC" 'sly-mrepl-clear-repls
    "rl" 'sly-asdf-load-system
    "rR" 'sly-restart-inferior-lisp
    "rp" 'my/reload-project
    "rs" 'sly-mrepl-sync

    "s" '(:ignore t :which-key "stickers")
    "sb" 'sly-stickers-toggle-break-on-stickers
    "sc" 'sly-stickers-clear-defun-stickers
    "sC" 'sly-sitckers-clear-buffer-stickers
    "sf" 'sly-stickers-fetch
    "ss" 'sly-sickers-dwim

    "t" '(:ignore t :which-key "trace")
    "tt" 'sly-trace-dialog-toggle-trace
    "tT" 'sly-trace-dialog-toggle-complex-trace
    "td" 'sly-trace-dialog
    "tu" 'sly-trace-dialog-untrace-all
    )


  )


(use-package sly-asdf
  :after sly
  :general
  (local-leader-def
    :keymaps 'sly-mode-map
    "a" '(:ignore t :which-key "asdf")
    "ar" 'sly-asdf-reload-system
    "ac" 'sly-asdf-compile-system
    "al" 'sly-asdf-load-system
    "ab" 'sly-asdf-browse-system
    "at" 'sly-asdf-test-system)
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
