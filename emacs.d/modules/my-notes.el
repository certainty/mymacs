;;; my-notes.el --- Notebook navigation -*- lexical-binding: t; -*-

(defun my/notes-root ()
  "Return the configured zk notebook directory."
  (let ((directory (or my/notes-directory (getenv "ZK_NOTEBOOK_DIR"))))
    (unless (and (stringp directory) (file-directory-p directory))
      (user-error "Set my/notes-directory or ZK_NOTEBOOK_DIR to an existing zk notebook"))
    (file-name-as-directory (expand-file-name directory))))

(defun my/notes-open-scratch ()
  "Open the notebook scratch note."
  (interactive)
  (find-file (expand-file-name "scratch.md" (my/notes-root))))

(defun my/notes-dired ()
  "Open the zk notebook in Dired."
  (interactive)
  (dired (my/notes-root)))

(defun my/notes-find-file ()
  "Find a file in the zk notebook with Consult."
  (interactive)
  (consult-find (my/notes-root)))

(defun my/notes-ripgrep ()
  "Search the zk notebook with Consult ripgrep."
  (interactive)
  (consult-ripgrep (my/notes-root)))

(keymap-set my/notes-prefix-map "j" #'my/notes-open-scratch)
(keymap-set my/notes-prefix-map "e" #'my/notes-dired)
(keymap-set my/notes-prefix-map "f" #'my/notes-find-file)
(keymap-set my/notes-prefix-map "/" #'my/notes-ripgrep)

(provide 'my-notes)
;;; my-notes.el ends here
