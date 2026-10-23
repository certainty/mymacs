;;; my-windows.el --- Windows and popup layout -*- lexical-binding: t; -*-

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

(defun my/tab-window-config (&optional name)
  "Return a display-buffer action for a tab named NAME."
  `((display-buffer-in-tab)
    (tab-name . ,(or name "VC"))))

(defun my/side-window-config-allow-other-window (&optional mode slot)
  "Return a side-window configuration that permits `other-window'."
  (let ((config (my/side-window-config mode slot)))
    (setf (alist-get 'window-parameters config)
          '((no-other-window . nil) (no-delete-other-windows . t)))
    config))

(defun my/bottom-window-config (&optional mode reuse-action slot)
  (my/window-config
   (or reuse-action 'display-buffer-reuse-mode-window)
   'bottom
   'window-height
   0.25
   mode
   slot))

(defun my/push-display-buffer-rule (condition action)
  "Add a display rule for CONDITION and ACTION at the front of the rules."
  (push (cons condition action) display-buffer-alist))


(use-package window
  :commands (+delete-other-windows)
  :bind
  (:map mymacs-mode-map
        ("C-q" . quit-window)
        ("C-Q" . kill-current-buffer)
        ([remap delete-other-windows] . +delete-other-windows)
        ("C-x {" . +resize-window-shrink)
        ("C-x }" . +resize-window-enlarge)
        ("C-x w u" . winner-undo)
        ("C-x w U" . winner-redo)
        ("C-x w t"   . window-layout-transpose)
        ("C-x w r"   . window-layout-rotate-clockwise)
        ("C-x w f h" . window-layout-flip-leftright)
        ("C-x w f v" . window-layout-flip-topdown)
        ("C-<" . previous-buffer)
        ("C->" . next-buffer))
  (:map my/leader-map
        ("|" . split-window-right))
  (:repeat-map my/window-resize-repeat-map
               ("{" . +resize-window-shrink)
               ("}" . +resize-window-enlarge))
  :custom
  ;; prefer splitting to the side
  (split-height-threshold nil)
  (split-width-threshold 80)
  (even-window-sizes nil)
  (window-combination-resize t)
  (window-divider-default-right-width 1)
  (window-divider-default-bottom-width 1)

;;;;; buffer arrangement
  ;; Keep the catch-all last; feature-specific rules should be prepended.
  (display-buffer-alist
   `(("^\\*\\(vc-.*\\|log-edit-files\\)\\*\\(<[0-9]+>\\)?$" . ,(my/tab-window-config "VC"))
     ("\\*xref\\*" . ,(my/bottom-window-config 'special-mode))
     ("\\*eldoc.*\\'" . ,(my/bottom-window-config 'special-mode 'display-buffer-reuse-window -1))
     ("\\*\\(compilation\\|Occur\\|grep\\).*\\*" . ,(my/bottom-window-config 'special-mode))
     ("\\*\\(Help\\|compilation\\|Occur\\|grep\\|Flymake.*\\)\\*" . ,(my/side-window-config 'special-mode))
     ("^\\*sly-compilation" . ,(my/side-window-config-allow-other-window))
     ("^\\*sly-mrepl" . ,(my/side-window-config-allow-other-window))
     (".*" (display-buffer-same-window))))

  :preface
  (defun +delete-other-windows (&optional window)
    "Delete all other windows, including special windows and popups."
    (interactive)
    (let ((ignore-window-parameters t))
      (delete-other-windows window)))

  (defun my--resize-window (delta)
    "Resize the selected window by DELTA along its immediate split."
    (let ((horizontal (window-combined-p nil t)))
      (unless (or horizontal (window-combined-p))
        (user-error "Selected window is not split"))
      (window-resize nil delta horizontal)))

  (defun +resize-window-shrink (&optional count)
    "Shrink the selected window by five units, or prefix COUNT units."
    (interactive "P")
    (my--resize-window (- (if count (prefix-numeric-value count) 5))))

  (defun +resize-window-enlarge (&optional count)
    "Enlarge the selected window by five units, or prefix COUNT units."
    (interactive "P")
    (my--resize-window (if count (prefix-numeric-value count) 5)))


  :init
  (window-divider-mode)
  :config
  (defun my/configure-window-dividers (&optional frame)
    "Configure window dividers for FRAME's display type."
    (setq frame (or frame (selected-frame)))
    (dolist (face '(window-divider
                    window-divider-first-pixel
                    window-divider-last-pixel
                    vertical-border))
      (if (display-graphic-p frame)
          (set-face-attribute face frame :foreground 'unspecified :background 'unspecified)
        (set-face-attribute face frame :foreground "#4f5f73" :background "#4f5f73"))))
  (add-hook 'window-setup-hook #'my/configure-window-dividers)
  (add-hook 'after-make-frame-functions #'my/configure-window-dividers)
  (my/configure-window-dividers)
  (my/push-display-buffer-rule
   "^\\*Current PR\\*$"
   (my/side-window-config 'special-mode)))

(use-package winner
  :bind
  (:map mymacs-mode-map
        ("C-c [" . winner-undo))
  :init
  (winner-mode 1))

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
  (popper-reference-buffers
   '("\\*Messages\\*"
     "Output\\*$"
     "\\*Async Shell Command\\*"
     "^\\*sly-compilation"
     "^\\*sly-mrepl"
     "\\*eldoc.*\\'"))
  :init
  (popper-mode +1)
  (popper-echo-mode +1))

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
      ("Text"
       (or
        (mode . markdown-ts-mode)
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
  (defun my/ibuffer-setup ()
    "Apply stable defaults to Ibuffer buffers."
    (require 'ibuf-ext)
    (ibuffer-switch-to-saved-filter-groups "default")
    (ibuffer-auto-mode 1)))

(provide 'my-windows)
;;; my-windows.el ends here
