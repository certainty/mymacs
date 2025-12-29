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
    "h" '(:ignore t :which-key "help")
    "hf" 'helpful-callable
    "hF" 'helpful-function
    "hv" 'helpful-variable
    "hk" 'helpful-key
    "hc" 'helpful-command
    "hs" 'helpful-symbol
    "h." 'helpful-at-point

    "hm" 'describe-mode
    "hb" 'describe-bindings
    "hK" 'describe-keymap
    "ha" 'apropos
    "hA" 'apropos-documentation

    "hw" 'woman
    "hi" 'info
    "hI" 'info-display-manual
    "he" 'my/info-elisp-manual
    "hE" 'my/info-display-manual

    "hP" 'describe-package
    "hF" 'describe-face
    "hC" 'describe-char
    "hT" 'describe-theme
    "hx" 'describe-syntax

    "hd" '(:ignore t :which-key "describe")
    "hdf" 'my/describe-face-at-point
    "hdp" 'describe-text-properties

    ;; Which-key
    "h?" 'which-key-show-top-level
    "hW" 'which-key-show-major-mode))

;;;; Info mode enhancements
(use-package info
  :straight (:type built-in)
  :custom
  (Info-use-header-line nil))

(provide 'core-help)
;;; core-help.el ends here
