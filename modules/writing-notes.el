;;; writing-notes.el --- Note-taking with Denote -*- lexical-binding: t -*-

;;; Commentary:
;; Denote for note-taking with p-search and consult-notes integration

;;; Code:

;;;; Denote - Note-taking system
(use-package denote
  :hook
  ((dired-mode . denote-dired-mode)
    (denote-mode-hook . (lambda () (corfu-mode -1))))

  :preface
  (defun +browse-notes ()
    (interactive)
    (dired my/notes-path))

  (defun +browse-managed-documents ()
    (interactive)
    (dired my/managed-documents-path))

  :bind
  (:map dired-mode-map
    ("C-c C-d C-i" . denote-dired-link-marked-notes)
    ("C-c C-d C-r" . denote-dired-rename-files)
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)
    ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))

  :custom
  (denote-directory my/notes-path)

  ;; File naming
  (denote-file-type nil)                ; Use .org by default
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
  (setopt denote-known-keywords '("draft" "idea" "dump"))

  (when (my/context-private-p)
    ;; append private keywords
    (setopt denote-known-keywords
      (append denote-known-keywords
        '("emacs" "philosophy" "common-lisp" "personal" "code" "idee" "reference" "auto" "versicherung" "finanzen"))))

  (when (my/context-work-p)
    (setopt denote-kknown-keywords
      (append denote-known-keywords
        '("project" "meeting" "rfc" "adr" "runbook" "status" "api" "messaging" "bfx" "1on1"))))

  (denote-rename-buffer-mode 1)


  (defalias 'denote-new 'denote)
  (defalias 'denote-find 'denote-open-or-create))

(use-package consult-denote)

(use-package denote-silo
  :commands ( denote-silo-create-note
              denote-silo-open-or-create
              denote-silo-select-silo-then-command
              denote-silo-dired
              denote-silo-cd )
  :config
  (setq denote-silo-directories
    (list denote-directory
      my/library-path
      my/managed-documents-path)))

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

(defun +consult-notes ()
  "Consult notes using consult-denote."
  (interactive)
  (let ((default-directory (expand-file-name my/notes-path)))
    (call-interactively #'consult-denote-find)))

(defun +consult-grep-notes ()
  "Consult notes using consult-denote."
  (interactive)
  (let ((default-directory (expand-file-name my/notes-path)))
    (call-interactively #'consult-denote-grep)))

(defun +psearch-notes ()
  "Search in notes directory using psearch."
  (interactive)
  (my/search-in-directory my/notes-path))

(defun +psearch-documents ()
  "Search in documents directory using p-search."
  (interactive)
  (my/search-in-directory my/managed-documents-path))

(defun +psearch-org ()
  "Search in org directory using p-search."
  (interactive)
  (my/search-in-directory my/org-path))

(provide 'writing-notes)
;;; writing-notes.el ends here
