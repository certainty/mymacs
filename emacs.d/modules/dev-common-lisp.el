;;; dev-common-lisp.el --- Common Lisp via Sly -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Common Lisp development using Sly (Sylvester the Cat's Common Lisp IDE).
;; Requires SBCL installed on the system.  The REPL opens in a side window.
;;
;;; Code:

;;; Sly

(use-package sly
  :straight t
  :hook (sly-mode . corfu-mode)
  :custom
  (inferior-lisp-program "sbcl")
  (sly-complete-symbol-function #'sly-flex-completions)
  (sly-net-coding-system 'utf-8-unix)
  :init
  (add-to-list 'auto-mode-alist '("\\.ros\\'" . lisp-mode))
  :config
  (setq sly-lisp-implementations
        '((sbcl ("sbcl") :coding-system utf-8-unix)))
  (setq sly-contribs
        '(sly-fancy sly-stickers sly-scratch sly-mrepl
          sly-autodoc sly-trace-dialog))

  ;; Buffer placement
  (my/register-side-popup 'sly-mrepl-mode t nil)
  (my/register-bottom-popup "\\*sly-compilation" nil t)

  :preface
  (defun +sly-start ()
    "Start Sly with the default implementation."
    (interactive)
    (call-interactively #'sly))

  (defun +sly-start-select ()
    "Start Sly, prompting for the implementation to use."
    (interactive)
    (let ((current-prefix-arg '-))
      (call-interactively #'sly))))

;;; Sly extensions

(use-package sly-asdf
  :straight t
  :after sly
  :config
  (add-to-list 'sly-contribs 'sly-asdf 'append))

(use-package sly-quicklisp
  :straight t
  :after sly
  :config
  (add-to-list 'sly-contribs 'sly-quicklisp 'append))

(use-package sly-macrostep
  :straight t
  :after sly
  :config
  (add-to-list 'sly-contribs 'sly-macrostep))

(use-package sly-repl-ansi-color
  :straight t
  :after sly
  :config
  (add-to-list 'sly-contribs 'sly-repl-ansi-color))

(provide 'dev-common-lisp)
;;; dev-common-lisp.el ends here
