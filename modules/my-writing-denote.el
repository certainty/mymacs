;;; my-writing-denote.el --- Denote -*- lexical-binding: t; -*-

(use-package denote
  :hook
  ((text-mode . denote-fontify-links-mode-maybe)
   (dired-mode . denote-dired-mode))
  :general
  (dired-mode-map
   "C-c C-d C-i" '("denote mark" . denote-dired-link-marked-notes)
   "C-c C-d C-r" '("denote rename" . denote-dired-rename-files)
   "C-c C-d C-k" '("denote-rename*" . denote-dired-rename-marked-files-with-keywords)
   "C-c C-d C-R" '("denote-rename-fm" . denote-dired-rename-marked-files-using-front-matter))
  (my-writing-keymap
   "n" '("Denote" . denote)
   "N" '("Denote dired" . denote-dired)
   "s" '("Search" . denote-grep)
   "r" '("Rename" . denote-rename-file)
   "R" '("Rename-fm" . denote-rename-file-using-front-matter))

  :config
  (setq denote-directory (expand-file-name "~/NewWork/Notes/"))
  (setq denote-known-keywords '("area" "project" "archive" "resource" "nw1" "messaging" "xws" "pmd" "cloud_migration" "emacs" "dea"))
  (setq denote-save-buffers nil)
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-prompts '(title keywords))
  (setq denote-excluded-directories-regexp nil)
  (setq denote-keywords-to-not-infer-regexp nil)
  (setq denote-rename-confirmations '(rewrite-front-matter modify-file-name))
  (setq denote-date-prompt-use-org-read-date t)
  (denote-rename-buffer-mode 1))

(use-package consult-notes
  :defer t
  :general
  (my-writing-keymap
   "b" '("Browse" . consult-notes)
   "F" '("Search*" . consult-notes-search-in-all-notes))

  :custom
  (consult-notes-denote-files-function
   (function
    (lambda ()
      (denote-directory-files nil nil t "#.*#$")))) ;; text-only and no auto-saved files

  (consult-notes-file-dir-sources
   `(("Notes" ?n ,(expand-file-name "~/NewWork/Notes"))))

  :config
  (consult-notes-org-headings-mode)
  (consult-notes-denote-mode))

(use-package denote-explore)


(provide 'my-writing-denote)
