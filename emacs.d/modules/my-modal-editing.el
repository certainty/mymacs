;;; my-modal-editing.el --- Modal editing configuration -*- lexical-binding: t; -*-

(eval-when-compile (require 'meow))

;;;; modal editing
(use-package embrace
  :ensure t
  :pin "melpa"
  :commands (embrace-add embrace-change embrace-delete))

(use-package meow
  :ensure t
  :demand t
  :pin "melpa"
  :custom
  (meow-display-thing-help t)
  (meow-use-clipboard t)
  (meow-selection-command-fallback
   '((meow-change . meow-change-char)
     (meow-kill . meow-delete)
     (meow-save . kill-ring-save)
     (meow-cancel-selection . keyboard-quit)
     (meow-pop-selection . meow-pop-grab)
     (meow-beacon-change . meow-beacon-change-char)
     (meow-expand . meow-digit-argument)))
  (meow-char-thing-table
   '((?\( . round)
     (?\[ . square)
     (?\{ . curly)
     (?\" . string)
     (?e . symbol)
     (?w . word)
     (?W . window)
     (?b . buffer)
     (?p . paragraph)
     (?l . line)
     (?v . visual-line)
     (?d . defun)
     (?g . git-change)
     (?. . sentence)))
  (meow-expand-hint-counts
   '((word . 0)
     (line . 0)
     (block . 0)
     (find . 0)
     (till . 0)
     (symbol . 0)))
  (meow-keypad-leader-dispatch my/leader-map)
  (meow-keypad-leader-transparent 'normal)
  (meow-keypad-message nil)
  (meow-mode-state-list
   '((special-mode . motion)
     (taskwarrior-list-mode . motion)
     (taskwarrior-report-mode . motion)
     (dired-mode . motion)
     (term-mode . insert)
     (shell-mode . insert)
     (eshell-mode . insert)
     (comint-mode . insert)
     (eat-mode . insert)
     (conf-mode . normal)
     (fundamental-mode . normal)
     (help-mode . motion)))
  :preface
  (defun my/meow-escape ()
    (interactive)
    (if (region-active-p)
        (meow-cancel-selection)
      (+escape-dwim)))

  (defun my/meow-insert-at-bol ()
    (interactive)
    (back-to-indentation)
    (meow-insert))

  (defun my/meow-append-at-eol ()
    (interactive)
    (end-of-line)
    (meow-append))

  (defun my/meow-backward-sexp ()
    (interactive)
    (mark-sexp -1))

  (defun my/meow-forward-sexp ()
    (interactive)
    (mark-sexp 1))

  (defun my/meow-setup ()
    (meow-motion-define-key
     '("<escape>" . my/meow-escape)
     '("j" . meow-next)
     '("k" . meow-prev)
     '("h" . meow-left)
     '("l" . meow-right))
    (meow-normal-define-key
     '("0" . meow-expand-0)
     '("1" . meow-expand-1)
     '("2" . meow-expand-2)
     '("3" . meow-expand-3)
     '("4" . meow-expand-4)
     '("5" . meow-expand-5)
     '("6" . meow-expand-6)
     '("7" . meow-expand-7)
     '("8" . meow-expand-8)
     '("9" . meow-expand-9)
     '("-" . negative-argument)
     '("@" . meow-mark-word)
     '("C-@" . meow-mark-symbol)
     '("?" . my/meow-search-backward)
     '(")" . my/meow-backward-sexp)
     '("(" . my/meow-forward-sexp)
     '(">" . paredit-forward-slurp-sexp)
     '("<" . paredit-backward-barf-sexp)
     '(";" . meow-reverse)
     '("," . meow-inner-of-thing)
     '("." . meow-bounds-of-thing)
     (cons "[" my/meow-prev-map)
     (cons "]" my/meow-next-map)
     '("{" . backward-paragraph)
     '("}" . forward-paragraph)
     '("a" . meow-append)
     '("A" . my/meow-append-at-eol)
     '("b" . meow-back-word)
     '("c" . meow-change)
     '("d" . meow-kill)
     '("D" . meow-C-k)
     '("e" . meow-next-word)
     '("f" . meow-find)
     '("F" . my/meow-find-backward)
     (cons "g" my/meow-goto-map)
     '("G" . end-of-buffer)
     '("h" . meow-left)
     '("i" . meow-insert)
     '("I" . my/meow-insert-at-bol)
     '("j" . meow-next)
     '("J" . my/meow-join-lines)
     '("k" . meow-prev)
     '("l" . meow-right)
     '("H" . meow-left-expand)
     '("K" . meow-prev-expand)
     '("L" . meow-right-expand)
     (cons "m" my/meow-match-map)
     '("M" . meow-tree-sitter-node)
     '("n" . my/meow-search-next)
     '("N" . my/meow-search-prev)
     '("o" . meow-open-below)
     '("O" . meow-open-above)
     '("p" . meow-yank)
     '("P" . meow-pop-selection)
     '("/" . my/meow-search-forward)
     '("s" . meow-swap-grab)
     '("t" . meow-till)
     '("T" . my/meow-till-backward)
     '("u" . meow-undo)
     '("v" . expreg-expand)
     '("V" . expreg-contract)
     '("w" . meow-mark-word)
     '("x" . meow-line)
     '("X" . meow-delete)
     '("y" . meow-save)
     '("#" . meow-grab)
     '("z" . meow-view-mode)
     '("Z" . meow-view-mode)
     '("W" . meow-mark-symbol)
     '("B" . meow-back-symbol)
     '("E" . meow-next-symbol)
     '("<backspace>" . meow-backspace)
     '("DEL" . meow-backspace)
     '("<escape>" . my/meow-escape)))
  :init
  (setq meow-cursor-type-normal 'box
        meow-cursor-type-insert '(bar . 2)
        meow-cursor-type-motion 'hollow)
  :config
  (require 'cl-lib)
  (require 'subr-x)
  (require 'flymake)

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
    "," #'pop-to-mark-command
    "M" #'consult-mark
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


  (keymap-set my/leader-map "f" #'project-find-file)
  (keymap-set my/leader-map "F" #'find-file)
  (keymap-set my/leader-map "e" #'project-dired)
  (keymap-set my/leader-map "b" #'consult-project-buffer)
  (keymap-set my/leader-map "B" #'consult-buffer)
  (keymap-set my/leader-map "s" #'consult-imenu)
  (keymap-set my/leader-map "S" #'consult-imenu-multi)
  (keymap-set my/leader-map "/" #'consult-ripgrep)
  (keymap-set my/leader-map "d" #'consult-flymake)
  (keymap-set my/leader-map "D" #'flymake-show-project-diagnostics)
  (keymap-set my/leader-map "a" #'eglot-code-actions)
  (keymap-set my/leader-map "r" #'eglot-rename)
  (keymap-set my/leader-map "=" #'eglot-format-buffer)
  (keymap-set my/leader-map "k" #'eldoc)
  (keymap-set my/leader-map "h" #'xref-find-references)
  (keymap-set my/open-prefix-map "o" #'consult-recent-file)
  (keymap-set my/open-prefix-map "l" #'+links-bookmarks)
  (keymap-set my/project-prefix-map "v" #'+links-project-repository)
  (keymap-set my/project-prefix-map "r" #'+links-project-pull-requests)
  (keymap-set my/project-prefix-map "R" #'+links-current-branch-pull-request)
  (keymap-set my/leader-map "v" #'magit-status)
  (meow-thing-register 'git-change
                       #'my/diff-hl-current-hunk-bounds
                       #'my/diff-hl-current-hunk-bounds)
  (my/meow-setup)
  (meow-global-mode 1))

(use-package meow-tree-sitter
  :ensure t
  :demand t
  :pin "melpa"
  :config
  (dolist (binding '((?f . "function")
                     (?a . "parameter")
                     (?t . "test")
                     (?c . "comment")
                     (?d . "entry")
                     (?k . "class")))
    (setq meow-char-thing-table
          (assoc-delete-all (car binding) meow-char-thing-table))
    (meow-tree-sitter-register-thing (car binding) (cdr binding))))

(provide 'my-modal-editing)
;;; my-modal-editing.el ends here
