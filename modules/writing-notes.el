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
    "nN" 'denote-subdirectory
    "nt" 'denote-type
    "nd" 'denote-date
    "ns" 'denote-find
    "nt" 'denote-template

    "nl" '(:ignore t :which-key "links")
    "nll" 'denote-find-link
    "nlL" 'denote-find-backlink
    "nli" 'denote-link
    "nla" 'denote-add-links
    "nlb" 'denote-backlinks

    "nf" '(:ignore t :which-key "file")
    "nfr" 'denote-rename-file
    "nfR" 'denote-rename-file-using-front-matter

    "nff" 'denote-open-or-create
    "nfF" 'denote-open-or-create-with-command
    "on" '(:ignore t :which-key "notes")
    "onn" 'my/open-notes-path
    "ond" 'my/open-managed-documents-path)
  :hook (dired-mode . denote-dired-mode)
  :bind
  (:map dired-mode-map
    ("C-c C-d C-i" . denote-dired-link-marked-notes)
    ("C-c C-d C-r" . denote-dired-rename-files)
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)
    ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))
  :custom
  (denote-directory (list my/notes-path
                      my/managed-documents-path))
  (denote-known-keywords '("emacs" "philosophy" "common-lisp" "personal" "code" "idee" "reference" "auto" "versicherung" "finanzen"))

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

  (defun my/open-managed-documents-path ()
    (interactive)
    (dired my/managed-documents-path))


  (defalias 'denote-new 'denote)
  (defalias 'denote-find 'denote-open-or-create))

(use-package consult-denote)

;;;; Org Roam style backlinks for Denote
(with-eval-after-load 'denote
  (defun denote-show-backlinks-buffer ()
    "Show backlinks in a dedicated buffer."
    (interactive)
    (let ((file (buffer-file-name)))
      (when file
        (denote-backlinks)))))

(defun my/search-in-directory (dir)
  "Search in DIR using p-search."
  (let ((default-directory (expand-file-name dir)))
    (call-interactively #'p-search)))

(defun my/search-notes ()
  "Search in notes directory using p-search."
  (interactive)
  (my-search-in-directory my/notes-path))

(defun my/search-documents ()
  "Search in documents directory using p-search."
  (interactive)
  (my-search-in-directory my/managed-documents-path))


(defun my/search-org ()
  "Search in org directory using p-search."
  (interactive)
  (my-search-in-directory my/org-path))

(leader-def
  "sn" '(:ignore t :which-key "notes")
  "snn" 'denote-find
  "snf" 'consult-denote-find
  "sng" 'consult-denote-grep
  "sN" 'my/search-notes
  "sd" 'my/search-documents
  "so" 'my/search-org)

(provide 'writing-notes)
;;; writing-notes.el ends here
