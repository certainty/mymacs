;;; ai-remote-agent.el --- Remote AI agent launcher -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Remote agent launcher for Lima-hosted workflows.  It translates the
;; current project root into the corresponding Lima path and runs the
;; Lima command directly in a ghostel buffer so startup errors stay visible.
;;
;;; Code:

(require 'project)

(declare-function ghostel-exec "ghostel")
(declare-function project-current "project")
(declare-function project-root "project")
(declare-function project-prefixed-buffer-name "project")

(defun my/ai-remote-agent--buffer-name (suffix)
  "Return a project-prefixed remote agent buffer name with SUFFIX."
  (project-prefixed-buffer-name
    (format "%s-%s"
      my/ai-remote-agent-instance-name
      suffix)))

(defun my/ai-remote-agent--map-path (local-path)
  "Translate LOCAL-PATH to the corresponding Lima path.
The first matching prefix in `my/ai-remote-agent-path-map' wins."
  (let ((expanded (directory-file-name (expand-file-name local-path)))
         (mapped nil))
    (dolist (entry my/ai-remote-agent-path-map)
      (pcase-let ((`(,local-root . ,remote-root) entry))
        (let ((local-prefix (file-name-as-directory (expand-file-name local-root)))
               (remote-prefix (file-name-as-directory remote-root)))
          (when (and (not mapped)
                  (string-prefix-p local-prefix
                    (file-name-as-directory expanded)))
            (setq mapped
              (expand-file-name
                (substring (file-name-as-directory expanded)
                  (length local-prefix))
                remote-prefix))))))
    (or mapped
      (user-error "No Lima path mapping configured for %s" expanded))))

(defun my/ai-remote-agent--shell-buffer-name (suffix)
  "Return a project-prefixed ghostel buffer name with SUFFIX."
  (my/ai-remote-agent--buffer-name suffix))

(defun my/ai-remote-agent--ensure-shell (buffer-name command)
  "Start COMMAND in BUFFER-NAME if needed and display the buffer.
COMMAND is a list whose car is the program and whose cdr is argv."
  (let* ((buffer (get-buffer-create buffer-name))
         (process (get-buffer-process buffer)))
    (unless (and process (process-live-p process))
      (ghostel-exec buffer (car command) (cdr command)))
    (display-buffer buffer)
    buffer))

(defun my/ai-remote-agent--nudge-window (buffer)
  "Resize BUFFER's window slightly to trigger a terminal resize event."
  (let ((window (get-buffer-window buffer t)))
    (when (window-live-p window)
      (condition-case nil
          (window-resize window 1 nil 'safe)
        (error nil)))))

(defun my/ai-remote-agent--lima-shell-command (remote-root &rest shell-args)
  "Return a Lima shell command for REMOTE-ROOT and SHELL-ARGS."
  (append
    (list "limactl" "shell" "--tty" "--start"
      "--workdir" remote-root
      my/ai-remote-agent-instance-name)
    shell-args))


(defun +ai-remote-agent-shell ()
  "Toggle a Lima zsh shell in a ghostel buffer."
  (interactive)
  (unless my/ai-remote-agent-enable
    (user-error "Remote agents are disabled"))
  (let* ((project (project-current t))
         (local-root (project-root project))
         (remote-root (my/ai-remote-agent--map-path local-root)))
    (my/ai-remote-agent--ensure-shell
      (my/ai-remote-agent--shell-buffer-name "shell")
      (my/ai-remote-agent--lima-shell-command remote-root "zsh" "-l"))))

(defun +ai-remote-agent ()
  "Toggle the configured remote agent in the Lima instance."
  (interactive)
  (unless my/ai-remote-agent-enable
    (user-error "Remote agents are disabled"))
  (let* ((project (project-current t))
         (local-root (project-root project))
         (remote-root (my/ai-remote-agent--map-path local-root))
         (buffer-name (my/ai-remote-agent--shell-buffer-name
                        (symbol-name my/ai-remote-agent-backend))))
    (my/ai-remote-agent--nudge-window
      (my/ai-remote-agent--ensure-shell
      buffer-name
       (my/ai-remote-agent--lima-shell-command
         remote-root "zsh" "-lc"
         (symbol-name my/ai-remote-agent-backend))))))

(provide 'ai-remote-agent)
;;; ai-remote-agent.el ends here
