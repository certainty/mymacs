;;; my-meow-helix.el --- Helix-style helpers for Meow -*- lexical-binding: t; -*-

(require 'subr-x)

(declare-function eglot-find-declaration "eglot")
(declare-function eglot-find-implementation "eglot")
(declare-function eglot-find-typeDefinition "eglot")
(declare-function +find-alternate-file "alternate-file")
(declare-function embrace-add "embrace")
(declare-function embrace-change "embrace")
(declare-function embrace-delete "embrace")
(declare-function meow-back-symbol "meow")
(declare-function meow-back-word "meow")
(declare-function meow-bounds-of-thing "meow")
(declare-function meow-find "meow")
(declare-function meow-inner-of-thing "meow")
(declare-function meow-mark-symbol "meow")
(declare-function meow-mark-word "meow")
(declare-function meow-next-symbol "meow")
(declare-function meow-next-word "meow")
(declare-function meow-search "meow")
(declare-function meow-till "meow")
(declare-function meow-visit "meow")

(defvar regexp-search-ring)

(defvar-keymap my/meow-goto-map
  :doc "Helix-style goto map for Meow."
  "g" #'beginning-of-buffer
  "e" #'end-of-buffer
  "h" #'beginning-of-line
  "l" #'end-of-line
  "s" #'back-to-indentation
  "t" #'my/meow-goto-window-top
  "c" #'move-to-window-line-top-bottom
  "b" #'my/meow-goto-window-bottom
  "d" #'xref-find-definitions
  "D" #'eglot-find-declaration
  "y" #'eglot-find-typeDefinition
  "r" #'xref-find-references
  "i" #'eglot-find-implementation
  "a" #'+find-alternate-file
  "n" #'next-buffer
  "p" #'previous-buffer)

(defvar-keymap my/meow-match-map
  :doc "Helix-style match map for Meow."
  "m" #'my/meow-match-pair
  "a" #'meow-bounds-of-thing
  "i" #'meow-inner-of-thing
  "s" #'embrace-add
  "r" #'embrace-change
  "d" #'embrace-delete)

(defun my/meow-search-forward ()
  "Start forward Meow visit."
  (interactive)
  (meow-visit nil))

(defun my/meow-search-backward ()
  "Start backward Meow visit."
  (interactive)
  (meow-visit t))

(defun my/meow-search-next ()
  "Repeat current Meow search forward."
  (interactive)
  (meow-search nil))

(defun my/meow-search-prev ()
  "Repeat current Meow search backward."
  (interactive)
  (meow-search '-))

(defun my/meow-find-backward (count char)
  "Find CHAR backward COUNT times."
  (interactive "p\ncBackward find: ")
  (meow-find (- count) char))

(defun my/meow-till-backward (count char)
  "Till CHAR backward COUNT times."
  (interactive "p\ncBackward till: ")
  (meow-till (- count) char))

(defun my/meow-goto-window-top ()
  "Move point to top visible line."
  (interactive)
  (move-to-window-line 0))

(defun my/meow-goto-window-bottom ()
  "Move point to bottom visible line."
  (interactive)
  (move-to-window-line -1))

(defun my/meow-match-pair ()
  "Jump to matching delimiter."
  (interactive)
  (let ((after (char-after))
        (before (char-before)))
    (cond
     ((and after (eq (char-syntax after) ?\())
      (goto-char (1- (scan-sexps (point) 1))))
     ((and after (eq (char-syntax after) ?\)))
      (goto-char (scan-sexps (1+ (point)) -1)))
     ((and before (eq (char-syntax before) ?\)))
      (goto-char (scan-sexps (point) -1)))
     ((nth 1 (syntax-ppss))
      (goto-char (nth 1 (syntax-ppss))))
     (t
      (user-error "No matching delimiter at point")))))

(provide 'my-meow-helix)
;;; my-meow-helix.el ends here
