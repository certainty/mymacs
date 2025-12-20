;;; dev-base.el --- Basic Dev Setup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package emacs
  :init
  (add-to-list 'display-buffer-alist
    '("\\*\\(Backtrace\\|Compile-log\\|Messages\\|Warnings\\)\\*"
       (display-buffer-in-side-window)
       (side . bottom)
       (slot . 0)
       (window-height . 0.33)
       (window-parameters
         (no-delete-other-windows . nil))))

  (add-to-list 'display-buffer-alist
    '("\\*shell:"
       (display-buffer-below-selected)
       (window-height . 12)))

  (add-to-list 'display-buffer-alist
    '("\\*\\(eldoc\\)\\*"
       (display-buffer-reuse-window display-buffer-in-side-window)
       (window-width . 30)
       (window-parameters . ((no-other-window . t)
                              (no-delete-other-windows . t)))
       (dedicated . t)
       (side . bottom)
       (slot . 5))))

(use-package eglot
  :straight (:type built-in)
  :commands (eglot eglot-ensure)
  :custom
  (eglot-report-progress t)
  (eglot-extend-to-xref t)
  (eglot-autoreconnect 5)
  (eldoc-echo-area-use-multiline-p 1)
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)

  :config
  (fset #'jsonrpc--log-event #'ignore)
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)

  :general
  (leader-def
    :keymaps 'eglot-mode-map
    "c" '(:ignore t :which-key "code")
    "cl" 'eglot
    "cr" 'eglot-rename
    "cf" 'eglot-format
    "ca" 'eglot-code-actions
    "cd" 'xref-find-definitions
    "cD" 'xref-find-references
    "ci" 'eglot-find-implementation
    "ct" 'eglot-find-typeDefinition
    "cR" 'eglot-reconnect
    "cQ" 'eglot-shutdown
    "cS" 'eglot-shutdown-all)

  :bind
  (:map eglot-mode-map
    ("M-g e a" . xref-find-apropos)
    ("M-g e d" . xref-find-definitions)
    ("M-g e r" . eglot-rename)
    ("M-g e i" . eglot-find-implementation)
    ("M-g e D" . eglot-find-declaration)
    ("M-g e t" . eglot-find-typeDefinition)))

;;; Treesitter
(use-package treesit-auto
  :hook (after-init . global-treesit-auto-mode)
  :custom
  (treesit-font-lock-level 5)
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all))

;;; Flymake
(use-package flymake
  :straight (:type built-in)
  :hook (prog-mode . flymake-mode)
  :general
  (leader-def
    :keymaps 'flymake-mode-map
    "!" '(:ignore t :which-key "diagnostics")
    "!!" 'consult-flymake
    "!l" 'flymake-show-buffer-diagnostics
    "!L" 'flymake-show-project-diagnostics
    "!n" 'flymake-goto-next-error
    "!p" 'flymake-goto-prev-error)
  :custom
  (flymake-no-changes-timeout 0.5)
  (flymake-start-on-save-buffer t)
  (flymake-error-bitmap '(right-triangle compilation-error))
  (flymake-warning-bitmap '(right-triangle compilation-warning))
  (flymake-note-bitmap '(right-triangle compilation-info))
  (flymake-show-diagnostics-at-end-of-line nil)
  :config
  (diminish 'flymake-mode))

;;;; Consult-Flymake - Consult integration for flymake
(use-package consult-flymake
  :straight nil
  :after (consult flymake)
  :defer t)

;;; Format and Format on Save

;; we use reformatter to easily define "external" formatters
;;
;; Here is an example on how I use it in my language modes
;;
;; rust.el
;;
;; (reformatter-define rustfmt
;;   :program "rustfmt")
;;
;; (add-hook 'rust-mode-hook
;;           (lambda ()
;;             (setq-local my/external-formatter #'rustfmt-buffer
;;                         my/format-policy 'external)))

(use-package reformatter)

(defvar-local my/format-policy 'dwim
  "Formatting policy for the current buffer.

Possible values:
- 'eglot    → always use Eglot (error if unavailable)
- 'external → always use external formatter
- 'dwim     → use Eglot if possible, otherwise external")

(defun my/format-buffer-with-indent-region ()
  "Format the entire buffer with `indent-region`, preserving point and narrowing."
  (save-excursion
    (save-restriction
      (widen)
      (indent-region (point-min) (point-max)))))

(defvar-local my/external-formatter #'my/format-buffer-with-indent-region
  "Function that formats the current buffer using an external formatter.")

(cl-defmacro my/define-mode-formatter (&key hook (policy 'dwim) (external))
  "Define a buffer-local formatter for a mode.
Keyword arguments:
- :hook     (required) the major-mode hook to attach to
- :policy   (required) one of 'eglot, 'external, or 'dwim
- :external (optional) a function to format the buffer for external formatting"
  `(add-hook ,hook
     (lambda ()
       ,@(when policy
           `((setq-local my/format-policy ,policy)))
       ,@(when external
           `((setq-local my/external-formatter ,external))))))

(defun my/eglot-can-format-p ()
  "Return non-nil if the current buffer can be formatted by Eglot."
  (when (and (fboundp 'eglot-managed-p) (eglot-managed-p))
    (cl-some
      (lambda (server)
        (eglot--server-capable server :documentFormattingProvider))
      (eglot-current-server))))

(defun my/format-with-eglot ()
  "Format buffer using Eglot. Return t if formatting was requested."
  (interactive)
  (when (my/eglot-can-format-p)
    (eglot-format-buffer)
    t))

(defun my/format-with-external ()
  "Format buffer using the external formatter."
  (interactive)
  (when (and my/external-formatter (functionp my/external-formatter))
    (message "running with external formatter")
    (funcall my/external-formatter)
    t))

(defun my/format-buffer ()
  "Format the current buffer according to `my/format-policy`."
  (interactive)
  (pcase my/format-policy
    ('eglot
      (unless (my/format-with-eglot)
        (user-error "Eglot formatting not available")))
    ('external
      (unless (my/format-with-external)
        (user-error "No external formatter configured")))
    ('dwim
      (or (my/format-with-eglot)
        (my/format-with-external)))
    (_
      (user-error "Unknown format policy: %s" my/format-policy))))

(defun my/format-debug ()
  "Show debug information for the current format settings."
  (interactive)
  (message "policy=%s eglot=%s"
    my/format-policy
    (my/eglot-can-format-p)))

(defvar-local my/format-on-save-enabled nil
  "Non-nil if `my/format-buffer` should be called automatically before saving this buffer.")

(defun my/enable-format-on-save ()
  "Enables format on save."
  (interactive)
  (add-hook 'before-save-hook #'my/format-buffer nil t)
  (setq my/format-on-save-enabled t)
  (message "Format-on-save enabled"))

(defun my/disable-format-on-save ()
  "Disables format on save."
  (remove-hook 'before-save-hook #'my/format-buffer t)
  (setq my/format-on-save-enabled nil)
  (message "Format-on-save disabled"))

(defun my/toggle-format-on-save ()
  "Toggle automatic formatting on save for the current buffer."
  (interactive)
  (if my/format-on-save-enabled
    (my/disable-format-on-save)
    (my/enable-format-on-save)))

(use-package emacs
  :general
  (leader-def
    "tF" 'my/toggle-format-on-save)
  :init
  (add-hook 'prog-mode-hook (lambda () (my/enable-format-on-save))))


;;; Global dev related settings
(use-package paren
  :straight (:type built-in)
  :hook (prog-mode . show-paren-mode)
  :custom
  (show-paren-delay 0))

(use-package highlight-parentheses
  :hook prog-mode)

(use-package electric-pair
  :straight (:type built-in)
  :hook prog-mode)

(provide 'dev-base)
;;; dev-base.el ends here
