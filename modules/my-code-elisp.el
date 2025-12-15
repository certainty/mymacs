;;; my-code-elisp.el --- () -*- lexical-binding: t; -*-

(use-package emacs-lisp-mode
  :ensure nil
  :mode (("\\.el$" . emacs-lisp-mode))
  :interpreter (("emacs" . emacs-lisp-mode))
  :custom
  (lisp-indent-offset 2))

(use-package eldoc
  :ensure nil
  :commands eldoc-mode
  :hook (emacs-lisp-mode . turn-on-eldoc-mode)
  :general
  (my-buffer-keymap
   "e" '("eldoc" . my/toggle-eldoc-buffer))
  :config
  (setq eldoc-idle-delay 0)

  :preface
  (defun my/toggle-eldoc-buffer ()
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

  ;; Elisp hook
  (dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook lisp-interaction-mode-hook))
    (add-hook hook (lambda ()
                     (setq show-trailing-whitespace t)
                     (setq show-paren-context-when-offscreen t)
                     (prettify-symbols-mode 1)
                     (eldoc-mode 1)
                     (rainbow-delimiters-mode 1)))))

(provide 'my-code-elisp)
