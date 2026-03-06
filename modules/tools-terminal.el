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
  :bind
  (:map +do
    ("t" . vterm-toggle)
    ("T" . vterm-toggle-cd))
  :custom
  (vterm-toggle-fullscreen-p nil)
  (vterm-toggle-scope 'project)
  :init
  (my/window-rule! vterm-mode :align bottom :size 0.3 :select t)
  (my/with-popper! "\\*vterm\\*"))


(provide 'tools-terminal)
