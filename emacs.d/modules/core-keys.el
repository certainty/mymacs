;;; core-keys.el --- Keybinding infrastructure and modal editing -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; This module implements the modal editing system (Meow) and the leader-key
;; infrastructure.  It follows a "semantic noun-verb" approach: the first key
;; after the leader (SPC) denotes a noun (the thing you operate on), and the
;; second key is the verb (the action).
;;
;; To preserve Meow's Keypad mode (god-mode-like functionality), the following
;; keys are left unbound in the leader map:
;; - x (C-x)
;; - c (C-c)
;; - h (C-h)
;; - m (M-)
;; - g (C-M-)
;;
;;; Code:

(eval-when-compile (require 'cl-lib))

(when (eq system-type 'darwin)
  (setopt mac-command-modifier 'super
    mac-option-modifier 'meta
    mac-right-option-modifier 'none))

;;; Prefix commands for semantic noun-verb grouping

(define-prefix-command '+buffer nil "Buffer")
(define-prefix-command '+file nil "File")
(define-prefix-command '+window nil "Window")
(define-prefix-command '+language nil "Language")
(define-prefix-command '+terminal nil "Terminal")
(define-prefix-command '+vc nil "VC")
(define-prefix-command '+settings nil "Settings")
(define-prefix-command '+notes nil "Notes")
(define-prefix-command '+org nil "Org")
(define-prefix-command '+goto nil "Goto")
(define-prefix-command '+previous nil "Previous")
(define-prefix-command '+next nil "Next")
(define-prefix-command '+ai nil "AI")
(define-prefix-command '+tools nil "Tools")

;;; Leader Map Setup

(defvar-keymap my/leader-map :doc "Authority for leader-key bindings.")

;;; Base Leader Bindings (nouns)
(keymap-set my/leader-map "b" '+buffer)
(keymap-set my/leader-map "f" '+file)
(keymap-set my/leader-map "w" '+window)
(keymap-set my/leader-map "p" project-prefix-map)
(keymap-set my/leader-map "l" '+language)
(keymap-set my/leader-map "t" '+terminal)
(keymap-set my/leader-map "v" '+vc)
(keymap-set my/leader-map "s" '+settings)

(when my/enable-writing
  (keymap-set my/leader-map "j" '+notes))

(when my/enable-gtd
  (keymap-set my/leader-map "o" '+org))

(when my/enable-ai
  (keymap-set my/leader-map "a" '+ai))

(when my/enable-pmd
  (keymap-set my/leader-map "," '+tools)
  (keymap-set +tools "," '+pmd-projects)
  (keymap-set +tools "t" '+pmd-teams)
  (keymap-set +tools "p" '+pmd-people)
  (keymap-set +tools "s" '+pmd-servicegroups))

;;; Direct leader shortcuts (most frequent actions)


(keymap-set my/leader-map "e" 'dired-jump)
(keymap-set my/leader-map "/" 'consult-ripgrep)
(keymap-set my/leader-map "|" '+split-vertically)
(keymap-set my/leader-map "=" '+split-horizontally)
(keymap-set my/leader-map ";" 'meow-comment)
(keymap-set my/leader-map "*" '+find-symbol)

;;; Buffer group (noun: buffer)

(keymap-set '+buffer "b" 'consult-project-buffer)
(keymap-set '+buffer "c" 'popper-cycle)
(keymap-set '+buffer "B" 'consult-buffer)
(keymap-set '+buffer "K" '+kill-all)
(keymap-set '+buffer "o" 'consult-imenu)
(keymap-set '+buffer "Q" 'project-kill-buffers)
(keymap-set '+buffer "q" 'kill-current-buffer)
(keymap-set '+buffer "r" 'revert-buffer)
(keymap-set '+buffer "s" 'consult-line)
(keymap-set '+buffer "z" 'bury-buffer)

;;; File group (noun: file)

(keymap-set '+file "f" 'project-find-file)
(keymap-set '+file "F" 'find-file)
(keymap-set '+file "r" 'consult-recent-file)
(keymap-set '+file "s" 'save-buffer)
(keymap-set '+file "j" 'dired-jump)
(keymap-set '+file "@" 'consult-bookmark)

;;; Window group (noun: window)

(keymap-set '+window "w" 'ace-window)
(keymap-set '+window "x" 'ace-swap-window)
(keymap-set '+window "q" 'delete-window)
(keymap-set '+window "o" 'delete-other-windows)
(keymap-set '+window "=" 'balance-windows)
(keymap-set '+window "h" 'windmove-left)
(keymap-set '+window "j" 'windmove-down)
(keymap-set '+window "k" 'windmove-up)
(keymap-set '+window "l" 'windmove-right)
(keymap-set '+window "m" 'toggle-frame-maximized)
(keymap-set '+window "p" 'popper-cycle)

;;; Project / Worpspace
(keymap-set project-prefix-map "." 'tab-switch)

;;; Language group (noun: language / code)

(keymap-set '+language "d" 'xref-find-definitions)
(keymap-set '+language "D" 'eglot-find-declaration)
(keymap-set '+language "r" 'xref-find-references)
(keymap-set '+language "x" 'xref-find-references-and-replace)
(keymap-set '+language "a" 'eglot-code-actions)
(keymap-set '+language "i" 'eglot-find-implementation)
(keymap-set '+language "t" 'eglot-find-typeDefinition)
(keymap-set '+language "R" 'eglot-rename)
(keymap-set '+language "c" 'consult-flymake)
(keymap-set '+language "f" '+format-buffer)
(keymap-set '+language "F" '+toggle-format-on-save)
(keymap-set '+language "g" '+treesit-install-all-grammars)
(keymap-set '+language "q" 'eglot-shutdown)
(keymap-set '+language "l" 'eglot-list-connections)
(keymap-set '+language "E" 'eglot-reconnect)

;;; Terminal group (noun: terminal)

(keymap-set '+terminal "T" 'ghostel-toggle)
(keymap-set '+terminal "t" 'ghostel-toggle-project)
(keymap-set '+terminal "v" 'multi-vterm-project)

;;; AI group (noun: ai / agent)

(when my/enable-ai
  (keymap-set '+ai "a" '+ai-remote-agent)
  (keymap-set '+ai "s" '+ai-remote-agent-shell))

;;; VC group (noun: version control)

(keymap-set '+vc "v" 'magit-status)
(keymap-set '+vc "d" 'difftastic-magit-diff)
(keymap-set '+vc "." 'vc-dir)
(keymap-set '+vc "V" 'project-vc-dir)
(keymap-set '+vc "l" 'magit-log-buffer-file)
(keymap-set '+vc "L" 'magit-log-all)
(keymap-set '+vc "p" 'vc-update)
(keymap-set '+vc "P" 'vc-push)

;;; Settings group (noun: settings / toggles)

(keymap-set '+settings "f" '+font-bigger)
(keymap-set '+settings "F" '+font-presentation)
(keymap-set '+settings "+" 'text-scale-increase)
(keymap-set '+settings "-" 'text-scale-decrease)
(keymap-set '+settings "n" 'display-line-numbers-mode)
(keymap-set '+settings "t" '+cycle-theme)
(keymap-set '+settings "c" '+config-file)
(keymap-set '+settings "C" '+brows-config)
(keymap-set '+settings "m" '+edit-config-module)
(keymap-set '+settings "R" '+reload-config)

;;; Notes group (noun: notes / denote)

(when my/enable-writing
  (keymap-set '+notes "n" 'denote)
  (keymap-set '+notes "j" '+notes-find)
  (keymap-set '+notes "g" '+notes-grep)
  (keymap-set '+notes "l" 'denote-link)
  (keymap-set '+notes "b" 'denote-backlinks)
  (keymap-set '+notes "r" 'denote-rename-file)
  (keymap-set '+notes "d" '+browse-notes))

;;; Org group (noun: org / GTD)

(when my/enable-gtd
  (keymap-set '+org "a" '+personal-agenda)
  (keymap-set '+org "A" 'org-agenda)
  (keymap-set '+org "c" 'org-capture)
  (keymap-set '+org "x" '+org-toggle-next-up))

;;; Goto group (Meow normal-state prefix: g)

(keymap-set '+goto "g" 'beginning-of-buffer)
(keymap-set '+goto "e" 'end-of-buffer)
(keymap-set '+goto "h" 'back-to-indentation)
(keymap-set '+goto "l" 'end-of-line)
(keymap-set '+goto "d" 'xref-find-definitions)
(keymap-set '+goto "r" 'xref-find-references)
(keymap-set '+goto "s" 'jinx-next)
(keymap-set '+goto "?" 'helpful-at-point)

;;; Next group (Meow normal-state prefix: ])

(keymap-set '+next "]" 'forward-paragraph)
(keymap-set '+next "b" 'next-buffer)
(keymap-set '+next "p" 'forward-paragraph)
(keymap-set '+next "c" 'flymake-goto-next-error)
(keymap-set '+next "a" 'hl-todo-next)
(keymap-set '+next "h" 'diff-hl-next-hunk)
(keymap-set '+next "s" 'jinx-previous)
(keymap-set '+next "t" 'vterm-toggle-forward)
(keymap-set '+next "TAB" 'tab-next)

;;; Previous group (Meow normal-state prefix: [)

(keymap-set '+previous "[" 'backward-paragraph)
(keymap-set '+previous "b" 'previous-buffer)
(keymap-set '+previous "p" 'backward-paragraph)
(keymap-set '+previous "c" 'flymake-goto-prev-error)
(keymap-set '+previous "a" 'hl-todo-previous)
(keymap-set '+previous "h" 'diff-hl-previous-hunk)
(keymap-set '+previous "t" 'vterm-toggle-backward)
(keymap-set '+previous "TAB" 'tab-previous)

;;; Surround Map

(defvar-keymap my/surround-map :doc "Surround/embrace prefix map.")

;;; Help with keys

;; we rely on default help with embark support instead of which-key
(with-eval-after-load 'embark-act
  (setopt prefix-help-command #'embark-prefix-help-command))

;;; Expansion / Selection

(use-package expreg)

(use-package embrace
  :after meow
  :config
  (keymap-set my/surround-map "a" #'embrace-add)
  (keymap-set my/surround-map "c" #'embrace-change)
  (keymap-set my/surround-map "d" #'embrace-delete))

;;; Avy

(use-package avy)

;;; Selection helpers

(cl-defmacro my/with-selection (&body body)
  "Evaluate BODY with an active region.
If no region is active, set the mark at point first."
  `(progn
     (unless (region-active-p)
       (set-mark-command nil))
     ,@body))

(defmacro my/def-command-with-selection (original-cmd new-cmd)
  "Define NEW-CMD as a wrapper around ORIGINAL-CMD that ensures a selection."
  `(defun ,new-cmd ()
     (interactive)
     (my/with-selection
       (call-interactively #',original-cmd))))

;;; Meow Helpers

(defun my/insert-at-end-of-line ()
  (interactive)
  (meow-line 1)
  (meow-append))

(defun my/insert-at-beginning-of-indentation ()
  (interactive)
  (back-to-indentation)
  (meow-insert))

(defun my/avy-goto-char-timer-and-mark-symbol ()
  "Use `avy-goto-char-timer', then select the symbol at the jumped-to location."
  (interactive)
  (let ((orig (point)))
    (condition-case nil
      (progn
        (call-interactively #'avy-goto-char-timer)
        (when (/= (point) orig)
          (let ((bounds (bounds-of-thing-at-point 'symbol)))
            (when bounds
              (goto-char (car bounds))
              (set-mark (cdr bounds))
              (activate-mark)))))
      (quit
        (goto-char orig)))))

;;; Meow Setup

(defun my/meow-setup ()
  (meow-motion-define-key
    '("j" . meow-next)
    '("k" . meow-prev)
    '("C-j" . meow-next)
    '("C-k" . meow-prev)
    '("C-h" . meow-left)
    '("C-l" . meow-right)
    '("<escape>" . ignore))

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

    '("/" . meow-visit)
    '("-" . negative-argument)
    '("," . meow-inner-of-thing)
    '("." . meow-bounds-of-thing)

    '("<" . meow-beginning-of-thing)
    '(">" . meow-end-of-thing)

    '(")" . meow-forward-slurp)
    '("(" . meow-backward-slurp)
    '("{" . meow-backward-barf)
    '("}" . meow-forward-barf)

    '("^" . meow-join)
    '("%" . mark-whole-buffer)
    '("*" . avy-goto-char-timer)

    '("<escape>" . meow-cancel-selection)
    `("[" . ,+previous)
    `("]" . ,+next)
    '("~" . meow-reverse)
    '(";" . meow-comment)

    '("a" . meow-append)
    '("A" . my/insert-at-end-of-line)
    '("b" . meow-back-symbol)
    '("B" . meow-back-word)
    '("c" . meow-change)
    '("d" . meow-kill)
    '("D" . kill-line)
    '("e" . meow-next-symbol)
    '("E" . meow-next-word)
    '("f" . meow-find)
    '("F" . avy-goto-line)
    '("G" . meow-grab)
    `("g" . ,+goto)
    '("h" . meow-left)
    '("H" . meow-left-expand)
    '("i" . meow-insert)
    '("I" . my/insert-at-beginning-of-indentation)
    '("j" . meow-next)
    '("J" . meow-next-expand)
    '("k" . meow-prev)
    '("K" . meow-prev-expand)
    '("l" . meow-right)
    '("L" . meow-right-expand)
    '("m" . meow-block)
    '("M" . meow-to-block)
    '("n" . meow-search)
    '("N" . my/avy-goto-char-timer-and-mark-symbol)
    '("o" . meow-open-below)
    '("O" . meow-open-above)
    '("p" . meow-yank)
    '("q" . meow-quit)
    '("r" . meow-replace)
    '("R" . meow-swap-grab)
    `("s" . ,my/surround-map)
    '("t" . meow-till)
    '("T" . meow-till-expand)
    '("u" . "C-x u")
    '("U" . undo-redo)
    '("v" . expreg-expand)
    '("V" . expreg-contract)
    '("w" . meow-mark-symbol)
    '("W" . meow-mark-word)
    '("x" . meow-line)
    '("y" . meow-save)
    '("z" . meow-pop-selection)
    '("Z" . meow-cancel-selection)))

(defun my/meow-keypad-title(def)
  "Return DEF title without the local prefix-map naming marker."
  (let ((title (meow-keypad-get-title def)))
    (if (and (symbolp title)
          (not (commandp title))
          (or (and (fboundp title)
                (keymapp (symbol-function title)))
            (and (boundp title)
              (keymapp (symbol-value title))))
          (string-prefix-p "+" (symbol-name title)))
      (intern (substring (symbol-name title) 1))
      title)))

(use-package meow
  :demand t
  :custom
  (meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-use-cursor-position-hack t)
  (meow-use-clipboard t)
  (meow-goto-line-function 'consult-goto-line)
  (meow-keypad-leader-dispatch my/leader-map)
  (meow-keypad-leader-transparent 'normal)
  (meow-replace-state-name-list
    '((normal . "🅝 ")
       (motion . "🅜 ")
       (keypad . "🅚 ")
       (insert . "🅘 ")
       (beacon . "🅑 ")
       (passthrough . "🅟 ")))
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
       (?\) . round)
       (?\[ . square)
       (?\] . square)
       (?\; . comment)
       (?{ . curly)
       (?} . curly)
       (?\" . string)
       (?s . symbol)
       (?w . window)
       (?b . buffer)
       (?p . paragraph)
       (?l . line)
       (?d . defun)
       (?. . sentence)))
  :bind
  (:map mymacs-mode-map
    ("C-o" . meow-pop-to-global-mark))
  :config
  (setq meow-keypad-get-title-function #'my/meow-keypad-title)
  (add-to-list 'meow-mode-state-list '(vterm-mode . passthrough))
  (add-to-list 'meow-mode-state-list '(ghostel-mode . passthrough))
  (dolist (m '(magit-status-mode magit-log-mode magit-diff-mode magit-revision-mode magit-process-mode magit-popup-mode magit-mode))
    (add-to-list 'meow-mode-state-list (cons m 'motion)))
  (add-to-list 'meow-mode-state-list '(helpful-mode . motion))
  (my/meow-setup)
  (meow-global-mode 1)

  (defvar meow-passthrough-keymap (make-keymap)
    "Keymap for meow passthrough state.")

  (meow-define-state passthrough
    "Terminal passthrough state. All keys go to the terminal."
    :lighter " [T]"
    :keymap meow-passthrough-keymap)

  (meow-define-keys 'passthrough
    '("C-SPC" . meow-keypad)
    '("C-c ESC" . meow-insert-exit))
  )

;;; Meow Tree-sitter

(use-package meow-tree-sitter
  :after meow
  :config
  (meow-tree-sitter-register-defaults))

;;; Better repeat
(use-package repeat-fu
  :commands (repeat-fu-mode repeat-fu-execute)

  :config
  (setq repeat-fu-preset 'meow)

  :bind
  (:map mymacs-mode-map
    ("M-'" . #'repeat)) ;; normal emacs repeat

  :hook
  ((meow-mode)
    .
    (lambda ()
      (when (and (not (minibufferp)) (not (derived-mode-p 'special-mode)))
        (repeat-fu-mode)
        (define-key meow-normal-state-keymap (kbd "C-'") 'repeat-fu-execute)
        (define-key meow-insert-state-keymap (kbd "C-'") 'repeat-fu-execute)))))

;;; Lisp editing (paredit)
(use-package paredit
  :hook ((emacs-lisp-mode lisp-mode clojure-mode racket-mode scheme-mode)
          . paredit-mode)
  :config
  (my/def-command-with-selection paredit-forward +paredit-forward)
  (my/def-command-with-selection paredit-forward-down +paredit-forward-down)
  (my/def-command-with-selection paredit-backward +paredit-backward)
  (my/def-command-with-selection paredit-backward-up +paredit-backward-up)

  (with-eval-after-load 'meow
    (meow-define-keys 'normal
      '("M-l" . paredit-forward)
      '("M-L" . +paredit-forward)
      '("M-h" . paredit-backward)
      '("M-H" . +paredit-backward)
      '("M-j" . paredit-forward-down)
      '("M-k" . paredit-backward-up)
      '("M-s" . paredit-kill)
      '("M-m" . paredit-join-sexps)
      '("M-r" . paredit-raise-sexp))))


(provide 'core-keys)
;;; core-keys.el ends here
