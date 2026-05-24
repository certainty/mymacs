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
  :lighter " Mymmacs"
  :keymap mymacs-mode-map)

(mymacs-mode 1) ;; enable immediatly

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

(defcustom my/dev-ruby-enabled nil
	"Enable ruby programming support"
	:type 'boolean
	:group 'mymacs)

(defcustom my/dev-scala-enabled nil
	"Enable scala programming support"
	:type 'boolean
	:group 'mymacs)

(defcustom my/dev-go-enabled nil
	"Enable go programming support"
	:type 'boolean
	:group 'mymacs)

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

;;; core ui
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
    "Do-What-I-Mean behaviour for a general `keyboard-quit'.
   - When the region is active, disable it.
   - When a minibuffer is open, close it.
   - When the Completions buffer is selected, close it.
   - Otherwise regular `keyboard-quit'."
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

;;; core ui / line numbers
(use-package display-line-numbers
	:hook prog-mode)

;;; core ui / windows and buffers
(use-package window
	:hook (after-init . window-divider-mode)
	:custom
	(split-height-threshold 60)
	(split-width-threshold 60)
		;;; buffer arrangement
	(display-buffer-alist
      '(("\\*\\(Help\\|compilation\\|Async-execute-command\\|Occur\\|grep\\|Flymake.*\\)\\*"
         (display-buffer-in-side-window)
         (side . right)
         (slot . 0)
         (window-width . 0.35)
         (select . t))
        ("\\*dired\\*"
         (display-buffer-same-window))
        (".*"
         (display-buffer-reuse-window display-buffer-same-window display-buffer-pop-up-window)
         (window-width . 0.5)))))

(use-package ace-window
	:ensure t
	:hook (after-init . ace-window-display-mode)
	:custom
	(aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
	:bind
	(:map mymacs-mode-map
				("M-o" . 'ace-window)))

;;; core ui / minibuffer

(use-package minibuffer
	:hook (after-init . minibuffer-depth-indicate-mode)
	:custom
	(enable-recursive-minibuffers t))

(use-package savehist
	:hook after-init
	:custom
	(savehist-ave-minibuffer-history t)
	(savehist-autosave-interval 100))

;; core ui / completion minibuffer

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

;; core ui / completion in-buffer
(use-package completion-preview
	:hook (prog-mode org-mode markdown-mode)
	:bind
	(:map completion-preview-active-mode-map
				("M-n" . 'completion-preview-next-candidate)
				("M-p" . 'completion-preview-prev-candidate)
				("C-y" . 'completion-preview-insert)
				("M-y" . 'completion-preview-insert)))

;;; core editing / base
(use-package emacs
  :custom
  (kill-whole-line t)
  :init
  (repeat-mode)
	(setq-default tab-width 2))

;;; core editing / handling pairs
(use-package elec-pair
  :custom
  (delete-pair-blink-delay 0.0)
  (delete-pair-push-mark t)
  :bind
  (:map mymacs-mode-map
	;; original binding is susped frame which I never want
	("C-z" . 'delete-pair)
	("C-Z" . 'electric-pair-delete-pair))
  :init
  (electric-pair-mode))


;;; core editing / avy
(use-package avy
	:ensure t
	:bind
	(:map mymacs-mode-map
				("M-g l" . 'avy-goto-line)
				("M-g j" . 'avy-goto-char-timer)))

;;; core editing / embark
(use-package embark
	:ensure t
	:custom
	(embark-prompter 'embark-completing-read-prompter)
	(prefix-help-command 'embark-prefix-help-command)
	
	:bind
	(:map mymacs-mode-map
				("C-." . 'embark-act)
				("C-," . 'embark-dwim))
	(:map minibuffer-mode-map
				("C-c C-c" . 'embark-collect)
				("C-c C-e" . 'embark-export)
				("C-c C-m" . 'embark-select)
				("C-c C-a" . 'embark-act-all))
	(:map minibuffer-local-map
				("C-c C-c" . 'embark-collect)
				("C-c C-e" . 'embark-export)
				("C-c C-m" . 'embark-select)
				("C-c C-a" . 'embark-act-all))
	
	:init
	(add-to-list 'display-buffer-alist
							 '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
								 nil
								 (window-parameter (mode-line-format . none)))))

(use-package embark-consult
	:after consult
	:ensure t
	:hook (embark-collect-mode . consult-preview-at-point-mode))

;;; core files 
(use-package files
  :custom
  (make-backup-files nil)
  (auto-save-default nil)
  (create-lockfiles nil)
	(find-file-visit-truename t))

;;; core files / recent
(use-package recentf
  :hook after-init
	:custom
	(recentf-max-saved-items 1000)
	(redentf-exclude
	 '(".gz" ".xz" ".zip"
		 "COMMIT_EDITMSG"))
  :bind
  (:map mymacs-mode-map
				("C-x R" . 'recentf-open)))

;; core files / dired
(use-package dired
	:custom
	(dired-listing-switches "-agho --group-directories-first")
	(dired-recursive-copies 'always)
	(dired-recursive-deletes 'always)
	(global-auto-revert-non-file-buffers t)
	:bind
	(:map mymacs-mode-map
				("C-c C-e" . dired-jump)))

(use-package wdired
	:commands wdired-change-to-wdired-mode
	:custom
	(wdired-allow-to-change-permissions t)
	(wdired-create-parent-directories t))

;; core search

(use-package consult
	:ensure t
	:bind
	(:map goto-map
				("b" . 'consult-project-buffer)
				("o" . 'consult-recent-file)
				("r" . 'consult-bookmarks)
				("i". 'consult-imenu)
				("m" . 'consult-mark)
				("d" . 'consult-flymake))
	(:map search-map			
				("M-s M-s" . 'consult-ripgrep)
				("M-s v" . 'consult-git-grep)))

(use-package wgrep
	:ensure t)

;;; extra projects

(use-package project
	:preface
	(defun +project-find-symbol ()
		"Search for symbol under point in whole project"
		(interactive)
		(consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol)))
	:bind
	(:map goto-map
				("f" . 'project-find-file))
	(:map search-map
				("/" . '+project-find-symbol)))

;;; etra gtd
(use-package org)

;;; extra writing
(use-package ispell
	:hook ((text-mode . flyspell-mode)
				 (prog-mode . flyspell-prog-mode))
	:custom
	(ispell-program-name "hunspell"))

;;; extra writing denote


;;; extra programming
(use-package eglot)

(use-package flymake
	:bind
	(:map flymake-mode-map
				("M-n" . 'flymake-goto-next-error)
				("M-p" . 'flymake-goto-prev-error)))

;;; extra programming ruby
(use-package ruby-ts-mode
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


;;; custom file
(setopt custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing) 
