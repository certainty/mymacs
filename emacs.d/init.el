;; -*- lexical-binding: t; -*-

;;; Conventions
;; - user defined functions use my/ prefix
;; - private user defined functinos use my-- prefix
;; - user defined interactive functions use + prefix
;;
;; Use of use-package
;;
;; All uses of use-package put the options into the same order which is defined melow.
;; If an option doesn't apply the order resumes with the next one.
;;
;; - :if / :unless
;; - :ensure
;; - :demand
;; - :pin
;; - :mode
;; - :hook
;; - :commands
;; - :bind
;; - :custom
;; - :preface
;; - :init
;; - :config

;;; Customization
(defvar-keymap mymacs-mode-map :doc "mymacs global keys")
(defvar mymacs-emulation-mode-map-alist
  `((mymacs-mode . ,mymacs-mode-map))
  "Keymap alist giving `mymacs-mode-map' precedence.")

(define-minor-mode mymacs-mode
  "My personal minor mode"
  :init-value t
  :global t
  :group 'mymacs
  :lighter " MyM"
  :keymap mymacs-mode-map)

(add-to-list 'emulation-mode-map-alists 'mymacs-emulation-mode-map-alist)
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
(defcustom my/pmd-enabled nil "Enable consult-pmd" :type 'boolean :group 'mymacs)
(defcustom my/pmd-base-url nil "The pmd url" :type 'string :group 'mymacs)
(defcustom my/denote-directory "" "The path to my notes" :type 'string :group 'mymacs)
(defcustom my/denote-keywords nil "List of keywords for denote" :type '(repeat string) :group 'mymacs)
(defcustom my/agent-shell-enabled nil "Enable AI with agent-shell?" :type 'boolean :group 'mymacs)

;;;; load custom file
(setopt custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; Packages

;; The main objective for packages is to strike a good balance between security
;; and functionality. This is achieved by:
;; - using as few packages as possible
;; - pin to the conservative archives
;; - require review for melpa packages
(require 'package)
(require 'use-package)
(setq use-package-always-pin "gnu")
(setopt package-archives
        '(("gnu" . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")
          ("melpa" . "https://melpa.org/packages/"))
        package-archive-priorities
        '(("gnu" . 20)
          ("nongnu" . 10)
          ("melpa" . 3))
        ;; we have to pin all packages by default to prevent melpa packages
        ;; from getting precedence
        network-security-level 'high
        gnutls-verify-error t
        package-install-upgrade-built-in nil
        package-check-signature nil
        package-review-policy '((archive . "melpa"))
        package-native-compile t
        ;; don't required to refresh packages all the time
        package-quickstart nil)


;;; Environment setup (to start emacs from launcher)
(use-package exec-path-from-shell
  :ensure t
  :pin "nongnu"
  :if (memq window-system '(mac ns))
  :custom
  (exec-path-from-shell-variables my/required-environment-variables)
  (exec-path-from-shell-arguments '("-l" "-i"))
  (exec-path-from-shell-check-startup-files nil)
  :config
  (exec-path-from-shell-initialize)
  :preface
  (defconst my/required-environment-variables
    '("PATH" "MANPATH" "GOPATH" "CARGO_HOME" "RUSTUP_HOME" "JAVA_HOME" "SBT_HOME")
    "Environment variables imported from the shell on macOS."))

;;; Essentials
(use-package emacs
  :bind
  (:map mymacs-mode-map
        ("C-j <" . indent-rigidly-left-to-tab-stop)
        ("C-j >" . indent-rigidly-right-to-tab-stop)
        ("C-g" . +escape-dwim)
        ("M-D" . backward-kill-sexp)
        ("C-o" . my/open-line-above-indented)
        ("M-<backspace>" . my/backward-kill-line)
        ("M-z" . zap-up-to-char)
        ("C-^" . just-one-space)
        ("<f5>" . display-line-numbers-mode)
        ("<f6>" . toggle-frame-maximized))
  (:map goto-map
        ("n" . nil)
        ("p" . nil)
        ("<" . pop-to-mark-command)
        ("m" . pop-global-mark))
  (:repeat-map my/navigation-repeat-map
               ("n" . forward-line)
               ("p" . previous-line))
  (:repeat-map my/mark-repeat-map
               ("<" . pop-to-marnk-command)
               ("m" . pop-global-mark))
  
  :custom
  ;;; ui
  (use-short-answers t)
  (ring-bell-function 'ignore)
  (inhibit-startup-screen t)
  (inhibit-startup-message t)
  (initial-scratch-message ";; Hack the planet!\n\n")

  ;;; editing
  (kill-whole-line t)
  (next-line-add-newlines t)
  (set-mark-command-repeat-pop t)

;;; theme configuration
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
      (keyboard-quit))))

  (defun my/open-line-above-indented ()
    (interactive)
    (forward-line -1)
    (end-of-line)
    (insert "\n")
    (indent-according-to-mode))
 
  (defun my/backward-kill-line ()
    "Kills the whole line backwards starting from point"
    (interactive)
    (let ((curr (point)))
      (back-to-indentation)
      (delete-region (point) curr)))

  :init
  ;;; modes
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (global-hl-line-mode -1)
  (repeat-mode)
  (delete-selection-mode)
  (global-subword-mode)
  (save-place-mode)

  ;;; tab settings
  (setq-default indent-tabs-mode nil)
  (setq-default standard-indent 2)
  (setq-default tab-width 2)

  ;;; default font
  (set-face-attribute
   'default nil
   :font my/font
   :height my/font-height
   :weight my/font-weight)

  ;;;; load theme
  (load-theme my/theme)

  ;;;; modeline
  (dolist (m '(mode-line mode-line-active mode-line-inactive))
    (set-face-attribute m nil :background 'unspecified :box nil :overline "gray50" :underline nil))

  (setopt project-mode-line t
          mode-line-compact nil
          mode-line-right-align-edge 'right-margin)

  (setq-default mode-line-format
                '("%e"
                  mode-line-front-space
                  mode-line-modified
                  mode-line-remote
                  " "
                  mode-line-buffer-identification
                  (:eval
                   (when (mode-line-window-selected-p)
                     (format-mode-line
                      '("  " (project-mode-line project-mode-line-format)
                        "  " (vc-mode vc-mode)
                        "  " mode-name mode-line-process))))
                  mode-line-format-right-align
                  (:eval
                   (when (mode-line-window-selected-p)
                     (format-mode-line
                      `("  "
                        ,@(when (bound-and-true-p flymake-mode)
                            '(flymake-mode-line-format
                              "  "))
                        mode-line-misc-info))))
                  mode-line-end-spaces)))  

(use-package easy-kill
  :ensure t
  :bind
  ([remap mark-sexp] . easy-mark)
  ([remap kill-ring-save] . easy-kill)
  (:map mymacs-mode-map
        ("M-j" . mark-sexp)))

;;;; outline

(use-package outline
  :hook ((prog-mode . outline-minor-mode)
         (org-mode . outline-minor-mode)
         (markdown-mode . outline-minor-mode))
  :bind
  (:map outline-minor-mode-map
        ("C-<tab>" . outline-cycle)))

;;;; windows and buffers

(defun my/window-config (display-action side size-key size-value &optional mode slot)
  (append
   `((,display-action display-buffer-in-side-window)
     (side . ,side)
     (slot . ,(or slot 0))
     (,size-key . ,size-value)
     (window-parameters . ((no-other-window . t) (no-delete-other-windows . t))))
   (when mode `((mode . ,mode)))))

(defun my/side-window-config (&optional mode slot)
  (my/window-config 'display-buffer-reuse-mode-window 'right 'window-width 0.33 mode slot))

(defun my/bottom-window-config (&optional mode reuse-action slot)
  (my/window-config (or reuse-action 'display-buffer-reuse-mode-window)
                    'bottom
                    'window-height
                    0.25
                    mode
                    slot))

(defun my/agent-shell-buffer-p (buffer-name _action)
  (when-let* ((buffer (get-buffer buffer-name)))
    (with-current-buffer buffer
      (or (derived-mode-p 'agent-shell-mode)
          (derived-mode-p 'agent-shell-viewport-view-mode)
          (derived-mode-p 'agent-shell-viewport-edit-mode)))))

(use-package window
  :bind
  (:map mymacs-mode-map
        ("C-j |" . split-window-right)
        ("C-q" . bury-buffer)
        ("C-Q" . kill-current-buffer))
  (:map goto-map
        ("n b" . next-buffer)
        ("p b" . previous-buffer))
  (:repeat-map my/window-resize-repeat-map
               ("{" . shrink-window-horizontally)
               ("}" . enlarge-window-horizontally))
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
   `(("\\*Org Select\\*" . ,(my/bottom-window-config))
     ("\\`CAPTURE-" . ,(my/bottom-window-config nil 'display-buffer-reuse-window))
     ("\\*Capture\\*" . ,(my/bottom-window-config))
     ("\\*vc-log\\*" . ,(my/bottom-window-config nil 'display-buffer-reuse-window 0))
     ("\\*log-edit-files\\*" . ,(my/bottom-window-config 'special-mode 'display-buffer-reuse-window 1))
     ("^\\*vc-git.*\\*$" . ,(my/bottom-window-config 'special-mode))
     ("^\\*vc-dir\\*" . ,(my/side-window-config 'special-mode))
     ("\\*xref\\*" . ,(my/bottom-window-config 'special-mode))
     ("\\*\\(Help\\|compilation\\|Occur\\|grep\\|Flymake.*\\)\\*" . ,(my/side-window-config 'special-mode))
     ,@(when my/agent-shell-enabled
         `((my/agent-shell-buffer-p . ,(my/side-window-config))))
     (".*"
      (display-buffer-same-window
       display-buffer-reuse-window
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
  :bind
  (:map mymacs-mode-map
        ("M-o" . ace-window)
        ("M-O" . other-window))
  :custom
  (aw-keys '(?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l))
  :config
  (add-to-list 'aw-dispatch-alist
               '(?q ace-delete-window "Delete Window")))

(use-package popper
  :ensure t
  :bind
  (:map mymacs-mode-map
        ("C-`"   . popper-toggle)
        ("M-`"   . popper-cycle)
        ("C-M-`" . popper-toggle-type))
  :custom
  (popper-display-control nil)
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          "\\*vc-.*\\*"
          "\\*eat\\*"
          occur-mode
          help-mode
          compilation-mode))
  (popper-mode +1)
  (popper-echo-mode +1))

;;;; auto-revert
(use-package autorevert
  :custom
  (auto-revert-verbose nil)
  :init
  (global-auto-revert-mode 1))

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
;; I have previously used vertico, marginalia, orderless and corfu as the completion stack
;; but I found that the builtin icomplete can be configured to come very close.
;; For in-buffer completion I actually prefer icomplete-preview over corfu.

;;;; minibuffer
(use-package minibuffer
  :custom
  (completion-sort 'historical)
  (completion-eager-update t)
  (completion-auto-select t)
  (completions-auto-help 'visible)
  (completions-max-height 20)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completions-format 'vertical)
  (completion-styles '(substring partial-completion flex basic)))

(use-package icomplete
  :bind
  (:map icomplete-minibuffer-map
        ("C-n" . icomplete-forward-completions)
        ("C-p" . icomplete-backward-completions)
        ("C-y" . icomplete-force-complete-and-exit)
        ("C-<return>" . icomplete-force-complete))
  :custom
  (icomplete-delay-completions-threshold 0)
  (icomplete-in-buffer t)
  (icomplete-max-delay-chars 0)
  (icomplete-scroll t)
  (icomplete-prospects-height 10)
  (icomplete-show-matches-on-no-input t)
  :init
  (icomplete-vertical-mode))

;;;; In-buffer
(use-package completion-preview
  :hook ((prog-mode . completion-preview-mode)
         (org-mode . completion-preview-mode)
         (markdown-mode . completion-preview-mode))
  :bind
  (:map completion-preview-active-mode-map
        ("M-n" . completion-preview-next-candidate)
        ("M-p" . completion-preview-prev-candidate)
        ("M-y" . completion-preview-insert)
        ("C-y" . completion-preview-insert))
  :custom
  (completion-preview-message-format nil)
  (completion-preview-minimum-symbol-length nil)
  (completion-preview-idle-delay nil)
  :init
  (abbrev-mode))

(use-package cape
  :ensure t
  :hook
  (emacs-lisp-mode . my/cape-elisp-completion)
  (text-mode . my/cape-text-completion)
  :preface
  (defun my/cape-text-completion ()
    (setq-local completion-at-point-functions
                (list (cape-capf-super #'cape-dict))))
  
  (defun my/cape-elisp-completion ()
    (setq-local completion-at-point-functions
                (list (cape-capf-super #'cape-elisp-block #'cape-elisp-symbol))))
  :init
  (add-to-list 'completion-at-point-functions	'cape-dabbrev)
  (add-to-list 'completion-at-point-functions 'cape-file))

;;; Editing

;;;; handling pairs (quotes, parens, etc.)
(use-package elec-pair
  :bind
  (:map mymacs-mode-map
        ("C-z" . delete-pair))
  :custom
  (delete-pair-blink-delay 0.0)
  (delete-pair-push-mark t)
  :init
  (electric-pair-mode))

;;;; core editing / structural
;; TODO: do we still need it since we have easy-kill enabled?
(use-package expreg
  :ensure t
  :bind
  (:map mymacs-mode-map
        ("C-=" . expreg-expand)
        ("C--" . expreg-contract)))

(use-package paredit
;  :load-path "user-lisp"
  :bind
  (:map paredit-mode-map
        ("C-j" . nil)) ;; C-j is our global prefix
  :hook
  (emacs-lisp-mode . paredit-mode)
  (lisp-mode . paredit-mode))

;;;; embark
(use-package embark
  :ensure t
  :bind
  (:map mymacs-mode-map
        ("C-." . embark-act)
        ("C-," . embark-dwim))
  (:map icomplete-minibuffer-map
        ("C-." . embark-act)
        ("C-," . embark-dwim)
        ("C-c C-c" . embark-collect)
        ("C-c C-e" . embark-export)
        ("C-c C-m" . embark-select)
        ("C-c C-a" . embark-act-all))
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
  :custom
  (embark-prompter 'embark-completing-read-prompter)
  (prefix-help-command 'embark-prefix-help-command)
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
  (create-lockfiles nil)
  (find-file-visit-truename t))

(use-package alternate-file
  :demand t
  :load-path "user-lisp")

;;;; recent
(use-package recentf
  :bind
  (:map mymacs-mode-map ("C-x R" . recentf-open))
  :custom
  (recentf-max-saved-items 1000)
  (recentf-exclude '(".gz" ".xz" ".zip" "COMMIT_EDITMSG"))
  :init
  (recentf-mode))

;;;; dired

(use-package dired
  :hook (dired-mode . hl-line-mode)
  :commands (dired dired-jump dired-find-alternate-file)
  :custom
  (dired-listing-switches
   (if (and (eq system-type 'darwin)
            (not (executable-find "gls")))
       "-agho"
     "-agho --group-directories-first"))
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-auto-revert-buffer #'dired-directory-changed-p)
  (global-auto-revert-non-file-buffers t)
  (dired-dwim-target t)
  :init
  (when-let* ((gls (and (eq system-type 'darwin)
                        (executable-find "gls"))))
    (setq insert-directory-program gls))
  :bind
  (:map mymacs-mode-map
        ("C-j e" . dired-jump)))

(use-package wdired
  :commands wdired-change-to-wdired-mode
  :custom
  (wdired-allow-to-change-permissions t)
  (wdired-create-parent-directories t))

;;; Search
(use-package isearch
  :hook (occur-mode . hl-line-mode)
  :bind
  (:map isearch-mode-map
        ("C-g" . isearch-cancel))
  :custom
  (isearch-lax-whitespace t)
  (isearch-regexp-lax-whitespace nil)
  (search-highlight t)
  (isearch-lazy-highlight t)
  (isearch-lazy-highlight-initial-delay 0.5)
  (isearch-highlight-no-delay-length 4)
  (isearch-lazy-count t)
  (lazy-count-prefix-format "(%s/%s) ")
  (lazy-count-suffix-format nil)
  (isearch-wrap-pause t)
  (isearch-repeat-on-direction-change t))

(use-package consult
  :ensure t
  :bind
  (:map goto-map
        ("b" . consult-project-buffer)
        ("o" . consult-recent-file)
        ("r" . consult-bookmark)
        ("i".  consult-imenu)
        ("M" . consult-mark)
        ("d" . consult-flymake))
  (:map search-map
        ("/" . consult-ripgrep)
        ("v" . consult-git-grep))
  :config
  (with-eval-after-load 'outline
    (keymap-set outline-minor-mode-map "C-c O" #'consult-outline)))

;; wgrep no longer needed, since emacs 31 has grep-edit-mode

;;; Projects
(use-package project
  :custom
  (project-vc-extra-root-markers '(".project.el"))
  
  :bind
  (:map mymacs-mode-map
        ("C-j p" . project-switch-project)
        ("C-j v" . project-vc-dir)
        ("C-j c" . project-compile))
  (:map goto-map
        ("f" . project-find-file)
        ("P" . project-switch-project))
  (:map search-map
        ("*" . +project-find-symbol))
  :preface
  (defun +project-find-symbol ()
    "Search for symbol under point in whole project"
    (interactive)
    (consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol))))

;;;; vc
(use-package diff-hl
  :ensure t
  :hook
  (prog-mode . turn-on-diff-hl-mode)
  (vc-dir-mode . turn-on-diff-hl-mode))

;;;; terminal
(use-package eat
  :ensure t
  :pin "nongnu"
  :bind
  (:map mymacs-mode-map
        ("C-j t" . eat))
  :custom
  (eat-term-name "xterm-256color")
  :init
  (push `("\\*eat.*\\*" . ,(my/side-window-config)) display-buffer-alist))

(use-package vterm
  :ensure t
  :pin "melpa"
  :commands (vterm my/vterm-project my/toggle-vterm-project)
  :bind
  (:map mymacs-mode-map
        ("C-j \\" . my/toggle-vterm-project)
        ("C-j T" . my/vterm-project))
  :custom
  (vterm-kill-buffer-on-exit t)
  (vterm-max-scrollback 10000)
  :init
  (push `("\\*vterm.*\\*" . ,(my/side-window-config)) display-buffer-alist))

;;; GTD
(use-package org
  :bind
  (:map mymacs-mode-map
        ("C-j o" . my/org-prefix-map))
  (:prefix-map my/org-prefix-map :prefix "C-j o"
               ("a" . org-agenda)
               ("o" . org-capture))
  :custom
  (org-directory (file-truename (expand-file-name my/org-directory)))
  (org-persist-directory (locate-user-emacs-file "org-persist/"))
  (org-agenda-files (list (concat org-directory "/tasks.org")
                          (concat org-directory "/log.org")))
  (org-agenda-window-setup 'other-window)
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
  (org-clock-into-drawer t)
  (org-clock-out-when-done t)
  (org-clock-persist 'history)
  (org-clock-persist-query-save nil)
  (org-clock-persist-query-resume t)
  (org-clock-idle-time 10)
  (org-clock-auto-clock-resolution 'when-no-clock-is-running)
  (org-clock-report-include-clocking-task t)
  (org-clock-mode-line-total 'today)
  (org-agenda-start-with-clockreport-mode t)
  (org-agenda-clockreport-parameter-plist
   '(:link t :maxlevel 3 :fileskip0 t :compact t))

  ;; Refile
  (org-refile-targets '((nil :maxlevel . 5) (org-agenda-files :maxlevel . 5)))
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
  (org-agenda-custom-commands
   '(("n" "Next actions" tags-todo "+nextup")
     ("w" "Waiting" todo "WAIT")
     ("d" "Decisions" todod "DECISION")))
  (org-tag-alist my/org-tag-alist)

  :config
  ;; Fixed-pitch for code/tables in variable-pitch org docs
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)
  (org-clock-persistence-insinuate))

;;; Writing
(defvar flyspell-mode-map)

(use-package ispell
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode))
  :custom
  (ispell-program-name "aspell")
  (ispell-dictionary "en_US"))

(use-package flyspell
  :bind
  (:map flyspell-mode-map
        ("C-," . nil)))

(use-package eldoc
  :custom
  (eldoc-idle-delay 1000000)
  (eldoc-echo-area-use-multiline-p nil)
  :config
  (defun my/eldoc-display-manually-only (docs interactive)
    (when interactive
      (or (eldoc-display-in-echo-area docs interactive)
          (eldoc-display-in-buffer docs interactive))))
  (setq eldoc-display-functions '(my/eldoc-display-manually-only)))


;;;; Denote
(use-package denote
  :ensure t
  :hook (dired-mode . denote-dired-mode)
  :bind
  (:map mymacs-mode-map
        ("C-j j" . denote))
  :custom
  (denote-directory my/denote-directory)
  (denote-save-buffers nil)
  (denote-known-keywords my/denote-keywords)
  (denote-infer-keywords t)
  (denote-sort-keywords t)
  (denote-file-type nil) ; Org is the default, set others here
  (denote-prompts '(title keywords template))
  (denote-excluded-directories-regexp nil)
  (denote-excluded-keywords-regexp nil)
  (denote-rename-confirmations '(rewrite-front-matter modify-file-name))
  (denote-date-prompt-use-org-read-date t)
  (denote-backlinks-show-context t))



;;; Programming
(use-package emacs
  :hook (prog-mode . display-line-numbers-mode))

(use-package xref
  :custom
  (xref-show-definitions-function #'xref-show-definitions-buffer))

;;;; compilation mode colors
(use-package compile
  :custom
  (compilation-scroll-output t))

(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

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

  :config
  (add-to-list 'eglot-server-programs
               `(scala-ts-mode . ("metals" :initializationOptions (:isHttpEnabled t)))))

;;; snippets
;; these also act as a provider for eglot
(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode))

(use-package treesit
  :custom
  (treesit-font-lock-level 4)
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
        ("M-p" . flymake-goto-prev-error))
  :custom
  (flymake-indicator-type 'margins)
  (flymake-margin-indicator-position 'left-margin)
  (flymake-mode-line-lighter ""))

;;;; ruby
(use-package ruby-ts-mode
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'" "\\.rake\\'" "\\.gemspec\\'" "\\.ru\\'")
  :hook
  (ruby-ts-mode . eglot-ensure)
  (ruby-mode . ruby-ts-mode)
  :bind
  (:map ruby-ts-mode-map
        ("C-c a" . +find-alternate-file)
        ("C-c t t" . +ruby-test-dwim)
        ("C-c t o" . +ruby-test-file)
        ("C-c t r" . +ruby-rspec-dwim)
        ("C-c t m" . +ruby-minitest-dwim))
  :custom
  (ruby-indent-level 2)
  (ruby-insert-encoding-magic-comment nil)
  :init
  (setf (alist-get 'ruby-ts-mode my/alternate-file-mappings)
        '((:source ("app" "")
           :test ("spec" "test" "test/unit" "test/system")
           :suffixes ("_spec" "_test"))
          (:source ("lib")
           :test ("spec/lib" "test/lib" "test/unit" "test/system")
           :suffixes ("_spec" "_test")))))

;;;; go lang
(use-package go-ts-mode
  :mode "\\.go\\'"
  :hook (go-ts-mode . eglot-ensure)
  :init
  (setq-default go-ts-mode-indent-offset 4))

;;;; scala
(use-package scala-ts-mode
  :ensure t
  :pin "melpa"
  :mode ("\\.scala\\'" "\\.sc\\'" "\\.sbt\\'")
  :hook ((scala-ts-mode . my/scala-eglot-setup)
         (scala-ts-mode . eglot-ensure))
  :bind
  (:map scala-ts-mode-map
        ("C-c a" . +find-alternate-file)
        ("C-c C-t" . +scala-test-only))
  :preface
  (defun my/scala-eglot-setup ()
    "Disable Metals on-type formatting in Scala buffers."
    (setq-local eglot-ignored-server-capabilities
                (cons :documentOnTypeFormattingProvider
                      eglot-ignored-server-capabilities)))
  :init
  (setf (alist-get 'scala-ts-mode my/alternate-file-mappings)
        '((:source ("src/main/scala")
           :test ("src/test/scala" "src/it/scala")
           :suffixes ("Spec" "Suite" "Test")))))

;;;; yaml
(use-package yaml-ts-mode
  :mode ("\\.ya?ml\\'" "\\.yaml\\.gotmpl\\'" "\\.yaml\\.erb\\'" "\\.yml\\.gotmpl\\'" "\\.yml\\.erb\\'"))

;;;; json
(use-package json-ts-mode
  :mode ("\\.json\\'" "\\.json\\.gotmpl\\'" "\\.json\\.erb\\'"))

;;;; web
(use-package html-ts-mode
  :mode ("\\.html\\'" "\\.html\\.erb\\'" "\\.html\\.gotmpl\\'"))

(use-package css-mode
  :mode ("\\.css\\'" "\\.css\\.erb\\'" "\\.css\\.gotmpl\\'"))

;;;; lisp

;;;; PMD
(when my/pmd-enabled
(use-package emacs 
  :commands (+pmd-projects
             +pmd-teams
             +pmd-people
             +pmd-servicegroups
             +pmd-cache-clear)
  :bind
  (:map mymacs-mode-map
        ("C-j ," . my/pmd-prefix-map))
  (:prefix-map my/pmd-prefix-map :prefix "C-j ,"
               ("," . +pmd-projects)
               ("t" . +pmd-teams)
               ("p" . +pmd-people)
               ("s" . +pmd-servicegroups)
               ("c" . +pmd-cache-clear))
  :custom
  (pmd-base-url my/pmd-base-url)))

;;;; AI
(declare-function agent-shell-openai-make-authentication "agent-shell-openai"
                  (&rest args))

(use-package acp
  :ensure t
  :if my/agent-shell-enabled
  :load-path "vendor/acp.el")

(use-package agent-shell
  :ensure t
  :pin "melpa"
  :if my/agent-shell-enabled
  :commands (agent-shell agent-shell-toggle agent-shell-new-shell agent-shell-send-dwim)
  :bind
  (:map mymacs-mode-map
        ("C-j a" . my/agent-shell-prefix-map))
  (:prefix-map my/agent-shell-prefix-map :prefix "C-j a"
               ("a" . agent-shell)
               ("." . agent-shell-send-dwim)
               ("t" . agent-shell-toggle)
               ("n" . agent-shell-new-shell))
  :custom
  (agent-shell-display-action (my/side-window-config))
  (agent-shell-prefer-viewport-interaction t)
  (agent-shell-context-sources '(region files error line))
  (agent-shell-preferred-agent-config 'codex)
  (agent-shell-session-strategy 'prompt)
  (agent-shell-buffer-name-format 'kebab-case)
  (agent-shell-confirm-interrupt nil)
  (agent-shell-show-session-id t)
  (agent-shell-show-welcome-message nil)
  (agent-shell-tool-use-expand-by-default t)
  (agent-shell-user-message-expand-by-default t)
  :config
  (setopt agent-shell-openai-authentication (agent-shell-openai-make-authentication :login t)))
