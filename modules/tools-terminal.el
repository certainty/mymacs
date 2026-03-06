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




(use-package vterm-posframe
  :straight (vterm-posframe
              :type git
              :host github
              :repo "Ghibranalj/vterm-posframe")
  :after (vterm posframe))

(defgroup my/tui-posframe nil
  "Toggle TUIs in vterm-posframes."
  :group 'tools)

(defcustom my/tui-posframe-width 110 :type 'integer)
(defcustom my/tui-posframe-height 32 :type 'integer)

;; Allow to load TUIs in a posframe terminal
(use-package posframe)

(defun my/tui--process-live-p (buf)
  (when (buffer-live-p buf)
    (let ((p (get-buffer-process buf)))
      (and p (process-live-p p)))))

(defun my/tui--ensure-running (buffer-name cmd &optional dir)
  "Return BUFFER-NAME (vterm). Start CMD if not already running.
If DIR is non-nil, use it as `default-directory` when starting."
  (let ((buf (get-buffer buffer-name)))
    (unless (buffer-live-p buf)
      (setq buf (get-buffer-create buffer-name))
      (with-current-buffer buf
        (let ((default-directory (or dir default-directory)))
          (vterm-mode)
          (vterm-send-string cmd)
          (vterm-send-return))))
    ;; If the vterm process died, restart + re-run CMD
    (unless (my/tui--process-live-p buf)
      (with-current-buffer buf
        (let ((inhibit-read-only t)) (erase-buffer))
        (let ((default-directory (or dir default-directory)))
          (vterm-mode)
          (vterm-send-string cmd)
          (vterm-send-return))))
    buf))

(defun my/tui-toggle (key cmd &optional dir)
  "Toggle a dedicated posframe for a TUI identified by KEY running CMD."
  (interactive)
  (unless (posframe-workable-p)
    (user-error "Posframe not supported in this Emacs session"))
  (let* ((bufname (format "*tui:%s*" key))
          (pfname  (format " *tui-posframe:%s* " key))
          (buf (my/tui--ensure-running bufname cmd dir)))
    (if (posframe--frame pfname)
      (posframe-hide pfname)
      (posframe-show
        pfname
        :buffer buf
        :poshandler #'posframe-poshandler-frame-center
        :width my/tui-posframe-width
        :height my/tui-posframe-height
        :accept-focus t
        :respect-header-line t
        :respect-mode-line t)
      ;; focus
      (select-frame-set-input-focus (posframe--frame pfname))
      (with-current-buffer buf (goto-char (point-max))))))

(defun my/tui-hide-current ()
  (interactive)
  (let ((name (buffer-name)))
    (when (and name (string-match "\\*tui:\\([^*]+\\)\\*" name))
      (posframe-hide (format " *tui-posframe:%s* " (match-string 1 name))))))

(with-eval-after-load 'vterm
  (define-key vterm-mode-map (kbd "<escape>") #'my/tui-hide-current))

(provide 'tools-terminal)
