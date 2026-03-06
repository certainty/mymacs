;;; core-keys.el --- Keybinding infrastructure -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(define-prefix-command '+workspaces)
(define-prefix-command '+workspaces-search)
(define-prefix-command '+workspaces-goto)

(define-prefix-command '+ai)

(define-prefix-command '+config)
(define-prefix-command '+config-search)
(define-prefix-command '+config-goto)

(define-prefix-command '+notes)
(define-prefix-command '+notes-search)
(define-prefix-command '+notes-goto)

(define-prefix-command '+files)
(define-prefix-command '+buffers)

(define-prefix-command '+help)
(define-prefix-command '+help-search)

(define-prefix-command '+org)
(define-prefix-command '+org-search)
(define-prefix-command '+org-goto)

(define-prefix-command '+project)
(define-prefix-command '+project-search)
(define-prefix-command '+project-goto)

(define-prefix-command '+toggle)

(define-prefix-command '+vc)
(define-prefix-command '+vc-search)
(define-prefix-command '+vc-goto)
(define-prefix-command '+windows)
(define-prefix-command '+do)

(define-prefix-command '+goto/act)
(define-prefix-command '+search)
(define-prefix-command '+previous)
(define-prefix-command '+next)

(defvar-keymap my/leader-map :doc "The main leader map")

(define-key my/leader-map (kbd "TAB") (cons "+workspaces" +workspaces))
(define-key my/leader-map (kbd "a") (cons "+ai" +ai))
(define-key my/leader-map (kbd "n") (cons "+notes"  +notes))
(define-key my/leader-map (kbd "d") (cons "+do" +do))
(define-key my/leader-map (kbd "F") (cons "+files" +files))
(define-key my/leader-map (kbd "b") (cons "+buffers" +buffers))
(define-key my/leader-map (kbd "o") (cons "+org" +org))
(define-key my/leader-map (kbd "p") (cons "+projects" +project))
(define-key my/leader-map (kbd "s") (cons "+search" +search))
(define-key my/leader-map (kbd "G") (cons "+goto/act" +goto/act))
(define-key my/leader-map (kbd "t") (cons "+toggle" +toggle))
(define-key my/leader-map (kbd "v") (cons "+vcs" +vc))
(define-key my/leader-map (kbd "w") (cons "+windows" +windows))


(when (my/context-work-p)
  (define-key my/leader-map (kbd ",") (cons "agent" 'agent-shell-toggle)))

;; search prefixes
(define-key +search (kbd "n") (cons "+notes" +notes-search))
(define-key +search (kbd "c") (cons "+config" +config-search))
(define-key +search (kbd "o") (cons "+org" +org-search))
(define-key +search (kbd "p") (cons "+project" +project-search))
(define-key +search (kbd "TAB") (cons "+workspaces" +workspaces-search))
(define-key +search (kbd "v") (cons "+vc" +vc-search))
(define-key +search (kbd "h") (cons "+help" +help-search))

;; goto prefixes
(define-key +goto/act (kbd "n") (cons "+notes" +notes-goto))
(define-key +goto/act (kbd "c") (cons "+config" +config-goto))
(define-key +goto/act (kbd "o") (cons "+org" +org-goto))
(define-key +goto/act (kbd "p") (cons "+project" +project-goto))
(define-key +goto/act (kbd "TAB") (cons "+workspaces" +workspaces-goto))
(define-key +goto/act (kbd "v") (cons "+vc" +vc-goto))

(defvar-keymap my/surround-map :doc "Surround/embrace prefix map.")

(use-package expand-region)
(use-package expreg)

(use-package embrace
  :demand t
  :after meow
  :config
  (keymap-set my/surround-map "y" #'embrace-add)
  (keymap-set my/surround-map "c" #'embrace-change)
  (keymap-set my/surround-map "d" #'embrace-delete))

(use-package avy)

(use-package meow
  :demand t
  :preface
  (cl-defmacro my/with-selection (&body body)
    `(progn
       (unless (region-active-p)
         (set-mark-command nil))
       ,@body))

  (defmacro my/def-command-with-selection (original-cmd new-cmd)
    `(defun ,new-cmd ()
       (interactive)
       (my/with-selection
         (call-interactively #',original-cmd))))

  (defun my/avy-with-selection ()
    (interactive)
    (my/with-selection
      (call-interactively #'avy-goto-char)))

  (defun my/insert-at-end-of-line ()
    (interactive)
    (meow-line 1)
    (meow-append))

  (defun my/insert-at-beginning-of-indentation ()
    (interactive)
    (back-to-indentation)
    (meow-insert))

  (defun my/avy-goto-char-timer-and-mark-word ()
    "Use `avy-goto-char-timer', then select the word at the jumped-to location.

If the avy command is aborted with `C-g', do nothing."
    (interactive)
    (let ((orig (point)))
      (condition-case nil
        (progn
          (call-interactively #'avy-goto-char-timer)
          (when (/= (point) orig)
            (let ((bounds (bounds-of-thing-at-point 'word)))
              (when bounds
                (goto-char (car bounds))
                (set-mark (cdr bounds))
                (activate-mark)))))
        (quit
          (goto-char orig)))))

  :custom

  (meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-use-cursor-position-hack t)
  (meow-use-clipboard t)
  (meow-goto-line-function #'consult-goto-line)
  (meow-keypad-leader-transparent 'normal)
  (meow-keypad-leader-dispatch my/leader-map)
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

  (meow-replace-state-name-list
    '((normal . "🅝 ")
       (motion . "🅜 ")
       (keypad . "🅚 ")
       (insert . "🅘 ")
       (beacon . "🅑 ")))
  (meow-selection-command-fallback
    '((meow-change . meow-change-char)
       (meow-kill . meow-delete) ; so we can have d as the default binding for delete
       (meow-save . kill-ring-save)
       (meow-cancel-selection . keyboard-quit)
       (meow-pop-selection . meow-pop-grab)
       (meow-beacon-change . meow-beacon-change-char)
       (meow-expand . meow-digit-argument)))



  :bind
  (:map mymacs-mode-map
    ("C-o" . meow-pop-to-global-mark))

  (:map my/leader-map
    (";" . meow-comment))

  (:map +next
    ("b" . next-buffer)
    ("p" . forward-paragraph)
    ("d" . end-of-defun)
    ("d" . flymake-goto-next-error)
    ("h" . diff-hl-next-hunk)
    ("t" . hl-todo-next)
    ("s" . smerge-next)
    ("m" . set-mark-command))

  (:map +previous
    ("b" . previous-buffer)
    ("p" . backward-paragraph)
    ("d" . beginning-of-defun)
    ("d" . flymake-goto-prev-error)
    ("h" . diff-hl-previous-hunk)
    ("t" . hl-todo-previous)
    ("s" . smerge-prev)
    ("m" . pop-to-mark-command))

  (:map +search
    ("w" . my/avy-goto-char-timer-and-mark-word))

  (:map +goto/act
    ("g" . beginning-of-buffer) ;helix
    ("e" . end-of-buffer) ; helix
    ("h" . move-beginning-of-line)
    ("j" . next-line)
    ("k" . previous-line)
    ("l" . move-end-of-line)
    ("s" . back-to-indentation)
    ("d" . xref-find-definitions)
    ("D" . eglot-find-declaration)
    ("y" . eglot-find-typeDefinition)
    ("r" . xref-find-references)
    ("i" . eglot-find-implementation)
    ("x" . xref-find-apropos)
    ("a" . eglot-code-actions)
    ("R" . eglot-rename)
    ("?" . helpful-at-point)
    ("b" . pop-to-mark-command)
    ("S" . yasnippet-insert-snippet)
    ("," . embark-dwim)
    ("." . embark-act))

  :config
  (repeat-mode 1) ;; enable repeat maps


  (with-eval-after-load 'org
    (modify-syntax-entry ?@ "_" org-mode-syntax-table))

  (use-package meow-tree-sitter
    :demand t
    :straight (meow-tree-sitter :type git :host github :repo "skissue/meow-tree-sitter")
    :config
    (meow-tree-sitter-register-defaults))



  (defun my/meow-setup ()
    (meow-motion-define-key
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

      ;; Utilities
      '("/" . meow-visit)

      ;; Arguments / repeat
      '("-" . negative-argument)
      ;;'("'" . repeat) -- handled by repeat-fu

      ;; Thing helpers
      '("," . meow-inner-of-thing)
      '("." . meow-bounds-of-thing)

      '("<" . meow-beginning-of-thing)
      '(">" . meow-end-of-thing)

      '(")" . meow-forward-slurp)
      '("(" . meow-backward-slurp)
      '("{" . meow-backward-barf)
      '("}" . meow-forward-barf)

      '("%" . meow-block)
      '("$" . meow-to-block)

      '("^" . meow-join)
      '("%" . mark-whole-buffer)


      ;; Selection control / maps
      '("<escape>" . meow-cancel-selection)
      `("[" . ,+previous) ;; helix [ prefix
      `("]" . ,+next) ;; helix ] prefix
      '("~" . meow-reverse)
      '(";" . meow-comment)

      '("a" . meow-append)
      '("A" . my/insert-at-end-of-line)
      '("b" . meow-back-symbol)
      '("B" . meow-back-word)
      '("c" . meow-change)
      ;;'("C" . ignored)
      '("d" . meow-kill)
      '("D" . meow-kill-whole-line)
      '("e" . meow-next-symbol)
      '("E" . meow-next-word)
      '("f" . meow-find)
      '("F" . my/avy-with-selection)
      `("g" . ,+goto/act)  ;; helix g prefix
      '("G" . meow-grab)
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
      '("M" . meow-block-expand)
      '("n" . meow-search)
      ;;'("N" . ignored)
      '("o" . meow-open-below)
      '("O" . meow-open-above)
      '("p" . meow-yank)
      ;;'("P" . ignored)
      '("q" . meow-quit)
      ;;'("Q" . ignored)
      '("r" . meow-replace)
      '("R" . meow-swap-grab)
      `("s" . ,+search)
      `("S" . ,my/surround-map)
      '("t" . meow-till)
      '("T" . meow-till-expand)
      '("u" . "C-x u")
      '("U" . undo-redo)
      '("v" . expreg-expand)
      '("V" . expreg-contract)
      '("w" . meow-mark-symbol)
      '("W" . meow-mark-word)
      '("x" . meow-line)
      ;;'("X" . ignored)
      '("y" . meow-save)
      ;;'("Y" . ignored)
      '("z" . meow-pop-selection)
      '("Z" . meow-cancel-selection)
      ))

  (add-to-list 'meow-mode-state-list '(vterm-mode . insert))
  (add-to-list 'meow-mode-state-list '(eshell-mode . insert))
  (dolist (m '(magit-status-mode
                magit-log-mode
                magit-diff-mode
                magit-revision-mode
                magit-process-mode
                magit-popup-mode
                magit-mode))
    (add-to-list 'meow-mode-state-list (cons m 'motion)))
  (add-to-list 'meow-mode-state-list '(helpful-mode . motion))

  (my/meow-setup)
  (meow-global-mode 1))


(use-package repeat-fu
  :after meow
  :commands (repeat-fu-mode repeat-fu-execute)
  :init
  (defun my/repeat-fu-enable ()
    (when (and (not (minibufferp))
            (not (derived-mode-p 'special-mode)))
      (repeat-fu-mode 1)))
  :config
  (setq repeat-fu-preset 'meow)
  (keymap-set meow-normal-state-keymap "'" #'repeat-fu-execute)
  (keymap-set meow-insert-state-keymap "C-'" #'repeat-fu-execute)
  :hook
  (meow-mode . my/repeat-fu-enable))

(use-package which-key
  :straight (:type built-in)
  :hook (after-init . which-key-mode)
  :custom
  (which-key-sort-order 'which-key-prefix-then-key-order)
  (which-key-max-display-columns 10)
  (which-key-show-early-on-C-h t)
  (which-key-show-prefix nil)
  (which-key-idle-delay .75)
  (which-key-idle-secondary-delay 0.05)
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-setup-minibuffer)
  (which-key-separator " • ")
  (which-key-prefix-prefix nil)

  :config
  (with-eval-after-load 'meow
    (defun my/meow-keypad-which-key (keymap)
      (when (and (featurep 'which-key)
              (fboundp 'which-key--show-keymap)
              (keymapp keymap))
        (which-key--show-keymap "Leader" keymap nil nil t)))

    (defun my/meow-keypad-clear-which-key ()
      (when (and (featurep 'which-key)
              (fboundp 'which-key--hide-popup-ignore-command))
        (which-key--hide-popup-ignore-command)))

    (setq meow-keypad-describe-keymap-function #'my/meow-keypad-which-key
      meow-keypad-clear-describe-keymap-function #'my/meow-keypad-clear-which-key)))


(when (eq system-type 'darwin)
  (setopt mac-command-modifier 'super
    mac-option-modifier 'meta
    mac-right-option-modifier 'none))

(provide 'core-keys)
;;; core-keys.el ends here
