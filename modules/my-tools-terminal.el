;;; my-tools-terminal.sel --- terminal -*- lexical-binding: t; -*-
(use-package vterm
  :commands
  (vterm-toggle)
  :general
  (my-open-keymap
   "T" '("Terminal" . vterm-toggle)))

(use-package multi-vterm
  :after popper
  :general
  (my-open-keymap
   "t" '("Terminal*" . multi-vterm-project))
  :config
  (add-to-list 'popper-reference-buffers 'vterm-mode)
  (add-to-list 'display-buffer-alist
    '((lambda (buffer-or-name _)
        (let ((buffer (get-buffer buffer-or-name)))
          (with-current-buffer buffer
            (or (equal major-mode 'vterm-mode)
              (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
       (display-buffer-reuse-window display-buffer-in-side-window)
       (side . right)
       (reusable-frames . visible)
       (window-height . 0.5))))

(provide 'my-tools-terminal)
