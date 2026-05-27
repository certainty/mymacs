;; -*- lexical-binding: t; -*-

(declare-function project-current "project")
(declare-function project-root "project")
(declare-function vterm "vterm")

(defun my/vterm-project-buffer-name ()
  "Return the vterm buffer name for the current project."
  (if-let* ((project (project-current nil))
            (root (project-root project))
            (name (file-name-nondirectory (directory-file-name root))))
      (format "*vterm:%s*" name)
    "*vterm*"))

(defun my/vterm-project-buffer ()
  "Return the current project vterm buffer."
  (get-buffer (my/vterm-project-buffer-name)))

(defun my/vterm-project ()
  "Open or reuse the vterm buffer for the current project."
  (interactive)
  (let* ((project (project-current nil))
         (default-directory (if project
                                (project-root project)
                              default-directory))
         (vterm-buffer-name (my/vterm-project-buffer-name)))
    (vterm)))

;;;###autoload
(defun my/toggle-vterm-project ()
  "Toggle the project vterm window."
  (interactive)
  (if-let* ((buffer (my/vterm-project-buffer))
            (window (get-buffer-window buffer t)))
      (delete-window window)
    (my/vterm-project)))

(provide 'my-terminal)
