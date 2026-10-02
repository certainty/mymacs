;;; my-notes.el --- Org note capture and navigation -*- lexical-binding: t; -*-

;;; Org setup
(use-package org
  :custom
  (org-directory (file-name-as-directory (expand-file-name my/org-directory)))
  (org-capture-templates
   `(("n" "Note" entry
      (file ,(expand-file-name "scratch.org" my/notes-directory))
      "* %<%H:%M> %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:")
     ("t" "Task" entry (file "todo.org")
      "* TODO %?\n")))
  (org-pretty-entities t)
  (org-startup-folded t)
  (org-hide-leading-stars t)
  (org-hide-emphasis-marker nil)
  (org-M-RET-may-split-lines nil)
  (org-insert-heading-respect-content t)
  (org-fontify-quote-and-verse-blocks t)
  (org-auto-align-tags t)
  (org-adapt-indentation nil)
  (org-startup-indented t)
  (org-src-preserve-indentation t)
  :config
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)
  ;; Prepend this specific rule so it wins before the windows catch-all.
  (add-to-list 'display-buffer-alist
               (cons "^CAPTURE-" (my/bottom-window-config 'org-capture-mode))))

;;; Denote
(use-package denote
  :ensure t
  :commands (denote)
  :custom
  (denote-directory (file-name-as-directory (expand-file-name my/notes-directory)))
  (denote-file-type 'org))

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
  (consult-find (my/notes--ensure-directory)))

(defun my/notes-ripgrep ()
  "Search the Org notes directory with Consult ripgrep."
  (interactive)
  (consult-ripgrep (my/notes--ensure-directory)))

(keymap-set my/notes-prefix-map "j" #'my/notes-capture)
(keymap-set my/notes-prefix-map "n" #'my/notes-denote-new)
(keymap-set my/notes-prefix-map "J" #'my/notes-open-scratch)
(keymap-set my/notes-prefix-map "e" #'my/notes-dired)
(keymap-set my/notes-prefix-map "f" #'my/notes-find-file)
(keymap-set my/notes-prefix-map "/" #'my/notes-ripgrep)

(provide 'my-notes)
;;; my-notes.el ends here
