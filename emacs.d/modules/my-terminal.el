;;; my-terminal.el --- Terminal and Taskwarrior TUI integration -*- lexical-binding: t; -*-

;;;; terminal
(use-package clipetty
  :ensure t
  :pin "melpa"
  :config
  (global-clipetty-mode 1))

(use-package vterm
  :ensure t
  :pin "melpa"
  :commands (vterm vterm-send-string vterm-send-return)
  :hook
  (vterm-mode . my/vterm-setup-meow)
  :preface
  (defun my/vterm-setup-meow ()
    "Keep Meow disabled in VTerm buffers."
    (add-hook 'meow-mode-hook #'my/disable-meow-locally nil t)
    (my/disable-meow-locally)))

(use-package vterm-toggle
  :ensure t
  :pin "melpa"
  :bind
  (:map my/leader-map
        ("$" . vterm-toggle))
  :custom
  (vterm-toggle-scope 'project)
  (vterm-toggle-project-root t)
  :preface
  (declare-function vterm "vterm" (&optional buffer-name))
  (declare-function vterm-send-string "vterm" (string &optional no-send))
  (declare-function vterm-send-return "vterm" ())

  (defconst my/taskwarrior-tui-buffer-name "*vterm-taskwarrior*"
    "Name of the dedicated Taskwarrior terminal buffer.")

  (defun my/vterm-toggle-project-buffer-p (buffer)
    "Return non-nil when BUFFER belongs to the project terminal pool."
    (not (equal (buffer-name buffer) my/taskwarrior-tui-buffer-name)))

  (defun my/taskwarrior-tui-toggle ()
    "Toggle the dedicated Taskwarrior TUI buffer."
    (interactive)
    (require 'vterm)
    (let ((buffer (get-buffer my/taskwarrior-tui-buffer-name)))
      (if-let* ((window (and buffer (get-buffer-window buffer 0))))
          (quit-window nil window)
        (if buffer
            (pop-to-buffer buffer)
          (unless (executable-find "taskwarrior-tui")
            (user-error "taskwarrior-tui is not on PATH"))
          (vterm my/taskwarrior-tui-buffer-name)
          (vterm-send-string "exec taskwarrior-tui" t)
          (vterm-send-return)))))
  :init
  (push `("\\*vterm.*\\*" . ,(my/side-window-config)) display-buffer-alist)
  (push `("\\*vterm-taskwarrior\\*" . ,(my/side-window-config-allow-other-window))
        display-buffer-alist)
  :config
  (add-to-list 'vterm-toggle-togglable-buffer-functions
               #'my/vterm-toggle-project-buffer-p))

(provide 'my-terminal)
;;; my-terminal.el ends here
