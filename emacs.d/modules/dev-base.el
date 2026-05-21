;;; dev-base.el --- Basic Dev Setup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Configures the foundation for development, including LSP (Eglot),
;; Treesitter, Flymake, and smart pairing.
;;
;;; Code:

;;; Dev popups (Eldoc, Compile-log)
(my/register-bottom-popup 'eldoc-mode nil nil)
(my/register-bottom-popup "\\*Compile-log\\*" nil t)
(my/register-bottom-popup "\\*xref\\*" t t)

;;; Eglot (LSP)
(use-package eglot
  :straight (:type built-in)
  :commands (eglot eglot-ensure)
  :init
  (setq eglot-stay-out-of '(flymake))

  (with-eval-after-load 'consult
    (setopt xref-show-xrefs-function 'consult-xref)
    (setopt xref-show-definitions-function 'consult-xref))

  :custom
  (eglot-report-progress nil)
  (eglot-extend-to-xref t)
  (eglot-autoreconnect 5)
  (eldoc-echo-area-use-multiline-p 1)
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)
  (eglot-code-action-indicator "*") ;; prohibit weird jumps in line height when eglot shows information
  :config
  (fset #'jsonrpc--log-event #'ignore))

;;; Treesitter
(use-package treesit
  :straight (:type built-in)
  :custom
  (treesit-extra-load-path
   (list (expand-file-name "tree-sitter" user-emacs-directory)))
  (treesit-font-lock-level 5)
  :config
  (when (>= emacs-major-version 31)
    (setopt treesit-auto-install-grammar 'always)
    (setopt treesit-enabled-modes t)))

(use-package treesit-auto
  :straight t
  :config
  ;; `treesit-language-source-alist' is empty by default, so keep it populated
  ;; from `treesit-auto' recipes even on Emacs 31 where built-in installation
  ;; is available.
  (setq treesit-language-source-alist (treesit-auto--build-treesit-source-alist))
  ;; Add markdown-inline which is often missing from treesit-auto recipes
  (add-to-list 'treesit-language-source-alist
               '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" nil "tree-sitter-markdown-inline/src"))
  (if (>= emacs-major-version 31)
      (setopt treesit-auto-install nil)
    (setopt treesit-auto-install 'prompt)
    (treesit-auto-add-to-auto-mode-alist 'all)
    (global-treesit-auto-mode 1)))

(defun +treesit-install-all-grammars (&optional force)
  "Install Tree-sitter grammars for all languages supported by this profile.
With FORCE prefix, re-install even if already present."
  (interactive "P")
  (require 'treesit-auto)
  (let ((treesit-language-source-alist (treesit-auto--build-treesit-source-alist))
        (langs (if force
                   treesit-auto-langs
                 (seq-filter (lambda (lang) (not (treesit-ready-p lang t)))
                             treesit-auto-langs))))
    (if langs
        (progn
          (message "Installing %d grammars..." (length langs))
          (mapc #'treesit-install-language-grammar langs)
          (message "Grammar installation complete."))
      (message "All grammars are already installed (use prefix to force)."))))

;;; Flymake (Linting)
(use-package flymake
  :straight (:type built-in)
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-no-changes-timeout 0.5)
  (flymake-start-on-save-buffer t)
  (flymake-error-bitmap '(right-triangle compilation-error))
  (flymake-warning-bitmap '(right-triangle compilation-warning))
  (flymake-note-bitmap '(right-triangle compilation-info))
  (flymake-show-diagnostics-at-end-of-line nil)
  :config
  (diminish 'flymake-mode))

;;; Flymake-collection (More diagnostic backends)
(use-package flymake-collection
  :straight t
  :after flymake)

;;; Consult-Flymake - Consult integration for flymake
(use-package consult-flymake
  :straight (:type built-in)
  :after (consult flymake))

;;; Highlight nested parentheses
(use-package highlight-parentheses
  :straight t
  :hook prog-mode)

(use-package elec-pair
  :straight (:type built-in)
  :hook (prog-mode . electric-pair-mode))

;;; Dape (Debug Adapter Protocol)
(use-package dape
  :straight t
  :commands dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  :bind-keymap ("C-x C-a" . dape-global-map)
  :init
  (define-prefix-command '+debug nil "+debug")
  (keymap-set +language "e" '+debug)
  (keymap-set +debug "d" 'dape)
  :config
  (dape-breakpoint-load)
  (my/register-bottom-popup "\\*dape-repl\\*" t t)
  (my/register-side-popup "\\*dape-info" nil t)
  (map-keymap (lambda (key cmd)
                (unless (eq key ?d)
                  (define-key +debug (vector key) cmd)))
              dape-global-map))

(use-package emacs
  :hook
  (makefile-bsdmake-mode . +disable-format-on-save)
  (makefile-mode . +disable-format-on-save)
  (makefile-gmake-mode . +disable-format-on-save))

(provide 'dev-base)
;;; dev-base.el ends here
