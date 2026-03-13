;;; consult-pmd-servicegroups.el --- servicegroups in project metatda -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;; Author: David Krentzlin
;; Keywords: tools, convenience
;;
;;; Code:

(require 'consult-pmd-core)

(defconst pmd--servicegroup-type 'pmd-service-group)

(defvar pmd--servicegroups-history nil
  "History for PMD servicegroups completion.")

(defun pmd--servicegroups-display (data)
  "Return a display string for servicegroup metadata `DATA'."
  (let ((name (pmd--string (gethash "name" data)))
         (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name)
      name
      id)))

(defun pmd--servicegroups-candidates ()
  "Return a list of servicegroups candidates for completion, sorted by name"
  (message "Fetching servicegroups metadata...")
  (let ((teams (pmd--fetch-entities pmd--servicegroup-type "service_groups"))
         (candidates '()))
    (maphash
      (lambda (id value)
        (push (pmd--completion-candidate (pmd--servicegroups-display value) pmd--servicegroup-type id) candidates))
      teams)
    (sort candidates #'string-lessp)))

;;;###autoload
(defun +pmd-servicegroups ()
  "Consult project metadata servicegroups."
  (interactive)
  (let ((candidates (pmd--servicegroups-candidates)))
    (when-let* ((team-id (consult--read
                           candidates
                           :prompt "PMD ServiceGroup: "
                           :category pmd--servicegroup-type
                           :history 'pmd--servicegroups-history
                           :lookup #'consult--lookup-candidate
                           :require-match t
                           :sort nil)))
      (pmd--browse-url (format "service_groups/%s" team-id)))))

(eval-when-compile
  (require 'marginalia))

(with-eval-after-load 'marginalia
  (defun pmd--servicegroups-annotate (cand)
    "Annotate team CAND with metadata fields."
    (when-let* ((data (pmd--candidate-data cand)))
      (marginalia--fields
        ((format "heads: %s" (pmd--string (pmd--list-string (gethash "heads" data)))) :face 'marginalia-string :width 50)
        ((format "directors: %s" (pmd--string (pmd--list-string (gethash "directors" data)))) :face 'marginalia-on :width 50)
        ((pmd--string (gethash "description" data)) :face 'marginalia-documentation :truncate 80))))

  (add-to-list 'marginalia-annotators `(,pmd--servicegroup-type pmd--servicegroups-annotate)))

(provide 'consult-pmd-servicegroups)
