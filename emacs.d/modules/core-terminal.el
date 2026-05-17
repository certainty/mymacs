;;; core-terminal.el --- Vterm and terminal emulation -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Terminal emulation using `vterm'. Supports project-local terminals
;; and handles TRAMP connections for remote terminals.
;;
;;; Code:

(use-package ghostel)

(defun my/vterm-setup ()
  "Configure vterm buffer for meow insert state."
  (setq-local meow-cursor-type 'bar))

(use-package vterm
  :commands vterm
  :custom
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t)
  (vterm-tramp-shells '(("ssh" "/bin/bash")
                         ("docker" "/bin/sh")
                         (t "/bin/sh")))
  :hook (vterm-mode . my/vterm-setup))

(use-package vterm-toggle
  :after vterm
  :custom
  (vterm-toggle-fullscreen-p nil)
  (vterm-toggle-scope 'project)
  :config
  (my/register-side-popup 'vterm-mode t nil)
  (my/register-side-popup "\\*vterm\\*" t t))

(use-package multi-vterm
  :after vterm
  :commands (multi-vterm-project multi-vterm))

;;; Project integration
(with-eval-after-load 'project
  (add-to-list 'project-switch-commands '(vterm-toggle "Terminal" ?t) t))

(provide 'core-terminal)
;;; core-terminal.el ends here
