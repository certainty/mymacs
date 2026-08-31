;;; my-meow-helix.el --- Helix-style helpers for Meow -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)

(declare-function eglot-find-declaration "eglot")
(declare-function eglot-find-implementation "eglot")
(declare-function eglot-find-typeDefinition "eglot")
(declare-function +find-alternate-file "alternate-file")
(declare-function avy-goto-word-0 "avy")
(declare-function embrace-add "embrace")
(declare-function embrace-change "embrace")
(declare-function embrace-delete "embrace")
(declare-function diff-hl-hunk-overlay-at "diff-hl")
(declare-function diff-hl-next-hunk "diff-hl")
(declare-function diff-hl-previous-hunk "diff-hl")
(declare-function meow-back-symbol "meow")
(declare-function meow-back-word "meow")
(declare-function meow-bounds-of-thing "meow")
(declare-function meow-beginning-of-thing "meow")
(declare-function meow-end-of-thing "meow")
(declare-function meow-find "meow")
(declare-function meow-inner-of-thing "meow")
(declare-function meow-mark-symbol "meow")
(declare-function meow-mark-word "meow")
(declare-function meow-next-symbol "meow")
(declare-function meow-next-word "meow")
(declare-function meow-search "meow")
(declare-function meow-till "meow")
(declare-function meow-visit "meow")
(declare-function meow-tree-sitter-node "meow-tree-sitter")
(declare-function meow-tree-sitter--get-nodes-of-type "meow-tree-sitter")

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
  "w" #'avy-goto-word-0
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
  "[" #'meow-beginning-of-thing
  "]" #'meow-end-of-thing
  "s" #'embrace-add
  "r" #'embrace-change
  "d" #'embrace-delete)

(defvar-keymap my/meow-prev-map
  :doc "Helix-style previous location map for Meow."
  "g" #'diff-hl-previous-hunk
  "d" #'flymake-goto-prev-error
  "f" #'my/meow-tree-sitter-prev-function
  "t" #'my/meow-tree-sitter-prev-class
  "a" #'my/meow-tree-sitter-prev-parameter
  "c" #'my/meow-tree-sitter-prev-comment
  "T" #'my/meow-tree-sitter-prev-test)

(defvar-keymap my/meow-next-map
  :doc "Helix-style next location map for Meow."
  "g" #'diff-hl-next-hunk
  "d" #'flymake-goto-next-error
  "f" #'my/meow-tree-sitter-next-function
  "t" #'my/meow-tree-sitter-next-class
  "a" #'my/meow-tree-sitter-next-parameter
  "c" #'my/meow-tree-sitter-next-comment
  "T" #'my/meow-tree-sitter-next-test)

(defvar-keymap my/meow-view-state-map
  :doc "Helix-style view state keymap for Meow."
  "<escape>" #'meow-normal-mode
  "q" #'meow-normal-mode
  "j" #'scroll-up-line
  "k" #'scroll-down-line
  "C-f" #'scroll-up-command
  "C-b" #'scroll-down-command
  "C-d" #'my/scroll-up-half-page
  "C-u" #'my/scroll-down-half-page
  "z" #'recenter-top-bottom
  "c" #'recenter-top-bottom
  "t" #'my/recenter-top
  "b" #'my/recenter-bottom)

(meow-define-state view
  "Meow VIEW state."
  :lighter " [V]"
  :keymap my/meow-view-state-map
  :face meow-motion-cursor)

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

(defun my/meow-join-lines ()
  "Join the current line to the previous line without killing whitespace."
  (interactive)
  (delete-indentation))

(defun my/scroll-up-half-page ()
  "Scroll up by half a window without moving point."
  (interactive)
  (scroll-up-command (max 1 (/ (window-body-height) 2))))

(defun my/scroll-down-half-page ()
  "Scroll down by half a window without moving point."
  (interactive)
  (scroll-down-command (max 1 (/ (window-body-height) 2))))

(defun my/recenter-top ()
  "Place the current line at the top of the window."
  (interactive)
  (recenter 0))

(defun my/recenter-bottom ()
  "Place the current line at the bottom of the window."
  (interactive)
  (recenter -1))

(defun my/meow-tree-sitter-goto (type direction)
  "Move DIRECTION to the next Tree-sitter TYPE capture."
  (let* ((capture (intern (concat type ".around")))
         (nodes (meow-tree-sitter--get-nodes-of-type (list capture)))
         (bounds (sort (mapcar #'cdr nodes)
                       (lambda (left right) (< (car left) (car right)))))
         (target (if (eq direction 'next)
                     (cl-find-if (lambda (bound) (> (car bound) (point))) bounds)
                   (car (last (cl-remove-if-not
                               (lambda (bound) (< (car bound) (point)))
                               bounds))))))
    (if target
        (goto-char (car target))
      (user-error "No %s %s" direction type))))

(defmacro my/define-meow-tree-sitter-motion (name type direction)
  "Define NAME as a Tree-sitter motion for TYPE in DIRECTION."
  `(defun ,name ()
     ,(format "Move to the %s %s Tree-sitter object." direction type)
     (interactive)
     (my/meow-tree-sitter-goto ,type ',direction)))

(my/define-meow-tree-sitter-motion my/meow-tree-sitter-prev-function "function" prev)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-next-function "function" next)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-prev-class "class" prev)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-next-class "class" next)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-prev-parameter "parameter" prev)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-next-parameter "parameter" next)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-prev-comment "comment" prev)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-next-comment "comment" next)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-prev-test "test" prev)
(my/define-meow-tree-sitter-motion my/meow-tree-sitter-next-test "test" next)

(defun my/diff-hl-current-hunk-bounds ()
  "Return bounds of the current `diff-hl' hunk, if any."
  (when (fboundp 'diff-hl-hunk-overlay-at)
    (when-let* ((overlay (diff-hl-hunk-overlay-at (point))))
      (cons (overlay-start overlay) (overlay-end overlay)))))

(provide 'my-meow-helix)
;;; my-meow-helix.el ends here
