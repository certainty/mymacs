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
(defvar-keymap my/leader-map :doc "Shared leader keymap.")
(defvar-keymap my/org-prefix-map :doc "Org leader submap.")
(defvar-keymap my/pmd-prefix-map :doc "PMD leader submap.")

(keymap-set my/leader-map "o" my/org-prefix-map)
(keymap-set my/leader-map "," my/pmd-prefix-map)

(defvar-keymap mymacs-mode-map
  :doc "mymacs global keys"
  "C-j" my/leader-map)

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
(defcustom my/org-categories nil "Available Org categories." :type '(repeat string) :group 'mymacs)
(defcustom my/org-tag-alist nil "The tag quick keys" :type '(alist :key-type string :value-type character))
(defcustom my/pmd-enabled nil "Enable consult-pmd" :type 'boolean :group 'mymacs)
(defcustom my/pmd-base-url nil "The pmd url" :type 'string :group 'mymacs)
(defcustom my/denote-directory "" "The path to my notes" :type 'string :group 'mymacs)
(defcustom my/denote-keywords nil "List of keywords for denote" :type '(repeat string) :group 'mymacs)

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
        package-quickstart t)


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
(use-package modus-themes
  :ensure t)

(use-package ef-themes
  :ensure t)

(use-package emacs
  :bind
  (:map mymacs-mode-map
        ("C-g" . +escape-dwim)
        ("M-D" . backward-kill-sexp)
        ("C-o" . my/open-line-above-indented)
        ("M-<backspace>" . my/backward-kill-line)
        ("M-z" . zap-up-to-char)
        ("C-^" . just-one-space)
        ("<f5>" . display-line-numbers-mode)
        ("<f6>" . toggle-frame-maximized))
  (:map my/leader-map
        ("<" . indent-rigidly-left-to-tab-stop)
        (">" . indent-rigidly-right-to-tab-stop))
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
  (modus-vivendi-palette-overrides
   '((bg-line-number-active bg-main)
     (bg-line-number-inactive bg-main)
     (bg-paren-match bg-magenta-intense)
     (bg-fringe bg-main)
     (fringe bg-main)
     (bg-space bg-main)))
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

  (defun my/disable-meow-locally ()
    "Disable Meow in the current buffer."
    (when (fboundp 'meow-mode)
      (meow-mode -1)))

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

  (setopt mode-line-compact nil
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
                      '("  " (vc-mode vc-mode)
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

(use-package window
  :commands (+delete-other-windows)
  :bind
  (:map mymacs-mode-map
        ("C-q" . bury-buffer)
        ("C-Q" . kill-current-buffer)
        ([remap delete-other-windows] . +delete-other-windows)
        ("C-x w t"   . window-layout-transpose) 
        ("C-x w r"   . window-layout-rotate-clockwise) 
        ("C-x w f h" . window-layout-flip-leftright)   
        ("C-x w f v" . window-layout-flip-topdown))
  (:map my/leader-map
        ("|" . split-window-right))
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
     (".*"
      (display-buffer-same-window
       display-buffer-reuse-window
       display-buffer-use-some-window
       display-buffer-pop-up-window))))

  :preface
  (defun +delete-other-windows (&optional window)
    "Delete all other windows, including special windows and popups."
    (interactive)
    (let ((ignore-window-parameters t))
      (delete-other-windows window)))

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
  (history-length 200)
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100)
  :init
  (add-hook 'emacs-startup-hook #'savehist-mode))

;;; Completion
;; I have previously used vertico, marginalia, orderless and corfu as the completion stack
;; but I found that the builtin icomplete can be configured to come very close.
;; For in-buffer completion I actually prefer icomplete-preview over corfu.

;;;; minibuffer
(use-package minibuffer
  :custom
  (completion-sort 'historical)
  (completion-eager-update t)
  (completion-eager-display 'auto)
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
        ("C-j" . nil))
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
  (embark-indicators '(embark-minimal-indicator
                       embark-highlight-indicator
                       embark-isearch-highlight-indicator))
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

(use-package my-meow-helix
  :demand t
  :load-path "user-lisp")

;;;; recent
(use-package recentf
  :bind
  (:map mymacs-mode-map ("C-x R" . recentf-open))
  :custom
  (recentf-max-saved-items 200)
  (recentf-exclude '(".gz" ".xz" ".zip" "COMMIT_EDITMSG"))
  :init
  (add-hook 'emacs-startup-hook #'recentf-mode))

;;;; ibuffer

(use-package ibuffer
  :hook (ibuffer-mode . my/ibuffer-setup)
  :commands (ibuffer)
  :custom
  (ibuffer-show-empty-filter-groups nil)
  (ibuffer-saved-filter-groups
   '(("default"
      ("Emacs"
       (or
        (name . "^\\*scratch\\*$")
        (name . "^\\*Messages\\*$")
        (name . "^\\*Warnings\\*$")
        (name . "^\\*Backtrace\\*$")
        (name . "^\\*Completions\\*$")
        (name . "^\\*Embark Collect.*\\*$")))
      ("Org and text"
       (or
        (mode . org-agenda-mode)
        (mode . org-mode)
        (mode . markdown-mode)
        (mode . text-mode)))
      ("Directories" (mode . dired-mode))
      ("Shells"
       (or
        (mode . shell-mode)
        (mode . eshell-mode)
        (mode . eat-mode)
        (mode . term-mode)
        (name . "^\\*eat.*\\*$")))
      ("Code" (predicate . (derived-mode-p 'prog-mode)))
      ("Version control"
       (or
        (mode . vc-dir-mode)
        (mode . diff-mode)
        (mode . log-view-mode)))
      ("Help and diagnostics"
       (or
        (mode . help-mode)
        (mode . compilation-mode)
        (mode . grep-mode)
        (mode . occur-mode)
        (mode . flymake-diagnostics-buffer-mode)
        (mode . xref--xref-buffer-mode))))))
  :preface
  (declare-function ibuffer-auto-mode "ibuf-ext" (&optional arg))
  (declare-function ibuffer-switch-to-saved-filter-groups "ibuf-ext" (name))
  (defun my/ibuffer-setup ()
    "Apply stable defaults to Ibuffer buffers."
    (require 'ibuf-ext)
    (ibuffer-switch-to-saved-filter-groups "default")
    (ibuffer-auto-mode 1)))

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
  (:map my/leader-map
        ("." . dired-jump)))

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
  (:map my/leader-map
        ("p" . project-switch-project)
        ("v" . project-vc-dir)
        ("c" . project-compile))
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
(use-package vc
  :hook
  (vc-dir-mode . my/disable-meow-locally)
  :custom
  (vc-auto-revert-mode t)
  (vc-allow-rewriting-published-history t)
  (vc-dir-hide-up-to-date-on-revert t))

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
  (:map my/leader-map
        ("t" . eat))
  :custom
  (eat-term-name "xterm-256color")
  :init
  (push `("\\*eat.*\\*" . ,(my/side-window-config)) display-buffer-alist))

;;; GTD
(use-package org
  :hook
  (org-mode . auto-revert-mode)
  (org-agenda-mode . my/disable-meow-locally)
  :bind
  (:map my/org-prefix-map
        ("a" . org-agenda)
        ("o" . org-capture))
  :custom
  (org-directory (file-truename (expand-file-name my/org-directory)))
  (org-persist-directory (locate-user-emacs-file "org-persist/"))
  (org-agenda-files  (list org-directory))
  (org-agenda-window-setup 'other-window)
  (org-agenda-skip-scheduled-if-done t)
  (org-pretty-entities t)
  (org-use-sub-superscripts '{})
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
     ("b" "Backlog" search "*BACKLOG")
     ("w" "Waiting" todo "WAIT")
     ("d" "Decisions" todod "DECISION")))
  (org-tag-alist my/org-tag-alist)
  :preface
  (declare-function org-back-to-heading "org" (&optional invisible-ok))
  (declare-function org-entry-get "org" (epom property &optional inherit literal-nil))
  (declare-function org-set-property "org" (property value))
  (defun my/org-set-category ()
    "Set the CATEGORY property on the current Org heading."
    (interactive)
    (unless (derived-mode-p 'org-mode)
      (user-error "Not in Org mode"))
    (unless my/org-categories
      (user-error "No categories configured in my/org-categories"))
    (org-back-to-heading t)
    (org-set-property
     "CATEGORY"
     (completing-read
      "Category: "
      my/org-categories
      nil
      t
      nil
      nil
      (org-entry-get nil "CATEGORY"))))

  :config
  ;; Fixed-pitch for code/tables in variable-pitch org docs
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)
  (add-hook 'emacs-startup-hook #'org-clock-persistence-insinuate))

;;; Writing
(use-package flyspell
  :hook (text-mode . flyspell-mode)
  :commands (flyspell-mode flyspell-prog-mode)
  :custom
  (ispell-program-name "aspell")
  (ispell-dictionary "en_US")
  :config
  (keymap-set flyspell-mode-map "C-," nil))

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
  (:map my/leader-map
        ("j" . denote))
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
  :hook (prog-mode . display-line-numbers-mode)
  :custom
  (eldoc-help-at-pt t))

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
  (eglot-documentation-renderer 'markdown-ts-view-mode)
  (eglot-code-action-indications nil)
  (read-process-output-max (* 1024 1024))
  :config
  (add-to-list 'eglot-server-programs
               '((ruby-mode ruby-ts-mode)
                 "ruby-lsp"))
  (add-to-list 'eglot-server-programs
               '((elixir-mode elixir-ts-mode heex-ts-mode)
                 "expert" "--stdio"))
  (add-to-list 'eglot-server-programs
               '(scala-ts-mode
                 "metals"
                 :initializationOptions
                 (:isHttpEnabled t))))

;;; snippets
;; these also act as a provider for eglot
(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode))

(use-package treesit
  :custom
  (treesit-auto-install-grammar t)
  (treesit-enabled-modes t)
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

;;;; templates
(use-package mmm-mode
  :ensure t
  :custom
  (mmm-global-mode 'maybe)
  :init
  (require 'mmm-auto)
  :config
  (mmm-add-classes
   '((gotmpl
      :submode go-ts-mode
      :face mmm-code-submode-face
      :front "{{-?"
      :back "-?}}"
      :end-not-begin t)))
  (mmm-add-mode-ext-class 'yaml-ts-mode nil 'gotmpl)
  (mmm-add-mode-ext-class nil "\\.gotmpl\\'" 'gotmpl))

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

;;;; elixir
(use-package elixir-ts-mode
  :mode ("\\.elixir\\'" "\\.ex\\'" "\\.exs\\'" "mix\\.lock\\'")
  :hook (elixir-ts-mode . eglot-ensure)
  :custom
  (elixir-ts-indent-offset 2))

(use-package heex-ts-mode
  :mode "\\.[hl]?eex\\'"
  :hook (heex-ts-mode . eglot-ensure))

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

;;;; mise
(use-package mise
  :ensure t
  :demand t
  :pin "melpa"
  :config
  (global-mise-mode 1))

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
  (:map my/pmd-prefix-map
        ("," . +pmd-projects)
        ("t" . +pmd-teams)
        ("p" . +pmd-people)
        ("s" . +pmd-servicegroups)
        ("c" . +pmd-cache-clear))
  :custom
  (pmd-base-url my/pmd-base-url)))

;;;; modal editing
(use-package meow
  :ensure t
  :demand t
  :pin "melpa"
  :custom
  (meow-display-thing-help t)
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
     '("(" . my/meow-backward-sexp)
     '(")" . my/meow-forward-sexp)
     '(";" . meow-reverse)
     '("," . meow-inner-of-thing)
     '("." . meow-bounds-of-thing)
     '("[" . meow-beginning-of-thing)
     '("]" . meow-end-of-thing)
     '("a" . meow-append)
     '("A" . my/meow-append-at-eol)
     '("b" . meow-back-word)
     '("c" . meow-change)
     '("d" . meow-kill)
     '("e" . meow-next-word)
     '("f" . meow-find)
     '("F" . my/meow-find-backward)
     (cons "g" my/meow-goto-map)
     '("G" . end-of-buffer)
     '("h" . meow-left)
     '("i" . meow-insert)
     '("I" . my/meow-insert-at-bol)
     '("j" . meow-next)
     '("J" . meow-join)
     '("k" . meow-prev)
     '("l" . meow-right)
     '("H" . meow-left-expand)
     '("K" . meow-prev-expand)
     '("L" . meow-right-expand)
     (cons "m" my/meow-match-map)
     '("M" . meow-block)
     '("n" . my/meow-search-next)
     '("N" . my/meow-search-prev)
     '("o" . meow-open-below)
     '("O" . meow-open-above)
     '("p" . meow-yank)
     '("P" . meow-pop-selection)
     '("/" . my/meow-search-forward)
     '("t" . meow-till)
     '("T" . my/meow-till-backward)
     '("u" . meow-undo)
     '("v" . expreg-expand)
     '("V" . expreg-contract)
     '("w" . meow-mark-word)
     '("x" . meow-line)
     '("X" . meow-delete)
     '("y" . meow-save)
     '("W" . meow-mark-symbol)
     '("B" . meow-back-symbol)
     '("E" . meow-next-symbol)
     '("<backspace>" . meow-backspace)
     '("DEL" . meow-backspace)
     '("C-h" . meow-backspace)
     '("<escape>" . my/meow-escape)))
  :config
  (keymap-set my/leader-map "f" #'project-find-file)
  (keymap-set my/leader-map "F" #'find-file)
  (keymap-set my/leader-map "e" #'project-dired)
  (keymap-set my/leader-map "b" #'consult-project-buffer)
  (keymap-set my/leader-map "s" #'consult-imenu)
  (keymap-set my/leader-map "S" #'consult-imenu-multi)
  (keymap-set my/leader-map "/" #'consult-ripgrep)
  (keymap-set my/leader-map "d" #'consult-flymake)
  (keymap-set my/leader-map "D" #'flymake-show-project-diagnostics)
  (keymap-set my/leader-map "a" #'eglot-code-actions)
  (keymap-set my/leader-map "r" #'eglot-rename)
  (keymap-set my/leader-map "k" #'eldoc)
  (keymap-set my/leader-map "h" #'xref-find-references)
  (my/meow-setup)
  (meow-global-mode 1))
