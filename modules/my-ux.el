;;; my-ux.el --- user experience -*- lexical-binding: t; -*-

;;; Line numbers
(use-package display-line-numbers
  :ensure nil
  :after evil
  :hook
  (prog-mode . display-line-numbers-mode)
  :custom
  (display-line-numbers-type t)
  (display-line-numbers-width-start t))

;;; Minibuffer

(use-package emacs
  :ensure nil
  :custom
  (tab-always-indent 'complete)
  (enable-recursive-minibuffers t)
  (completion-auto-help 'always)
  (completions-max-height 20)
  (completions-format 'one-column)
  (completion-auto-select 'second-tab)
  (completion-detailed t)
  (suggest-keybindings t)
  (completion-sort 'historical))

(use-package minibuf-eldef
  :ensure nil
  :hook (after-init . minibuffer-electric-default-mode)
  :custom
  (minibuffer-default-prompt-format " [%s]"))

(use-package savehist
  :ensure nil
  :hook after-init
  :custom
  (savehist-save-minibuffer-history t)
  (savehist-autosave-interval 100))

;;; Orderless
(use-package orderless
  :custom
  (completion-styles '(orderless basic)))

;;; Vertico
(use-package vertico
  :hook elpaca-after-init)

;;; Marginalia
(use-package marginalia
  :hook elpaca-after-init)

;;; Icons
(use-package nerd-icons-completion
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup))

(use-package emacs
  :ensure nil
  :init
  (global-set-key [remap dabbrev-expand] 'hippie-expand))

;;; Corfu
(use-package corfu
  :hook
  ((elpaca-after-init . global-corfu-mode)
   (corfu-mode . corfu-popupinfo-mode))
  :bind
  (:map corfu-map
        ("C-y" . corfu-insert)
        ("TAB" . nil)
        ([tab] . nil)
        ("C-SPC" . corfu-insert-separator))
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 3)
  (corfu-auto-delay 0.5)
  (corfu-preselect 'valid)
  (corfu-preview-current nil)
  (corfu-min-width 20)
  (corfu-bar-width 0.5)
  (corfu-count 10)
  (corfu-cycle t) ;; completions are a ring
  (corfu-popupinfo-delay '(1.25 . 0.5)))

(use-package corfu-history
  :ensure nil ; part of corfu
  :hook corfu-mode
  :config
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-quick
  :ensure nil ; part of corfu
  :bind (:map corfu-map ("'" . corfu-quick-complete))
  :custom
  (corfu-quick1 "asdfghjkl"))

(use-package nerd-icons-corfu
  :init
  (with-eval-after-load 'corfu
    (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)))

(use-package kind-icon
  :custom
  (kind-icon-style 'nerd-icons)
  (kind-icon-use-icons t)
  (kind-icon-default-face 'corfu-default)
  (kind-icon-blend-background nil)

  :init
  (with-eval-after-load 'corfu
    (add-to-list 'corfu-margin-formatters 'kind-icon-margin-formatter)))

;;; Cape
(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

(use-package consult
  :general
   (my-file-keymap
    "o" '("Recent" . consult-recent-file))
   (my-help-keymap
    "i" '("Info" . consult-into)
    "m" '("Man" . consult-man))
   (my-buffer-keymap
    "b" '("Buffer" . consult-project-buffer)
    "B" '("Buffer*" . consult-buffer)
    "o" '("Buffer ow" . consult-buffer-other-window))
   (goto-map
    "b" '("Buffer" . consult-project-buffer)
    "B" '("Bookmark" . consult-bookmark)
    "!" '("Flymake" . consult-flymake)
    "o" '("Outline" . consult-outline)
    "i" '("Imenu" . consult-imenu)
    "I" '("Imenu multi" . consult-imenu-multi))
   (search-map
    "f" '("File" . consult-fd)
    "p" '("Ripgrep" . consult-ripgrep)
    "g" '("Grep" . consult-grep))
   (minibuffer-local-map
    "M-s" '("History" . consult-history))

  :init
  (unbind-key "M-g n") ; free some prefix keys we need
  (fset 'multi-occur #'consult-multi-occur)

  :custom
  (consult-narrow-key "<")
  (register-preview-delay 0.5)
  (register-preview-function 'consult-register-format)
  (xref-show-xrefs-function 'consult-xref)
  (xref-show-definitions-function 'consult-xref)

  :config
  (consult-customize
    consult-ripgrep consult-git-grep consult-grep
    consult-bookmark consult-recent-file consult-xref
    consult--source-bookmark consult--source-recent-file
    consult--source-project-recent-file consult-theme
    :preview-key '(:debounce 0.2 any))


  (setq consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /   --smart-case --no-heading --with-filename --line-number --search-zip")
  (setq consult-async-min-input 2)

  ;; Consult info functions
  (defun consult-info-emacs ()
    "Search through Emacs info pages."
    (interactive)
    (consult-info "emacs" "efaq" "elisp" "cl"))

  (defun consult-info-org ()
    "Search through the Org info page."
    (interactive)
    (consult-info "org"))

  (defun consult-info-completion ()
    "Search through completion info pages."
    (interactive)
    (consult-info "vertico" "consult" "marginalia" "orderless" "embark" "corfu" "cape" "tempel"))

  (defun consult-line-symbol-at-point ()
    (interactive)
    (consult-line (thing-at-point 'symbol))))

(use-package consult-dir
  :general
  (goto-map
   "d" '("Directory" . consult-dir))
  (vertico-map
   "C-c C-d" '("Directory" . consult-dir)
   "C-c C-j" '("Jump dir" . consult-dir-jump-file)))

(use-package embark-consult
  :after embark
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;;; Search
(use-package grep
  :ensure nil
  :commands (grep lgrep rgrep)
  :custom
  (grep-save-buffers nil)
  (grep-use-headings t) ; Emacs 30

  :config
  (let ((executable (or (executable-find "rg") "grep"))
        (rgp (string-match-p "rg" grep-program)))
    (setq grep-program executable)
    (setq grep-template
          (if rgp
              "/usr/bin/rg -nH --null -e <R> <F>"
            "/usr/bin/grep <X> <C> -nH --null -e <R> <F>"))
    (setq xref-search-program (if rgp 'ripgrep 'grep))))

(use-package wgrep
  :bind
  (:map grep-mode-map
    ("e" . wgrep-change-to-wgrep-mode)
    ("C-x C-q" . wgrep-change-to-wgrep-mode)
    ("C-c C-c" . wgrep-finish-edit)))

;;; Embark
(use-package embark
  :general
   (mymacs-mode-map
     "C-." '("Embark" . embark-act)
     "C-," '("Embark collect" . embark-collect))
   (my-point-leader-keymap
     "." '("Embark" . embark-act)
     "," '("Embark collect" . embark-collect))
   (my-help-keymap
     "B" '("Embark" . embark-bindings))

  :custom
  (prefix-help-command #'embark-prefix-help-command)
  (embark-prompter 'embark-completing-read-prompter)
  (embark-indicators
    '(embark-highlight-indicator
       embark-isearch-highlight-indicator))

  :config
  (add-to-list 'display-buffer-alist
    '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
       nil
       (window-parameters (mode-line-format . none)))))

;;; Helpful
(use-package helpful
   :general
   (my-point-leader-keymap
      "h" '("help" . helpful-at-point))
   (my-help-keymap
    "f" '("callable" . helpful-callable)
    "v" '("variable" . helpful-variable)
    "s" '("symbol" . helpful-symbol)
    "k" '("key" . helpful-key)
    "x" '("command" . helpful-command)))

(use-package delsel
  :ensure nil
  :hook (elpaca-after-init . delete-selection-mode))

(provide 'my-ux)
