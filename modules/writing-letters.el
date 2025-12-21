;;; writing-letters.el --- support to write and export letters  -*- lexical-binding: t; -*-

;; does not QUITE work yet
(with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes
    '("scrlttr2"
       "\\documentclass{scrlttr2}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\setkomavar{fromname}{%s}
\\setkomavar{fromaddress}{%s}
\\setkomavar{fromphone}{%s}
\\setkomavar{fromemail}{%s}
\\setkomavar{subject}{%s}
\\begin{document}
\\begin{letter}{%s}
\\opening{Sehr geehrte %s,}"
       ("\\closing{Beste Gruesse}" . NIL)
       ("\\end{letter}" . nil)
       ("\\end{document}" . nil))))

(defun my/org-letter-export (backend)
  (when (eq backend 'latex)
    (setq org-export-latex-extra
      (format
        "\\setkomavar{fromname}{%s}
\\setkomavar{fromaddress}{%s}
\\setkomavar{fromphone}{%s}
\\setkomavar{fromemail}{%s}
\\setkomavar{subject}{%s}"
        (org-entry-get nil "SENDER_NAME" t)
        (org-entry-get nil "SENDER_ADDRESS" t)
        (org-entry-get nil "SENDER_PHONE" t)
        (org-entry-get nil "SUBJECT" t)))))

(add-hook 'org-export-before-processing-hook #'my/org-letter-export)

(use-package org-contacts
  :after org
  :config
  (setq org-contacts-files (list (expand-file-name "contacts.org" org-directory))))

(use-package emacs
  :general
  (leader-def
    "Wl" 'my/denote-letter-from-contact)
  :init
  (defun my/org-contact-data (name)
    "Return an alist of properties for contact NAME."
    (with-current-buffer (find-file-noselect (car org-contacts-files))
      (org-map-entries
        (lambda ()
          (when (string= (org-get-heading t t t t) name)
            `((name . ,name)
               (street . ,(org-entry-get nil "STREET"))
               (zip . ,(org-entry-get nil "ZIP"))
               (city . ,(org-entry-get nil "CITY"))
               (country . ,(org-entry-get nil "COUNTRY"))
               (email . ,(org-entry-get nil "EMAIL")))))
        nil 'file)))

  (defun org-contacts-names ()
    "Return a list of all contact names from `org-contacts-files`."
    (let (names)
      (dolist (file org-contacts-files)
        (when (file-exists-p file)
          (with-current-buffer (find-file-noselect file)
            (org-map-entries
              (lambda ()
                (push (org-get-heading t t t t) names))
              nil 'file))))
      (delete-dups names)))

  (defun my/denote-letter-from-contact ()
    "Create a new Denote letter for a selected Org contact."
    (interactive)
    (require 'denote)
    (require 'org-contacts)
    (require 'yasnippet)

    (let* ((contact-name
             (completing-read
               "Recipient: "
               (org-contacts-names)))
            (contact (my/org-contact-data contact-name))
            (keywords '("letter"))
            (file
              (denote
                contact-name
                keywords
                nil
                "org")))
      (find-file file)

      (setq-local
        RECIPIENT_NAME contact-name
        RECIPIENT_STREET (alist-get 'street contact)
        RECIPIENT_ZIP (alist-get 'zip contact)
        RECIPIENT_CITY (alist-get 'city contact)
        RECIPIENT_COUNTRY (alist-get 'country contact))

      (yas-expand-snippet
        (yas-lookup-snippet "letter" 'org-mode)))))

(provide 'writing-letters)
