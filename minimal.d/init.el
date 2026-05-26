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

(defcustom my/user-name "john doe" "Full name" :type 'string :group 'mymacs)
(defcustom my/theme 'modus-vivendi-tinted "The theme to use" :type 'symbol :group 'mymacs)
(defcustom my/font "Maple Mono NF" "The font to use" :type 'string :group 'mymacs)
(defcustom my/font-height 110 "The font height" :type 'number :group 'mymacs)
(defcustom my/font-weight 'light "The font weigh" :type 'symbol :group 'mymacs)
(defcustom my/org-directory "~/org" "The main org directory" :type 'string :group 'mymacs)
(defcustom my/org-tag-alist nil "The tag quick keys" :type '(alist :key-type string :value-type character))
(defcustom my/scala-metals-java-options nil "Java options for Metals." :type '(repeat string) :group 'mymacs)
(defcustom my/scala-metals-server-arguments nil "Arguments for metals" :type '(repeat string) :group 'mymacs)
(defcustom my/scala-metals-initialization-options
  '(:isHttpEnabled "on")
  "Initialization options sent to Metals."
  :type 'plist
  :group 'mymacs)

;;;; load custom file
(setopt custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; Packages
(require 'package)
(require 'use-package)
(setopt package-archives
        '(("gnu" . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")
          ("melpa" . "https://melpa.org/packages/"))
        package-archive-priorities
        '(("gnu" . 20)
          ("nongnu" . 10)
          ("melpa" . 0))

				package-pinned-packages
        '((ace-window . "gnu")
          (cape . "gnu")
          (consult . "gnu")
          (embark . "gnu")
          (embark-consult . "gnu")
          (scala-ts-mode . "melpa")
          (vterm . "melpa")
          (vterm-toggle . "melpa"))
				
        package-install-upgrade-built-in t
        ;; MELPA packages are generally unsigned, so keep GNU/Nongnu signature
        ;; verification where available but allow explicitly reviewed MELPA use.
        package-check-signature 'allow-unsigned
        package-native-compile t
        package-quickstart t
        network-security-level 'high
        gnutls-verify-error t)

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
  (modus-themes-paren-match '(bold intense))
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
	:hook ((prog-mode . outline-minor-mode)
				 (org-mode . outline-minor-mode)
				 (markdown-mode . outline-minor-mode))
	:bind
	(:map mymacs-mode-map
				("C-<tab>" . outline-cycle)))

;;;; windows and buffers

(defvar my/side-window-config
	'((display-buffer-reuse-mode-window display-buffer-in-side-window)
    (side . right)
    (slot . 0)
    (window-width . 0.33)
    (mode . special-mode)
    (window-parameters . ((no-other-window . t) (no-delete-other-windows . t)))))

(defvar my/bottom-window-config
  '((display-buffer-reuse-mode-window display-buffer-in-side-window)
    (side . bottom)
    (slot . 0)
    (window-height . 0.25)
    (mode . special-mode)
    (window-parameters . ((no-other-window . t) (no-delete-other-windows . t)))))

(use-package window
  :bind
	(:map mymacs-mode-map
				("C-c |" . split-window-right))
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
	(window-divider-default-right-width 7)
	(window-divider-default-bottom-width 7)

  ;;;;; buffer arrangement
  (display-buffer-alist
   `(("\\*Capture\\*" . ,my/bottom-window-config)
     ("\\*\\(Help\\|compilation\\|Occur\\|grep\\|Flymake.*\\|xref\\)\\*" . ,my/side-window-config)
     (".*"
      (display-buffer-reuse-window
       display-buffer-use-some-window
       display-buffer-pop-up-window))))

	:config
	(set-face-foreground 'window-divider (face-background 'default))
	(dolist (f '(window-divider-first-pixel window-divider-last-pixel))
		(set-face-foreground f "#4f5f73"))
	:init
	(window-divider-mode))

(use-package ace-window
	:ensure t
	:commands (ace-window)
	:custom
	(aw-keys '(?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l))
	:bind
	(:map mymacs-mode-map
				("M-o" . ace-window)
				("M-O" . other-window)))

;;;; minibuffer
(use-package minibuffer
  :custom
  (enable-recursive-minibuffers t)
	:init
	(minibuffer-depth-indicate-mode))

(use-package savehist
  :custom
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100)
	:init
	(savehist-mode))

;;; Completion

;;;; minibuffer
(use-package minibuffer
	:custom
	(completion-sort 'historical)
	(completion-eager-update t)
	(completion-auto-select t)
	(completions-auto-help 'visible)
    (completions-max-height 20)
    (completion-ignore-case t)
	(completions-format 'vertical)
	(completion-styles '(substring partial-completion flex basic)))

(use-package icomplete
	:custom
	(icomplete-delay-completions-threshold 0)
	(icomplete-max-delay-chars 0)
	(icomplete-scroll t)
	(icomplete-prospects-height 10)
	(icomplete-show-matches-on-no-input t)
	:bind
	(:map icomplete-minibuffer-map
				("C-n" . icomplete-forward-completions)
				("C-p" . icomplete-backward-completions)
				("C-y" . icomplete-force-complete-and-exit)
				("C-j" . icomplete-force-complete))
	:init
	(icomplete-vertical-mode 1))

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions	'cape-dabbrev)
  (add-to-list 'completion-at-point-functions 'cape-file))

;;; Editing
(use-package emacs
  :custom
  (kill-whole-line t)
  (set-mark-command-repeat-pop t)
  :bind
  (:map mymacs-mode-map
				("C-c >" . indent-rigidly-right-to-tab-stop)
				("C-c <" . indent-rigidly-left-to-tab-stop))
  (:map goto-map
				("<" . pop-to-mark-command)
				("m" . pop-global-mark))
  (:repeat-map my/mark-repeat-map
							 ("<" . pop-to-mark-command)
							 ("m" . pop-global-mark))
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
	 ("=" . indent-sexp))
	(:repeat-map
	 my/movement-repeat-map
	 ("p" . previous-line)
	 ("n" . next-line))
	(:repeat-map
	 my/sexp-repeat-map
	 ("f" . treesit-forward-sexp)
	 ("b" . treesit-backward-sexp)
	 ("u" . treesit-up-list)
	 ("d" . treesit-down-list)
	 ("t" . transpose-sexps)))

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
	(:map icomplete-minibuffer-map
				("C-." . embark-act)
				("C-," . embark-dwim)
				("C-c c" . embark-collect)
				("C-c e" . embark-export)
				("C-c m" . embark-select)
				("C-c a" . embark-act-all))
  (:map minibuffer-mode-map
				("C-c c" . embark-collect)
				("C-c e" . embark-export)
				("C-c m" . embark-select)
				("C-c a" . embark-act-all))
  (:map minibuffer-local-map
				("C-c c" . embark-collect)
				("C-c e" . embark-export)
				("C-c m" . embark-select)
				("C-c a" . embark-act-all))

  :init
  (add-to-list 'display-buffer-alist
							 '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
								 nil
								 (window-parameter (mode-line-format . none)))))

(use-package embark-consult
  :after consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;; Files

(use-package files
  :custom
  (make-backup-files nil)
  (auto-save-default nil)
	(auto-save-default nil)
  (create-lockfiles nil)
  (find-file-visit-truename t))

;;;; recent

(use-package recentf
  :custom
  (recentf-max-saved-items 1000)
  (recentf-exclude
   '(".gz" ".xz" ".zip"
     "COMMIT_EDITMSG"))
  :bind
  (:map mymacs-mode-map
				("C-x R" . recentf-open))
	:init
	(recentf-mode))

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

;;; Search

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
				("/" . consult-ripgrep)
				("v" . consult-git-grep)))

;; wgrep no longer needed, since emacs 31 has grep-edit-mode

;;; Projects
(use-package project
  :preface
  (defun +project-find-symbol ()
    "Search for symbol under point in whole project"
    (interactive)
    (consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol)))
  :custom
  (project-vc-extra-root-markers '(".project.el"))
  :bind
	(:map mymacs-mode-map
				("C-c p" . project-switch-project)
				("C-c v" . project-vc-dir))
  (:map goto-map
				("f" . project-find-file)
				("P" . project-switch-project))
  (:map search-map
				("*" . +project-find-symbol)))

(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package vterm
  :ensure t
  :pin "melpa"
  :commands vterm
  :custom
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t)
  (vterm-tramp-shells '(("ssh" "/bin/bash")
                         ("docker" "/bin/sh")
                         (t "/bin/sh"))))

(use-package vterm-toggle
  :ensure t
  :pin "melpa"
  :after vterm
  :commands vterm-toggle
  :bind
  (:map mymacs-mode-map
        ("C-c t" . vterm-toggle)
        ("C-c T" . vterm))
  :custom
  (vterm-toggle-fullscreen-p nil)
  (vterm-toggle-scope 'project)
  :init
  (push `("\\*vterm.*\\*" . ,my/side-window-config)
        display-buffer-alist))

;;; GTD
(use-package org
  :custom
  (org-directory (file-truename (expand-file-name my/org-directory)))
	(org-agenda-files (list (concat org-directory "/tasks.org")
													(concat org-directory "/log.org")))
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
	(org-enforce-todo-dependencies t)
	(org-agenda-custom-commmands '((n "Next actions" todo "TODO") ("w" "Waiting" todo "WAIT")))
	(org-tag-alist my/org-tag-alist)

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
  (ispell-program-name "aspell")
  (ispell-dictionary "en_US"))

;;;; Denote


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
	 ("c" . consult-flymake))
	:custom
	(read-process-output-max (* 1024 1024))
	(eglot-server-programs
	 '((ruby-ts-mode . ("ruby-lsp"))
		 (go-ts-mode . ("gopls"))))

  :preface
	(defun my/scala-metals-contact ()
    "Build the Eglot contact spec for Metals."
    (append
     (list "metals")
     (mapcar (lambda (arg) (format "-J%s" arg)) my/scala-metals-java-options)
     my/scala-metals-server-arguments
     (list :initializationOptions my/scala-metals-initialization-options)))
  :config
  (add-to-list 'eglot-server-programs
               `(scala-ts-mode . ,(my/scala-metals-contact))))

(use-package treesit
  :custom
  (treesit-font-lock-level 5)
  :config
  (add-to-list 'treesit-language-source-alist
               '(scala "https://github.com/tree-sitter/tree-sitter-scala")))

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
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook (ruby-ts-mode . eglot-ensure)
  :bind
  (:map ruby-ts-mode-map
        ("C-c t t" . +ruby-test-dwim)
        ("C-c t o" . +ruby-test-file)
        ("C-c t r" . +ruby-rspec-dwim)
        ("C-c t m" . +ruby-minitest-dwim))
  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil))

;;;; go lang
(use-package go-ts-mode
	:mode "\\.go'"
  :hook (go-ts-mode . eglot-ensure)
  :init
  (setq-default go-ts-mode-indent-offset 4))


;;;; scala
(use-package scala-ts-mode
  :ensure t
  :pin "melpa"
  :mode ("\\.scala\\'" "\\.sc\\'" "\\.sbt\\'")
  :hook (scala-ts-mode . eglot-ensure)
  :bind
  (:map scala-ts-mode-map
				("C-c C-t" . +scala-test-only)))

;;;; lisp
