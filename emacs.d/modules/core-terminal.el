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
  ;; `display-buffer-alist' conditions must use a buffer matcher form.
  ;; A bare `ghostel-mode' symbol does not match there, so use
  ;; explicit `major-mode' rules for both the default and project names.
  (my/register-side-popup '(major-mode . ghostel-mode) t)
  (my/register-side-popup "^\\*ghostel\\*$" t t)
  (my/register-side-popup "^\\*.*-ghostel\\*$" t t))

(defun ghostel-toggle (command buffer-name)
  "Toggle a Ghostel buffer named BUFFER-NAME running COMMAND.
COMMAND may be a program string or a list whose car is the program
and whose cdr is the argument list.
If BUFFER-NAME exists, switch to it.  Otherwise create the buffer and
run COMMAND in it."
  (pcase-let* ((`(,program . ,args)
                (if (consp command)
                    command
                  (cons command nil)))
               (buffer (get-buffer buffer-name))
         (window (and buffer (get-buffer-window buffer t)))
         (display-action (append display-buffer--same-window-action
                                 '((category . comint)))))
    (cond
     (window
      (quit-window nil window))
     (buffer
      (pop-to-buffer buffer display-action))
     (t
      (setq buffer (get-buffer-create buffer-name))
      (ghostel-exec buffer program args)
      (pop-to-buffer buffer display-action)))))

(defun ghostel-toggle-project ()
  "Toggle a project-local Ghostel shell running interactive zsh."
  (interactive)
  (let* ((project (project-current t))
         (default-directory (project-root project))
         (buffer-name (project-prefixed-buffer-name "ghostel")))
    (ghostel-toggle '("/bin/zsh" "-i") buffer-name)))

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
  (my/register-side-popup '(major-mode . vterm-mode) t)
  (my/register-side-popup "\\*vterm\\*" t t))

(use-package multi-vterm
  :after vterm
  :commands (multi-vterm-project multi-vterm))

;;; Project integration
(with-eval-after-load 'project
  (add-to-list 'project-switch-commands '(ghostel-toggle-project "Terminal" ?t) t))

(provide 'core-terminal)
;;; core-terminal.el ends here
