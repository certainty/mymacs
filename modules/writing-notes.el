;;; writing-notes.el --- Note-taking with Denote -*- lexical-binding: t -*-

;;; Commentary:
;; Denote for note-taking with p-search and consult-notes integration

;;; Code:

;;;; Denote - Note-taking system
(use-package denote
  :general
  (leader-def
    "n" '(:ignore t :which-key "notes")
    "nn" 'denote
    "nN" 'denote-type
    "nd" 'denote-date
    "ns" 'denote-subdirectory
    "nt" 'denote-template

    "ni" 'denote-link
    "nI" 'denote-add-links
    "nb" 'denote-backlinks

    "nr" 'denote-rename-file
    "nR" 'denote-rename-file-using-front-matter

    "nf" 'denote-open-or-create
    "nF" 'denote-open-or-create-with-command
    "gN" 'my/open-notes-path)
  :hook (dired-mode . denote-dired-mode)
  :bind
  (:map dired-mode-map
    ("C-c C-d C-i" . denote-dired-link-marked-notes)
    ("C-c C-d C-r" . denote-dired-rename-files)
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)
    ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))
  :custom
  (denote-directory (list my/notes-path my/managed-documents-path))
  (denote-known-keywords '("emacs" "philosophy" "common-lisp" "personal" "code" "idea" "reference"))

  ;; File naming
  (denote-file-type nil) ; Use .org by default
  (denote-prompts '(title keywords))
  (denote-sort-keywords t)
  (denote-infer-keywords t)
  (denote-date-prompt-use-org-read-date t)

  (denote-templates
    '((default . "")
       (idea . "* Overview\n\n* Details\n\n* Next Steps\n")))

  ;; Links
  (denote-link-button-action #'find-file)

  :config
  (denote-rename-buffer-mode 1)
  (defun my/open-notes-path ()
    (interactive)
    (dired my/notes-path))

  (defalias 'denote-new 'denote)
  (defalias 'denote-find 'denote-open-or-create))

;;;; Consult-notes - Search notes with consult
(use-package consult-notes
  :commands (consult-notes
              consult-notes-search-in-all-notes)
  :general
  (leader-def
    "nN" 'consult-notes
    "n/" 'consult-notes-search-in-all-notes
    "gn" 'consult-notes
    "sn" 'consult-notes-search-in-all-notes)
  :custom
  (consult-notes-file-dir-sources
    `(("Notes"  ?n ,(expand-file-name my/notes-path))
       ("Org"    ?o ,(expand-file-name my/org-path))
       ("Documents" ?d ,(expand-file-name my/managed-documents-path))))
  :config
  ;; Use ripgrep for searching note contents
  (consult-notes-denote-mode 1)

  ;; Set up search command
  (when (executable-find "rg")
    (setq consult-notes-use-rg t)))

(use-package denote-explore)

(use-package denote-silo
  :commands (denote-silo-create-note
              denote-silo-open-or-create
              denote-silo-select-silo-then-command
              denote-silo-dired
              denote-silo-cd))

;;;; Org Roam style backlinks for Denote
(with-eval-after-load 'denote
  (defun denote-show-backlinks-buffer ()
    "Show backlinks in a dedicated buffer."
    (interactive)
    (let ((file (buffer-file-name)))
      (when file
        (denote-backlinks)))))

(provide 'writing-notes)
;;; writing-notes.el ends here
