;; -*- lexical-binding: t; -*-

;;; Conventions
;; - user defined functions use my/ prefix
;; - private user defined functinos use my-- prefix
;; - user defined interactive functions use + prefix

;;; customization

(defvar-keymap mymacs-mode-map :doc "mymacs global keys")
(define-minor-mode mymacs-mode
  "My personal minor mode"
  :init-value t
  :global t
  :lighter " MyM"
  :keymap mymacs-mode-map)

(mymacs-mode 1) ;; enable immediately

(defgroup mymacs nil
  "User configuration for my emacs"
  :prefix "my/"
  :group 'emacs)

(defcustom my/user-name "john doe"
  "Full name"
  :type 'string
  :group 'mymacs)

(defcustom my/theme 'modus-vivendi-tinted
  "The theme to use"
  :type 'symbol
  :group 'mymacs)

(defcustom my/font "Maple Mono NF"
  "The font to use"
  :type 'string
  :group 'mymacs)

(defcustom my/font-height 116
  "The font height"
  :type 'number
  :group 'mymacs)

(defcustom my/font-weight 'light
  "The font weight"
  :type 'symbol
  :group 'mymacs)

(defcustom my/org-directory "~/org"
  "The main org directory"
  :type 'string
  :group 'mymacs)

(defcustom my/dev-ruby-enabled nil
  "Enable ruby programming support"
  :type 'boolean
  :group 'mymacs)

(defcustom my/dev-scala-enabled nil
  "Enable scala programming support"
  :type 'boolean
  :group 'mymacs)

;;; load custom file
(setopt custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing) 

;;; package setup
(require 'package)
(setopt package-archives
        '(("gnu" . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/"))
        package-archive-priorities
        '(("gnu" . 20)
          ("nongnu" . 10))
        package-install-upgrade-built-in t
        package-check-signature t ; don't trust anyone these days
	package-native-compile t
	package-quickstart t)

;;; UI
(use-package emacs
  :custom
  (use-short-answers t)
  (ring-bell-function 'ignore)
  (inhibit-startup-screen t)
  (inhibit-startup-message t)
  (initial-scratch-message nil)

  (modus-themes-custom-auto-reload t)
  (modus-themes-disable-other-themes t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-prompts '(extrabold italic))
  (modue-themes-paren-match '(bold intense))
  (modus-themes-org-blocks 'tinted-background)
  (modus-themes-completions
   '((matches . (extrabold underline))
     (selection . (semibold italic))))
  (modus-vivendi-tinted-palette-overrides
   '((bg-line-number-active bg-main)
     (bg-line-number-inactive bg-main)
     (bg-paren-match bg-magenta-intense)
     (bg-fringe bg-main)
     (fringe bg-main)
     (bg-space bg-main)))
  
  :bind
  (:map mymacs-mode-map
	("C-g" . +escape-dwim))
  
  :init
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (global-hl-line-mode -1)

  (load-theme my/theme)
  
  (set-face-attribute
   'default nil
   :font my/font
   :height my/font-height
   :weight my/font-weight)

  :preface
  (defun +escape-dwim ()
    (interactive)
    (cond
     ((region-active-p)
      (keyboard-quit))
     ((derived-mode-p 'completion-list-mode)
      (delete-completion-window))
     ((> (minibuffer-depth) 0)
      (abort-recursive-edit))
     (t
      (keyboard-quit)))))

;;;; keybindings setup

(use-package simple
  :init
  ;; free the keymap for next and previous in goto-map
  (keymap-set goto-map "n" nil)
  (keymap-set goto-map "p" nil))

;;;; line numbers
(use-package display-line-numbers
  :hook prog-mode)

;;;; outline
(use-package outline
	:hook ((prog-mode org-mode markdown-mode) . outline-minor-mode)
	:bind
	(:map mymacs-mode-map
				("C-<tab>" . outline-cycle)))

;;;; windows and buffers
(use-package window
  :hook
	(after-init . window-divider-mode)
  :init
  :bind
  (:map goto-map
	("n b" . next-buffer)
	("p b" . previous-buffer))
  (:repeat-map my/window-resize-repeat-map
	       ("{" . shrink-window-horizontally)
	       ("}" . enlarge-window-horizontally))
  (:repeat-map my/buffer-repeat-map
	       ("n" . next-buffer)
	       ("p" . previous-buffer))
  :custom
  ;; prefer splitting to the side
  (split-height-threshold nil)
  (split-width-threshold 80)
  (even-window-sizes nil)
  (window-combination-resize t)
	
;;;;; buffer arrangement
  (display-buffer-alist
   '(("\\*\\(Help\\|compilation\\|Occur\\|grep\\|Flymake.*\\|xref\\)\\*"
 
      (display-buffer-reuse-mode-window
       display-buffer-in-side-window)

      (side . right)
      (slot . 0)
      (window-width . 0.33)

      (mode . special-mode)
      
      (window-parameters
       . ((no-other-window . t)
          (no-delete-other-windows . t))))

     (".*"
      (display-buffer-reuse-window
       display-buffer-use-some-window
       display-buffer-pop-up-window)))))

(use-package ace-window
  :ensure t
  :hook (after-init . ace-window-display-mode)
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :bind
  (:map mymacs-mode-map
				("M-O" . other-window)
				("M-o" . ace-window)))

;;; minibuffer

(use-package minibuffer
  :hook (after-init . minibuffer-depth-indicate-mode)
  :custom
  (enable-recursive-minibuffers t))

(use-package savehist
  :hook after-init
  :custom
  (savehist-ave-minibuffer-history t)
  (savehist-autosave-interval 100))

;;; completion 

;;;; minibuffer  
(use-package vertico
  :ensure t
  :hook after-init
  :custom
  (vertico-cycle t)
  :config
  (vertico-multiform-mode)
  (add-to-list 'vertico-multiform-categories '(embark-keybinding grid)))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless)))

(use-package marginalia
  :ensure t
  :hook after-init)

;;;; in-buffer
(use-package completion-preview
  :hook (prog-mode org-mode markdown-mode)
  :bind
  (:map completion-preview-active-mode-map
	("M-n" . completion-preview-next-candidate)
	("M-p" . completion-preview-prev-candidate)
	("C-y" . completion-preview-insert)
	("M-y" . completion-preview-insert))
  :custom
  (completion-auto-select t)
  (completions-formt 'one-column)
  (completions-auto-help 'visible)
  (completions-max-height 20)
  (completion-ignore-case t)
  :config
  (push 'org-self-insert-command completion-preview-commands))

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions	'cape-dabbrev)
  (add-to-list 'completion-at-point-functions 'cape-file))

;;; editing
(use-package emacs
  :custom
  (kill-whole-line t)
  (set-mark-command-repeat-pop t)
  :bind
  (:map mymacs-mode-map
	("C-c >" . indent-rigidly-right-to-tab-stop)
	("C-c <" . indent-rigigly-left-to-tab-stop))
  (:map goto-map
	("@" . pop-to-mark-command)
	("m" . pop-global-mark))
  (:repeat-map my/mark-repeat-map
	       ("p" . pop-to-mark-command)
	       ("g" . pop-global-mark))
  :init
  (setq-default tab-width 2)
  (repeat-mode)
  (delete-selection-mode)
  (global-subword-mode)
  (save-place-mode))

;;;; handling pairs (quotes, parens, etc.)

(use-package elec-pair
  :custom
  (delete-pair-blink-delay 0.0)
  (delete-pair-push-mark t)
  :bind
  (:map mymacs-mode-map
	;; original binding is susped frame which I never want
	("C-z" . delete-pair)
	("C-Z" . electric-pair-delete-pair))
  :init
  (electric-pair-mode))

;;;; core editing / structural
(use-package emacs
  :bind
  (:map
	 mymacs-mode-map
	 ("C-c s" . my/sexp-prefix-map)
	 ("C-c )" . treesit-forward-sexp)
	 ("C-c (" . treesit-backward-sexp)
	 ("C-c [" . treesit-beginning-of-defun)
	 ("C-c ]" . treesit-end-of-defun))
  (:prefix-map
	 my/sexp-prefix-map
	 :prefix "C-c s"
	 ("m" . mark-sexp)
	 (")" . treesit-forward-sexp)
	 ("f" . treesit-forward-sexp)
	 ("F" . kill-sexp)
	 ("(" . treesit-backward-sexp)
	 ("b" . treesit-backward-sexp)
	 ("B" . backward-kill-sexp)
	 ("u" . treesit-up-list)
	 ("d" . treesit-down-list)
	 ("t" . transpose-sexps)
	 ("=" . indent-sexp)
	 (:repeat-map
		my/movement-repeat-map
		("p" . previous-line)
		("n" . next-line))
	 (:repeat -map
		my/sexp-repeat-map
		("f" . treesit-forward-sexp)
		("b" . treesit-backward-sexp)
		("u" . treesit-up-list)
		("d" . treesit-down-list)
		("t" . transpose-sexps))))

;;;; embark
(use-package embark
  :ensure t
  :custom
  (embark-prompter 'embark-completing-read-prompter)
  (prefix-help-command 'embark-prefix-help-command)
  
  :bind
  (:map mymacs-mode-map
				("C-." . embark-act)
				("C-," . embark-dwim))
  (:map minibuffer-mode-map
				("C-c C-c" . embark-collect)
				("C-c C-e" . embark-export)
				("C-c C-m" . embark-select)
				("C-c C-a" . embark-act-all))
  (:map minibuffer-local-map
				("C-c C-c" . embark-collect)
				("C-c C-e" . embark-export)
				("C-c C-m" . embark-select)
				("C-c C-a" . embark-act-all))
  
  :init
  (add-to-list 'display-buffer-alist
							 '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
								 nil
								 (window-parameter (mode-line-format . none)))))

(use-package embark-consult
  :after consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;; files

(use-package files
  :custom
  (make-backup-files nil)
  (auto-save-default nil)
  (create-lockfiles nil)
  (find-file-visit-truename t))

;;;; recent

(use-package recentf
  :hook after-init
  :custom
  (recentf-max-saved-items 1000)
  (redentf-exclude
   '(".gz" ".xz" ".zip"
     "COMMIT_EDITMSG"))
  :bind
  (:map mymacs-mode-map
				("C-x R" . recentf-open)))

;;;; dired

(use-package dired
  :custom
  (dired-listing-switches "-agho --group-directories-first")
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (global-auto-revert-non-file-buffers t)
  :bind
  (:map mymacs-mode-map
				("C-c e" . dired-jump)))

(use-package wdired
  :commands wdired-change-to-wdired-mode
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

;;; search

(use-package consult
  :ensure t
  :bind
  (:map goto-map
				("b" . consult-project-buffer)
				("o" . consult-recent-file)
				("r" . consult-bookmarks)
				("i".  consult-imenu)
				("M" . consult-mark)
				("d" . consult-flymake))
  (:map search-map			
				("M-s M-s" . consult-ripgrep)
				("M-s v" . consult-git-grep)))

;; wgrep no longer needed, since emacs 31 has grep-edit-mode

;;; projects
(use-package project
  :preface
  (defun +project-find-symbol ()
    "Search for symbol under point in whole project"
    (interactive)
    (consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol)))
  :bind
  (:map goto-map
				("f" . project-find-file))
  (:map search-map
				("/" . +project-find-symbol)))

(use-package ansi-color
	:hook (completion-filter . ansi-color-compilation-filter))

;;; GTD
(use-package org
  :custom
  (org-directory (file-truename (expand-file-name my/org-directory)))
	(org-pretty-entities t)
	(org-startup-folded t)
	(org-hide-leading-stars t)
	(org-hide-emphasis-marker nil)
	(org-M-RET-may-split-lines nil)
	(org-insert-heading-respect-content t)
	(org-fontify-quote-and-verse-blocks t)
  
	;; Indentation
	(org-auto-align-tags t)
  (org-adapt-indentation nil)
  (org-startup-indented t)
  (org-src-preserve-indentation t)

	;; Logging
  (org-log-done 'time)
  (org-log-into-drawer t)
	
	;; Refile
  (org-refile-targets '((nil :maxlevel . 5)
                        (org-agenda-files :maxlevel . 5)))
  (org-outline-path-complete-in-steps nil)
  (org-refile-use-outline-path t)

	;; Sequences
	(org-todo-keywords
	 '((sequence "TODO(t)" "WAIT(w!)" "|" "CANCELLED(c!)" "DONE(d!)")
		 (sequence "EVT(e)" "|" "CANCELLED(c!)" "DONE(d!)")
		 (sequence "|" "DECISION(c)")))
	(org-use-fast-todo-selection 'expert)
	(org-capture-templates
   '(("t" "Task" entry (file "tasks.org")
      "* TODO %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:"
      :prepend t)
     ("n" "Note" entry (file+olp+datetree "log.org")
      "* %<%H:%M> %?\n:PROPERTIES:\n:CAPTURED: %T\n:END:"
      :tree-type week)

     ("d" "Decision" entry (file+olp+datetree "log.org")
      "* DECISION %?\n:PROPERTIES:\n:CAPTURED: %T\n:END:"
      :tree-type week)
		 
     ("e" "Event" entry (file+olp+datetree "log.org")
      "* EVT %? :event:\n:PROPERTIES:\n:CAPTURED: %U\n:END:"
      :tree-type week
      :prepend t)))

	:bind
	(:map mymacs-mode-map
				("C-c o" . my/org-prefix-map))
	(:prefix-map
	 my/org-prefix-map
	 :prefix "C-c o"
	 ("a" . org-agenda)
	 ("o" . org-capture))
							 
				

	:config
  ;; Fixed-pitch for code/tables in variable-pitch org docs
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

;;; Writing
(use-package ispell
  :hook ((text-mode . flyspell-mode)
	 (prog-mode . flyspell-prog-mode))
  :custom
  (ispell-program-name "hunspell"))

;;; extra writing denote


;;; Programming
(use-package eglot
	:bind
	(:map eglot-mode-map
				("C-c l" . my/eglot-prefix-map))
	(:prefix-map
	 my/eglot-prefix-map
	 :prefix "C-c l"
	 ("a" . eglot-code-actions)
	 ("d" . xref-find-definitions)
	 ("r" . eglot-rename)
	 ("h" . eldoc)
	 ("f" . eglot-format-buffer)
	 ("F" . eglot-format)
	 ("C" . flymake-show-project-diagnostics)
	 ("c" . consult-flymake)))

;;;; diagnostics
(use-package flymake
  :bind
  (:map goto-map
	("n e" . flymake-goto-next-error)
	("p e" . flymake-goto-prev-error))
  (:map flymake-mode-map
	("M-n" . flymake-goto-next-error)
	("M-p" . flymake-goto-prev-error)))

;;;; ruby
(use-package ruby-ts-mode
  :if my/dev-ruby-enabled
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook ((ruby-ts-mode . eglot-ensure))
  :bind
  (:map ruby-ts-mode-map
        ("C-c t t" . +ruby-test-dwim)
        ("C-c t o" . +ruby-test-file)
        ("C-c t r" . +ruby-rspec-dwim)
        ("C-c t m" . +ruby-minitest-dwim))
  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil)
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(ruby-ts-mode . ("ruby-lsp")))))

;;;; go lang
(use-package go-ts-mode
  :if my/dev-go-enabled
  :hook (go-ts-mode . eglot-ensure)
  :init
  (setq-default go-ts-mode-indent-offset 4)
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(go-ts-mode . ("gopls")))))


;;;; scala 
(use-package scala-ts-mode
  :mode ("\\.scala\\'" "\\.sc\\'" "\\.sbt\\'")
  :hook (scala-ts-mode . eglot-ensure)
  :custom
  (scala-ts-mode-indent-offset 2)
  :bind
  (:map scala-ts-mode-map
	("C-c C-t" . +scala-test-only))

  :config
	;;; Metals LSP configuration
  (defun my/scala-metals-contact ()
    "Build the Eglot contact spec for Metals."
    (append
     (list my/scala-metals-command)
     (mapcar (lambda (arg) (format "-J%s" arg)) my/scala-metals-java-options)
     my/scala-metals-server-arguments
     (list :initializationOptions my/scala-metals-initialization-options)))

  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 `(scala-ts-mode . ,(my/scala-metals-contact)))))

;;;; lisp

