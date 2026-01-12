;;; core-help.el --- Help system -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defun my/info-display-manual ()
  "Display Emacs manual."
  (interactive)
  (info "emacs"))

(defun my/info-elisp-manual ()
  "Display Emacs Lisp manual."
  (interactive)
  (info "elisp"))

(defun my/describe-face-at-point ()
  "Describe the face at point."
  (interactive)
  (let ((face (get-text-property (point) 'face)))
    (if face
      (describe-face face)
      (message "No face at point"))))

(use-package helpful
  :bind
  (([remap describe-function] . helpful-callable)
    ([remap describe-variable] . helpful-variable)
    ([remap describe-key] . helpful-key)
    ([remap describe-command] . helpful-command)
    ([remap describe-symbol] . helpful-symbol))
  :custom
  (helpful-max-buffers 2))

(with-eval-after-load 'general
  (leader-def
    "sh" '(:ignore t :which-key "help")
    "shf" 'helpful-callable
    "shF" 'helpful-function
    "shv" 'helpful-variable
    "shk" 'helpful-key
    "shc" 'helpful-command
    "shs" 'helpful-symbol
    "sh." 'helpful-at-point

    "shm" 'describe-mode
    "shb" 'describe-bindings
    "shK" 'describe-keymap
    "sha" 'apropos
    "shA" 'apropos-documentation

    "shw" 'woman
    "shi" 'info
    "shI" 'info-display-manual
    "she" 'my/info-elisp-manual
    "shE" 'my/info-display-manual

    "shP" 'describe-package
    "shC" 'describe-char
    "shT" 'describe-theme
    "shx" 'describe-syntax

    "shd" '(:ignore t :which-key "describe")
    "shdf" 'my/describe-face-at-point
    "shdF" 'describe-face
    "shdp" 'describe-text-properties

    ;; Which-key
    "sh?" 'which-key-show-top-level
    "shW" 'which-key-show-major-mode))

;;;; Info mode enhancements
(use-package info
  :straight (:type built-in)
  :custom
  (Info-use-header-line nil))

(provide 'core-help)
;;; core-help.el ends here
