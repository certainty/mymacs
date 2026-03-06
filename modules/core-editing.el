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
  :bind
  (:map +toggle
    ("l" . display-line-numbers-mode))

  :custom
  (display-line-numbers-type t)
  (display-line-numbers-width-start t))

(use-package embark
  :bind
  (:map mymacs-mode-map
    ("C-." . embark-act)
    ("C-," . embark-dwim))
  (:map minibuffer-local-map
    ("C-c C-c" . embark-collect)
    ("C-c C-e" . embark-export)
    ("C-c C-m" . embark-select)
    ("C-c C-a" . embark-act-all))

  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  (keymap-set global-map "C-." 'embark-act)
  (keymap-set global-map "C-," 'embark-dwim)

  (with-eval-after-load 'vertico
    (keymap-set vertico-map "C-." 'embark-act)
    (keymap-set vertico-map "C-," 'embark-dwim))

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
    '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
       nil
       (window-parameters (mode-line-format . none))))

  :custom
  (embark-indicators
    '(embark-which-key-indicator
       embark-highlight-indicator
       embark-isearch-highlight-indicator))

  :config
  ;;(setq embark-prompter 'embark-completing-read-prompter)
  (advice-add #'embark-completing-read-prompter
    :around #'embark-hide-which-key-indicator)

  :preface
  (defun embark-which-key-indicator ()
    "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
    (lambda (&optional keymap targets prefix)
      (if (null keymap)
        (which-key--hide-popup-ignore-command)
        (which-key--show-keymap
          (if (eq (plist-get (car targets) :type) 'embark-become)
            "Become"
            (format "Act on %s '%s'%s"
              (plist-get (car targets) :type)
              (embark--truncate-target (plist-get (car targets) :target))
              (if (cdr targets) "…" "")))
          (if prefix
            (pcase (lookup-key keymap prefix 'accept-default)
              ((and (pred keymapp) km) km)
              (_ (key-binding prefix 'accept-default)))
            keymap)
          nil nil t (lambda (binding)
                      (not (string-suffix-p "-argument" (cdr binding))))))))


  (defun embark-hide-which-key-indicator (fn &rest args)
    "Hide the which-key indicator immediately when using the completing-read prompter."
    (which-key--hide-popup-ignore-command)
    (let ((embark-indicators
            (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args))))

(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package ws-butler
  :hook (after-init . ws-butler-global-mode))


(provide 'core-editing)
;;; core-editing.el ends here
