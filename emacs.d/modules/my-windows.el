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

(defun my/side-window-config-allow-other-window (&optional mode slot)
  "Return a side-window configuration that permits `other-window'."
  (let ((config (my/side-window-config mode slot)))
    (setf (alist-get 'window-parameters config)
          '((no-other-window . nil) (no-delete-other-windows . t)))
    config))

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
        ("C-q" . quit-window)
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
  (window-divider-default-right-width 1)
  (window-divider-default-bottom-width 1)

  ;;;;; buffer arrangement
  (display-buffer-alist
   `(("\\*vc-log\\*" . ,(my/bottom-window-config nil 'display-buffer-reuse-window 0))
     ("\\*log-edit-files\\*" . ,(my/bottom-window-config 'special-mode 'display-buffer-reuse-window 1))
     ("^\\*vc-git.*\\*$" . ,(my/bottom-window-config 'special-mode))
     ("^\\*vc-dir\\*" . ,(my/side-window-config 'special-mode))
     ("\\*xref\\*" . ,(my/bottom-window-config 'special-mode))
     ("\\*\\(compilation\\|Occur\\|grep\\).*\\*" . ,(my/bottom-window-config 'special-mode))
     ("\\*\\(Help\\|compilation\\|Occur\\|grep\\|Flymake.*\\)\\*" . ,(my/side-window-config 'special-mode))
     (".*" (display-buffer-same-window))))

  :preface
  (defun +delete-other-windows (&optional window)
    "Delete all other windows, including special windows and popups."
    (interactive)
    (let ((ignore-window-parameters t))
      (delete-other-windows window)))

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
  :init
  (window-divider-mode))

(use-package winner
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

(use-package avy
  :ensure t
  :commands (avy-goto-word-0)
  :custom
  (avy-all-windows nil))

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
     "\\*Taskwarrior\\(?: Report\\| Task\\)?\\*"))
  :init
  (popper-mode +1)
  (popper-echo-mode +1))

(provide 'my-windows)
;;; my-windows.el ends here
