;;; ai-remote-agent.el --- Remote AI agent launcher -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Remote agent launcher for Lima-hosted workflows.  It translates the
;; current project root into the corresponding Lima path and starts the
;; configured agent in a ghostel terminal.
;;
;;; Code:

(require 'project)

(declare-function ghostel-toggle "core-terminal")
(declare-function project-current "project")
(declare-function project-root "project")
(declare-function project-prefixed-buffer-name "project")

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
                  (concat (directory-file-name remote-prefix)
                          (substring (file-name-as-directory expanded)
                                     (length local-prefix))))))))
    (or mapped
        (user-error "No Lima path mapping configured for %s" expanded))))

(defun +ai-remote-agent ()
  "Toggle a Lima-hosted agent shell for the current project."
  (interactive)
  (unless my/ai-remote-agent-enable
    (user-error "Remote agents are disabled"))
  (let* ((project (project-current t))
         (local-root (project-root project))
         (remote-root (my/ai-remote-agent--map-path local-root))
         (buffer-name (project-prefixed-buffer-name
                       (format "%s-%s"
                               my/ai-remote-agent-instance-name
                               (symbol-name my/ai-remote-agent-backend))))
         (command (list "limactl" "shell" "--tty" "--start"
                        "--workdir" remote-root
                        my/ai-remote-agent-instance-name
                        "zsh" "-lc"
                        (symbol-name my/ai-remote-agent-backend))))
    (ghostel-toggle command buffer-name)))

(provide 'ai-remote-agent)
;;; ai-remote-agent.el ends here
