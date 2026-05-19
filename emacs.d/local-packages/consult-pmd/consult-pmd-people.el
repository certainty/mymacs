;; consult-pmd-people.el --- people in project metatda -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;; Author: David Krentzlin
;; Keywords: tools, convenience
;;
;;; Code:

(require 'consult-pmd-core)

(defconst pmd--people-type 'pmd-people)

(defvar pmd--people-history nil
  "History for PMD people completion.")

(defun pmd--people-display (data)
  "Return a display string for people metadata `DATA'."
  (let ((name (pmd--string (gethash "display_name" data)))
         (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name)
      name
      id)))

(defun pmd--people-candidates ()
  "Return a list of people candidates for completion, sorted by name"
  (message "Fetching people metadata...")
  (let ((people (pmd--fetch-entities pmd--people-type "emails"))
         (candidates '()))
    (maphash
      (lambda (id value)
        (push (pmd--completion-candidate (pmd--people-display value) pmd--people-type id) candidates))
      people)
    (sort candidates #'string-lessp)))

;;;###autoload
(defun +pmd-people ()
  "Consult project metadata people."
  (interactive)
  (let ((candidates (pmd--people-candidates)))
    (when-let* ((person-id (consult--read
                             candidates
                             :prompt "PMD People: "
                             :category pmd--people-type
                             :history 'pmd--people-history
                             :lookup #'consult--lookup-candidate
                             :require-match t
                             :sort nil)))
      (let ((data (pmd--recover-entity pmd--people-type person-id)))
        (browse-url (format "https://github.com/%s" (pmd--string (gethash "github_com" data))))))))

(eval-when-compile
  (require 'marginalia))

(with-eval-after-load 'marginalia
  (defun pmd--people-annotate (cand)
    "Annotate team CAND with metadata fields."
    (when-let* ((data (pmd--candidate-data cand)))
      (marginalia--fields
        ((pmd--icon-mail (gethash "email" data)) :face 'marginalia-string :width 40)
        ((pmd--icon-github (gethash "github_com" data)) :face 'marginalia-string))))

  (add-to-list 'marginalia-annotators `(,pmd--people-type pmd--people-annotate)))

(with-eval-after-load 'embark
  (defvar-keymap pmd-people-embark-map
    "e" '+pmd-copy-person-email)

  (defun +pmd-copy-person-email (person-id)
    "Copy the email address of PERSON-ID to the clipboard."
    (when-let* ((data (pmd--recover-entity pmd--people-type person-id))
                 (email (pmd--string (gethash "email" data))))
      (kill-new email)
      (message "Copied email: %s" email)))

  (add-to-list 'embark-keymap-alist `(,pmd--people-type . pmd-people-embark-map)))


(provide 'consult-pmd-people)
