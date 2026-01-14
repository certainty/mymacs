;;; core-editing.el --- Basic editing features -*- lexical-binding: t; -*-
;;
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package emacs
  :custom
  (show-paren-delay 0)

  :init
  (setq-default
    indent-tabs-mode nil
    tab-width 2
    fill-column 150)

  (show-paren-mode 1)
  (electric-pair-mode -1)
  (electric-indent-mode -1)
  (global-visual-line-mode -1)
  (global-auto-revert-mode 1))


(use-package display-line-numbers
  :straight (:type built-in)
  :hook prog-mode

  :general
  (leader-def
    "tl" 'display-line-numbers-mode)

  :custom
  (display-line-numbers-type t)
  (display-line-numbers-width-start t))

(use-package evil-nerd-commenter
  :demand t
  :after evil
  :commands (evilnc-comment-operator
              evilnc-inner-comment
              evilnc-outer-commenter)
  :general ([remap comment-line] #'evilnc-comment-or-uncomment-lines))

(use-package evil-surround
  :after evil
  :hook (after-init global-evil-surround-mode))

(use-package evil-exchange
  :after evil
  :config
  (diminish 'evil-exchange-mode)
  (evil-exchange-install))

(use-package evil-snipe
  :after evil
  :hook (after-init . (lambda ()
                        (evil-snipe-mode 1)
                        (evil-snipe-override-mode 1)))
  :config
  (diminish 'evil-snipe-mode)
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1)

  :custom
  (evil-snipe-scope 'visible)
  (evil-snipe-repeat-scope 'whole-visible)
  (evil-snipe-smart-case t)
  (evil-snipe-use-vim-sneak-bindings t))

;;;; Evil Visualstar - Search with * in visual mode
(use-package evil-visualstar
  :after evil
  :hook (after-init . global-evil-visualstar-mode))

;;;; Evil Lion - Align operators
(use-package evil-lion
  :after evil
  :hook (after-init . evil-lion-mode))

;;;; Evil Args - Arguments text object
(use-package evil-args
  :after general
  :general
  (:keymaps 'evil-inner-text-objects-map
    "a" 'evil-inner-arg)
  (:keymaps 'evil-outer-text-objects-map
    "a" 'evil-outer-arg)
  (:states 'normal
    "L" 'evil-forward-arg
    "H" 'evil-backward-arg
    "K" 'evil-jump-out-args)
  (:states '(normal motion)
    "[," 'evil-backward-arg
    "]," 'evil-forward-arg))

(use-package embark
  :preface
  (defvar my/embark-prefix-map (make-sparse-keymap)
    "Keymap for Embark C-. prefix.")

  :general
  (:states '(normal insert visual motion emacs)
    "C-." my/embark-prefix-map
    "C-h B" 'embark-bindings)

  (:keymaps 'my/embark-prefix-map
    "," 'embark-dwim
    "." 'embark-act
    "a" 'embark-act-all
    "m" 'embark-select)

  (leader-def
    "." '(:ignore t :which-key "embark")
    ".." 'embark-dwim
    ".," 'embark-act
    ".a" 'embark-act-all
    ".m" 'embark-select)

  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  (keymap-set global-map "C-." my/embark-prefix-map)
  (with-eval-after-load 'vertico
    (keymap-set vertico-map "C-." my/embark-prefix-map))
  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
    '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
       nil
       (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package ws-butler
  :hook prog-mode)

;; ----------------------------
;; Yasnippet
;; ----------------------------
(use-package yasnippet
  :hook (after-init . yas-global-mode)
  :general
  (leader-def
    "xs" 'yas-insert-snippet)
  :custom
  (yas-snippet-dirs (list (expand-file-name "snippets" user-emacs-directory)))
  :config
  (yas-reload-all))



(provide 'core-editing)
;;; core-editing.el ends here
