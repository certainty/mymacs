;;; my-notes.el --- Org note capture and navigation -*- lexical-binding: t; -*-

(defvar my/notes--project-capture-file nil
  "Dynamically bound target for project note capture.")

(defun my/notes--project-note-info ()
  "Return the current project note path and its project root/name."
  (require 'project)
  (let* ((project (or (project-current)
                      (user-error "Current directory is not in a project")))
         (root (file-name-as-directory
                (expand-file-name (project-root project))))
         (name (project-name project))
         (filename (concat (replace-regexp-in-string "/" "-" name) ".org"))
         (directory (expand-file-name
                     "projects"
                     (expand-file-name my/notes-directory))))
    (list :root root
          :name name
          :directory directory
          :file (expand-file-name filename directory))))

(defun my/notes--ensure-project-note (info)
  "Create the project note described by INFO if it does not exist."
  (let ((directory (plist-get info :directory))
        (file (plist-get info :file)))
    (make-directory directory t)
    (unless (file-exists-p file)
      (with-temp-file file
        (insert (format "#+title: %s\n#+PROPERTY: PROJECT_PATH %s\n\n"
                        (plist-get info :name)
                        (plist-get info :root)))))
    file))

(defun my/notes-capture-project ()
  "Capture a top-level note in the current project note."
  (interactive)
  (let* ((info (my/notes--project-note-info))
         (my/notes--project-capture-file
          (my/notes--ensure-project-note info)))
    (org-capture nil "p")))

(defun my/notes-project-open ()
  "Open the note for the current project, if it exists."
  (interactive)
  (let* ((info (my/notes--project-note-info))
         (file (plist-get info :file)))
    (if (file-exists-p file)
        (find-file file)
      (user-error "No project note exists for %s" (plist-get info :name)))))

(defun my/notes-project-select ()
  "Choose and open a project note from the projects notes directory."
  (interactive)
  (let* ((directory (expand-file-name
                     "projects"
                     (expand-file-name my/notes-directory)))
         (files (and (file-directory-p directory)
                     (directory-files directory nil "[.]org$"))))
    (unless files
      (user-error "No project notes found in %s" directory))
    (find-file (expand-file-name
                (completing-read "Project note: " files nil t)
                directory))))

;;; Org setup
(use-package org
  :custom
  (org-hide-leading-stars nil)
  (org-indent-mode-turns-on-hiding-stars nil)
  (org-directory (file-name-as-directory (expand-file-name my/org-directory)))
  (org-capture-templates
   `(("n" "Note" entry
      (file ,(expand-file-name "scratch.org" my/notes-directory))
      "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:")
     ("p" "Project note" entry
      (file my/notes--project-capture-file)
      "* %U %?\n%a\n"
      :prepend t)
     ("t" "Task" entry (file "todo.org")
      "* TODO %?\n")))
  (org-pretty-entities t)
  (org-startup-folded t)
  (org-hide-emphasis-marker nil)
  (org-M-RET-may-split-lines nil)
  (org-insert-heading-respect-content t)
  (org-fontify-quote-and-verse-blocks t)
  (org-auto-align-tags t)
  (org-adapt-indentation nil)
  (org-startup-indented t)
  (org-src-preserve-indentation t)
  (org-todo-keyword-faces
   '(("TODO" . font-lock-keyword-face)
     ("DOING" . warning)
     ("BLOCKED" . error)
     ("DONE" . success)
     ("CANCELLED" . success)))
  :config
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)
  (dolist (face-and-height '((org-level-1 . 1.12)
                           (org-level-2 . 1.08)
                           (org-level-3 . 1.04)
                           (org-level-4 . 1.0)))
    (set-face-attribute (car face-and-height) nil :height (cdr face-and-height)))
  ;; Prepend this specific rule so it wins before the windows catch-all.
  (add-to-list 'display-buffer-alist
               (cons "^CAPTURE-" (my/bottom-window-config 'org-capture-mode))))

;;; Org bullets
(use-package org-superstar
  :ensure t
  :pin nongnu
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-headline-bullets-list '("◉" "○" "◈" "◇" "✳"))
  (org-superstar-prettify-item-bullets nil)
  (org-superstar-leading-bullet ?\s))

;;; Denote
(use-package denote
  :ensure t
  :hook (dired-mode . denote-dired-mode)
  :commands (denote)
  :custom
  (denote-directory (file-name-as-directory (expand-file-name my/notes-directory)))
  (denote-file-type 'org)

  :bind
  (:map my/notes-prefix-map
        ("j" . my/notes-capture)
        ("n" . my/notes-denote-new)
        ("J" . my/notes-open-scratch)
        ("e" . my/notes-dired)
        ("f" . my/notes-find-file)
        ("/" . my/notes-ripgrep))

  :config

  (defun my/notes--ensure-directory ()
    "Create and return `my/notes-directory'."
    (let ((directory (expand-file-name my/notes-directory)))
      (make-directory directory t)
      directory))

  (defun my/notes-denote-new ()
    "Create a Denote note in `denote-directory'."
    (interactive)
    (my/notes--ensure-directory)
    (call-interactively #'denote))

;;; Notes navigation
  (defun my/notes-capture ()
    "Capture an Org note to the default scratch file."
    (interactive)
    (my/notes--ensure-directory)
    (org-capture nil "n"))

  (defun my/notes-open-scratch ()
    "Open the default Org scratch file."
    (interactive)
    (find-file (expand-file-name "scratch.org" (my/notes--ensure-directory))))

  (defun my/notes-dired ()
    "Open the Org notes directory in Dired."
    (interactive)
    (dired (my/notes--ensure-directory)))

  (defun my/notes-find-file ()
    "Find a file in the Org notes directory with Consult."
    (interactive)
    (find-file (my/notes--ensure-directory)))

  (defun my/notes-ripgrep ()
    "Search the Org notes directory with Consult ripgrep."
    (interactive)
    (consult-ripgrep (my/notes--ensure-directory))))


(use-package markdown-ts-mode
  :mode
  ("\\.md\\'" . markdown-ts-mode)
  ("\\.markdown\\'" . markdown-ts-mode)
  ("\\.mdown\\'" . markdown-ts-mode)
  ("\\.mkdn\\'" . markdown-ts-mode)
  ("\\.mdwn\\'" . markdown-ts-mode))

(use-package flyspell
  :hook (text-mode . flyspell-mode)
  :commands (flyspell-mode flyspell-prog-mode)
  :custom
  (ispell-program-name "aspell")
  (ispell-dictionary "en_US")
  :config
  (keymap-set flyspell-mode-map "C-," nil))




(provide 'my-notes)
;;; my-notes.el ends here
