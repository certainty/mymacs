;;; tools-terminal.el ---  Vterm -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(use-package vterm
  :commands vterm
  :custom
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t)
  :config
  ;; Better evil integration
  (advice-add 'evil-collection-vterm-insert
              :before (lambda () (vterm-reset-cursor-point))))

(use-package vterm-toggle
  :general
  (leader-def
    "ot" 'vterm-toggle
    "oT" 'vterm-toggle-cd)
  :custom
  (vterm-toggle-fullscreen-p nil)
  (vterm-toggle-scope 'project)
  :config
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                   (let ((buffer (get-buffer buffer-or-name)))
                     (with-current-buffer buffer
                       (or (equal major-mode 'vterm-mode)
                           (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                 (display-buffer-reuse-window display-buffer-in-side-window)
                 (reusable-frames . visible)
                 (size . right)
                 (window-height . 0.3))))

(provide 'tools-terminal)
