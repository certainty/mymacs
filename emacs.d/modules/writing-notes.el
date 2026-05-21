;;; writing-notes.el --- Note-taking with Denote -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Denote-based note system with consult integration.  Notes live in
;; `my/notes-path' (defined in core-config).  Uses consult-denote for
;; completing-read search/grep over notes.
;;
;;; Code:

;;; Helpers

(defun +browse-notes ()
  "Open notes directory in dired."
  (interactive)
  (dired my/notes-path))

(defun +notes-find ()
  "Find or create a note via consult-denote."
  (interactive)
  (let ((default-directory (expand-file-name my/notes-path)))
    (call-interactively #'consult-denote-find)))

(defun +notes-grep ()
  "Grep notes directory via consult-denote."
  (interactive)
  (let ((default-directory (expand-file-name my/notes-path)))
    (call-interactively #'consult-denote-grep)))

;;; Denote

(use-package denote
  :straight t
  :hook (dired-mode . denote-dired-mode)
  :bind
  (:map dired-mode-map
    ("C-c C-d C-i" . denote-dired-link-marked-notes)
    ("C-c C-d C-r" . denote-dired-rename-files)
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords))
  :custom
  (denote-directory my/notes-path)
  (denote-file-type nil)
  (denote-prompts '(title keywords))
  (denonte-sort-keywords t)
  (denote-infer-keywords t)
  (denote-date-prompt-use-org-read-date t)
  (denote-link-button-action #'find-file)
  :config
  (setopt denote-known-keywords my/notes-keywords)
  (denote-rename-buffer-mode 1))

;;; Consult-Denote (completing-read integration)

(use-package consult-denote
  :straight t
  :after denote
  :config
  (consult-denote-mode 1))

(provide 'writing-notes)
;;; writing-notes.el ends here
