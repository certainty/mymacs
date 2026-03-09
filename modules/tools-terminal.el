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
  :custom
  (vterm-toggle-fullscreen-p nil)
  (vterm-toggle-scope 'project)
  :init
  (my/window-rule! vterm-mode :align right :size 0.4 :select t)
  (my/window-rule! "\\*vterm\\*" :align right :size 0.4 :select t)
  (my/with-popper! "\\*vterm\\*"))

(use-package multi-vterm
  :commands (multi-vterm-project multi-vterm))


(provide 'tools-terminal)
