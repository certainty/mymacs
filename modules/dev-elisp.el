;;; dev-elisp.el --- Elisp config for sweeter emacs experience -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package emacs-lisp-mode
  :straight (:type built-in)
  :mode (("\\.el$" . emacs-lisp-mode))
  :interpreter (("emacs" . emacs-lisp-mode))
  :custom
  (lisp-indent-offset 2))

(use-package eldoc
  :straight (:type built-in)
  :commands eldoc-mode
  :hook (emacs-lisp-mode . turn-on-eldoc-mode)
  :general
  (local-leader-def
    :keymaps 'emacs-lisp-mode-map
    "d" '(:ignore t :which-key "doc")
    "de" '+toggle-eldoc-buffer
    "e" '(:ignore t :which-key "eval")
    "eb" 'eval-buffer
    "ed" 'eval-defun
    "ee" 'eval-last-sexp
    "er" 'eval-region
    "el" 'load-library
    "h" '(:ignore t :which-key "help")
    "hf" 'describe-function
    "hv" 'describe-variable
    "hk" 'describe-key
    "hp" 'describe-package
    "t" 'ert)
  :custom
  (eldoc-echo-area-use-multiline-p t)
  (eldoc-echo-area-display-truncation-message nil)
  :config
  (setq lisp-indent-function 'common-lisp-indent-function)
  (setq eldoc-idle-delay 0)

  :preface
  (defun +toggle-eldoc-buffer ()
    (interactive)
    (let ((buf (get-buffer "*eldoc*")))
      (if buf
        (progn
          (when-let ((win (get-buffer-window buf)))
            (delete-window win))
          (kill-buffer buf))
        (eldoc)))))

;; better jump to definition
(use-package elisp-def
  :commands (elisp-def elisp-def-mode)
  :config
  (dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook lisp-interaction-mode-hook))
    (add-hook hook #'elisp-def-mode))

  (dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook lisp-interaction-mode-hook))
    (add-hook hook (lambda ()
                     (setq show-trailing-whitespace t)
                     (setq show-paren-context-when-offscreen t)
                     (prettify-symbols-mode 1)
                     (eldoc-mode 1)
                     (rainbow-delimiters-mode 1)))))

(provide 'dev-elisp)
