;;; core-terminal.el --- Vterm and terminal emulation -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Terminal emulation using `vterm' and `ghostel'. Supports project-local
;; terminals and handles TRAMP connections for remote terminals.
;; Uses a meow passthrough state so that keys go straight to the
;; terminal. C-SPC dispatches to the leader map, and C-c ESC exits
;; to normal state.
;;
;;; Code:

;;; Meow passthrough state for terminals

(defvar meow-passthrough-keymap (make-keymap)
  "Keymap for meow passthrough state.")

(meow-define-state passthrough
  "Terminal passthrough state. All keys go to the terminal."
  :lighter " [T]"
  :keymap meow-passthrough-keymap)

(meow-define-keys 'passthrough
  '("C-SPC" . meow-keypad)
  '("C-c ESC" . meow-insert-exit))

;;; Ghostel

(use-package ghostel
  :init
  (my/register-side-popup 'ghostel-mode t nil)
  (my/register-side-popup "\\.*-ghostel\\*" t t))

;;; Vterm

(use-package vterm
  :commands vterm
  :custom
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t)
  (vterm-tramp-shells '(("ssh" "/bin/bash")
                         ("docker" "/bin/sh")
                         (t "/bin/sh"))))

(use-package vterm-toggle
  :after vterm
  :custom
  (vterm-toggle-fullscreen-p nil)
  (vterm-toggle-scope 'project)
  :init
  (my/register-side-popup 'vterm-mode t nil)
  (my/register-side-popup "\\*vterm\\*" t t))

(use-package multi-vterm
  :after vterm
  :commands (multi-vterm-project multi-vterm))

;;; Project integration
(with-eval-after-load 'project
  (add-to-list 'project-switch-commands '(ghostel-project "Terminal" ?t) t))

(provide 'core-terminal)
;;; core-terminal.el ends here
