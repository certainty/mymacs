;;; core-keys.el --- Keybinding infrastructure -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(eval-when-compile (require 'cl-lib))

(define-prefix-command '+files)

(define-prefix-command '+help)

(define-prefix-command '+org)

(define-prefix-command '+vc)
(define-prefix-command '+windows)

(define-prefix-command '+goto/act)
(define-prefix-command '+previous)
(define-prefix-command '+next)

(define-prefix-command '+workspaces)

(define-prefix-command '+ai)
(define-prefix-command '+agent-shell)

(define-prefix-command '+buffers)

(define-prefix-command '+do)

(define-prefix-command '+explore)

(define-prefix-command '+find)

(define-prefix-command '+notes)

(define-prefix-command '+language)

(define-prefix-command '+terminal)

(defvar-keymap my/leader-map :doc "The main leader map")
(defvar my/leader-bindings-registry (make-hash-table :test #'equal)
  "Registry of custom leader bindings.
Used to prevent accidental duplicate key assignments.")

(defun my/define-leader-key (map-name map key def)
  "Define KEY -> DEF in MAP (named MAP-NAME) with duplicate protection."
  (let ((binding-id (format "%s:%s" map-name key)))
    (when (gethash binding-id my/leader-bindings-registry)
      (user-error "Duplicate leader binding for %s" binding-id))
    (puthash binding-id t my/leader-bindings-registry)
    (define-key map (kbd key) def)))

(defmacro my/leader-bindings! (&rest groups)
  "Define leader bindings in GROUPS.
Each group has the shape: (MAP (KEY . DEF) ...)."
  `(progn
     ,@(cl-loop for group in groups
         for map-name = (car group)
         for bindings = (cdr group)
         append (cl-loop for binding in bindings
                  collect `(my/define-leader-key ',map-name ,map-name
                             ,(car binding) ,(cdr binding))))))

(defun my/tmr-prefix-dispatch ()
  "Open `tmr-prefix-map` when available, otherwise fallback to `tmr`."
  (interactive)
  (if (and (boundp 'tmr-prefix-map) (keymapp tmr-prefix-map))
    (set-transient-map tmr-prefix-map t)
    (call-interactively #'tmr)))

(defun +find-vc-changed-files ()
  "Show changed version-controlled files, scoped to current project when possible."
  (interactive)
  (if-let ((project (project-current nil)))
    (vc-dir (project-root project))
    (call-interactively #'vc-dir)))

;; This config uses a "two key Leader mappings" approach: first key describes
;; semantic group, second key executes an action. Both keys are usually chosen
;; to create some kind of mnemonic.
;; Example: `<Leader>f` groups "find" type of actions; `<Leader>ff` - find files.
;;
;; Anything that would require a deeper nesting is delegated to just be executed via M-x

;; Usually if there are global and local kinds of actions, lowercase second key
;; denotes local and uppercase - global.
;;
;; You can think of bigger letters == bigger scope
;; Example: `<Leader>fS` / `<Leader>fs` - find workspace/document LSP symbols.
;;
;;
;; In meow we dispatch to keypad by default with the leader so we are careful not
;; to bind prefixes that are already taken in keypad mode. Those are:
;;
;; x => C-x
;; h => C-h
;; c => C-c
;; m => M-
;; g => C-M-
;;
;;
;; TODO: simplify this to a two level map only as descibed above
;; My neovim setup can be found here https://raw.githubusercontent.com/david-krentzlin/mynvim/refs/heads/main/plugin/20_keymaps.lua
;; we don't want to replicate it exactly but we take inspiration
;;

(my/leader-bindings!
  (my/leader-map
    ("TAB" . (cons "Workspaces" +workspaces))
    ("a" . (cons "AI" +ai))
    ("b" . (cons "Buffers" +buffers))
    ("d" . (cons "Do" +do))
    ("e" . (cons "Explore" +explore))
    ("f" . (cons "Find" +find))
    ("j" . (cons "Jot" +notes))
    ("l" . (cons "Language" +language))
    ("t" . (cons "Terminal" +terminal))
    ("o" . (cons "Org GTD" +org))
    ("v" . (cons "VC" +vc))
    ("w" . (cons "Windows" +windows))
    ("," . (cons "Codex Start" 'agent-shell-openai-start-codex))
    ("/" . (cons "Find Ripgrep" 'consult-ripgrep))
    ("*" . (cons "Find Symbol" '+find-symbol))
    ("|" . (cons "Window Split Right" '+split-vertically))
    ("=" . (cons "Window Split Below" '+split-horizontally)))

  (+buffers
    ("b" . (cons "Switch" 'switch-to-buffer))
    (">" . (cons "Scale Text" 'text-scale-adjust))
    ("d" . (cons "Kill Current" '+kill-current))
    ("D" . (cons "Kill All" '+kill-all))
    ("p" . (cons "Popper Cycle" 'popper-cycle))
    ("r" . (cons "Revert" 'revert-buffer))
    ("z" . (cons "Bury" 'bury-buffer))
    ("P" . (cons "Project List" 'consult-project-buffer))
    ("K" . (cons "Project Kill" 'project-kill-buffers)))

  (+windows
    ("c" . (cons "Center" '+center-window))
    ("w" . (cons "Select" 'ace-window))
    ("x" . (cons "Swap" 'ace-swap-window))
    ("m" . (cons "Maximize" 'toggle-frame-maximized))
    ("h" . (cons "Left" 'windmove-left))
    ("j" . (cons "Down" 'windmove-down))
    ("k" . (cons "Up" 'windmove-up))
    ("l" . (cons "Right" 'windmove-right))
    ("d" . (cons "Delete" 'delete-window))
    ("s" . (cons "Split Below" 'split-window-below))
    ("v" . (cons "Split Right" 'split-window-right))
    ("o" . (cons "Only" 'delete-other-windows))
    ("=" . (cons "Balance" 'balance-windows))
    ("n" . (cons "Line Numbers" 'display-line-numbers-mode)))

  (+do
    ("c" . (cons "Timer" 'tmr))
    ("C" . (cons "Timer Presets" 'my/tmr-prefix-dispatch))
    ("d" . (cons "Dashboard" 'dashboard-open))
    ("o" . (cons "Toggle Format on Save" '+toggle-format-on-save))
    ("p" . (cons "Project Compile" 'project-compile))
    ("r" . (cons "RSS" 'elfeed)))

  (+terminal
    ("t" . (cons "Toggle Here" 'vterm-toggle-cd))
    ("T" . (cons "Toggle" 'vterm-toggle)))

  (+language
    ("d" . (cons "Diagnostics" 'consult-flymake))
    ("D" . (cons "Definition" 'xref-find-definitions))
    ("f" . (cons "Format" 'eglot-format))
    ("a" . (cons "Code Actions" 'eglot-code-actions))
    ("i" . (cons "Find Implementation" 'eglot-find-implementation))
    ("I" . (cons "Find Declaration" 'eglot-find-declaration))
    ("r" . (cons "Rename" 'eglot-rename))
    ("R" . (cons "References" 'xref-find-references))
    ("t" . (cons "Type Definition" 'eglot-find-typeDefinition))
    ("h" . (cons "Inlay Hints" 'eglot-inlay-hints-mode))
    ("q" . (cons "Shutdown" 'eglot-shutdown))
    ("C" . (cons "Connections" 'eglot-list-connections))
    ("E" . (cons "Reconnect" 'eglot-reconnect)))

  (+explore
    ("b" . (cons "Buffers" 'ibuffer))
    ("e" . (cons "Dired Here" 'dired-jump))
    ("i" . (cons "Init File" '+init-file))
    ("m" . (cons "Config Module" '+edit-config-module))
    ("n" . (cons "Notes Directory" '+browse-notes))
    ("N" . (cons "Managed Documents" '+browse-managed-documents))
    ("o" . (cons "Outline" 'imenu))
    ("O" . (cons "Org Directory" '+browse-org))
    ("v" . (cons "VC Root Log" 'vc-print-root-log))
    ("p" . (cons "Project Dired" 'project-dired))
    ("P" . (cons "Project Switch" 'project-switch-project)))

  (+find
    ("n" . (cons "Notes" 'consult-notes))
    ("N" . (cons "Notes Grep" '+consult-grep-notes))
    ("o" . (cons "Org Agenda" 'consult-org-agenda))
    ("O" . (cons "Org Ripgrep" '+org-ripgrep))
    ("f" . (cons "File Project" 'project-find-file))
    ("p" . (cons "Project Switch" 'project-switch-project))
    ("b" . (cons "Buffer Project" 'consult-project-buffer))
    ("B" . (cons "Buffer Global" 'consult-buffer))
    ("@" . (cons "Bookmark" 'consult-bookmark))
    ("c" . (cons "Commit Search" 'agitate-vc-git-commit-search))
    ("j" . (cons "Mark Global" 'consult-global-mark))
    ("l" . (cons "Buffer Line" 'consult-line))
    ("L" . (cons "Global Line Multi" 'consult-line-multi))
    ("m" . (cons "Modified Files" '+find-vc-changed-files))
    ("r" . (cons "Recent Files" 'consult-recent-file))
    ("v" . (cons "VC Log Search" 'vc-log-search))
    ("g" . (cons "VC Repo Grep" 'agitate-vc-git-grep))
    ("w" . (cons "Window Avy Word" 'my/avy-goto-char-timer-and-mark-word))
    ("x" . (cons "Project P-Search" 'p-search))
    ("q" . (cons "Quicklink" '+quicklink)))

  (+goto/act
    ("g" . (cons "Buffer Start" 'beginning-of-buffer))
    ("e" . (cons "Buffer End" 'end-of-buffer))
    ("h" . (cons "Line Start" 'move-beginning-of-line))
    ("j" . (cons "Next Line" 'next-line))
    ("k" . (cons "Prev Line" 'previous-line))
    ("l" . (cons "Line End" 'move-end-of-line))
    ("s" . (cons "Indent Start" 'back-to-indentation))
    ("?" . (cons "Helpful At Point" 'helpful-at-point))
    ("b" . (cons "Pop Mark" 'pop-to-mark-command))
    ("," . (cons "Embark DWIM" 'embark-dwim))
    ("." . (cons "Embark Act" 'embark-act)))

  (+next
    ("b" . (cons "Buffer" 'next-buffer))
    ("p" . (cons "Paragraph" 'forward-paragraph))
    ("d" . (cons "Diagnostic" 'flymake-goto-next-error))
    ("h" . (cons "Hunk" 'diff-hl-next-hunk))
    ("t" . (cons "TODO" 'hl-todo-next))
    ("s" . (cons "Smerge" 'smerge-next))
    ("m" . (cons "Set Mark" 'set-mark-command)))

  (+previous
    ("b" . (cons "Buffer" 'previous-buffer))
    ("p" . (cons "Paragraph" 'backward-paragraph))
    ("d" . (cons "Diagnostic" 'flymake-goto-prev-error))
    ("h" . (cons "Hunk" 'diff-hl-previous-hunk))
    ("t" . (cons "TODO" 'hl-todo-previous))
    ("s" . (cons "Smerge" 'smerge-prev))
    ("m" . (cons "Pop Mark" 'pop-to-mark-command)))

  (+workspaces
    ("TAB" . (cons "Switch/Create" 'tabspaces-switch-or-create-workspace))
    ("d" . (cons "Delete" 'tabspaces-close-workspace))
    ("b" . (cons "Buffer Switch" 'tabspaces-switch-to-buffer))
    ("k" . (cons "Kill Buffers" 'tabspaces-kill-buffers-close-workspace))
    ("." . (cons "Buffer and Tab" 'tabspaces-switch-buffer-and-tab)))

  (+org
    ("a" . (cons "Agenda Personal" '+personal-agenda))
    ("A" . (cons "Agenda Global" 'org-agenda))
    ("c" . (cons "Capture" 'org-capture))
    ("t" . (cons "Capture Task" '+capture-task))
    ("e" . (cons "Capture Event" '+capture-event))
    ("o" . (cons "Timer" 'tmr))
    ("O" . (cons "Timer Presets" 'my/tmr-prefix-dispatch))
    ("l" . (cons "Open Log" '+goto-log))
    ("T" . (cons "Open Tasks" '+goto-tasks)))

  (+notes
    ("j" . (cons "Capture Journal Note" '+capture-note))
    ("d" . (cons "Capture Decision" '+capture-decision))
    ("J" . (cons "Denote Find/Create" 'denote-open-or-create))
    ("n" . (cons "Denote New" 'denote))
    ("l" . (cons "Find Link" 'denote-find-link))
    ("i" . (cons "Insert Link" 'denote-link))
    ("b" . (cons "Backlinks" 'denote-backlinks))
    ("r" . (cons "Rename" 'denote-rename-file))
    ("R" . (cons "Rename Front Matter" 'denote-rename-file-using-front-matter)))

  (+ai
    ("s" . (cons "Shell" 'agent-shell))
    ("S" . (cons "Send Screenshot" 'agent-shell-send-screenshot))
    ("A" . (cons "New Shell" 'agent-shell-new-shell))
    ("p" . (cons "Compose Prompt" 'agent-shell-prompt-compose))
    ("t" . (cons "Toggle Shell" 'agent-shell-toggle))
    ("h" . (cons "Help" 'agent-shell-help-menu))
    ("r" . (cons "Review" 'agent-review))
    ("d" . (cons "Attention Dashboard" 'agent-shell-attention-dashboard))
    ("j" . (cons "Attention Jump" 'agent-shell-attention-jump))
    ("m" . (cons "Shell Manager" 'agent-shell-manager-toggle))
    ("." . (cons "GPTel Send" 'gptel-send)))

  (+vc
    ("s" . (cons "Status" 'magit-status))
    ("d" . (cons "Root Diff" 'vc-root-diff))
    ("v" . (cons "Next Action" 'vc-next-action))
    ("c" . (cons "Project Dir" 'project-vc-dir))
    ("." . (cons "VC Dir" 'vc-dir))
    ("f" . (cons "Update" 'vc-update))
    ("p" . (cons "Push" 'vc-push))
    ("l" . (cons "Log File" 'magit-log-buffer-file))
    ("L" . (cons "Log All" 'magit-log-all))))

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
