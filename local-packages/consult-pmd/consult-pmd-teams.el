;;; consult-pmd-teams.el --- Teams in project metatda -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;; Author: David Krentzlin
;; Keywords: tools, convenience
;;
;;; Code:

(require 'consult-pmd-core)

(defconst pmd--team-type 'pmd-team)

(defvar pmd--teams-history nil
  "History for PMD teams completion.")

(defun pmd--teams-display (data)
  "Return a display string for team metadata `DATA'."
  (let ((name (pmd--string (gethash "name" data)))
         (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name)
      name
      id)))

(defun pmd--teams-candidates ()
  "Return a list of team candidates for completion, sorted by name"
  (message "Fetching team metadata...")
  (let ((teams (pmd--fetch-entities pmd--team-type "teams" :format "json"))
         (candidates '()))
    (maphash
      (lambda (id value)
        (push (pmd--completion-candidate (pmd--teams-display value) pmd--team-type id) candidates))
      teams)
    (sort candidates #'string-lessp)))

;;;###autoload
(defun +pmd-teams ()
  "Consult project metadata teams."
  (interactive)
  (let ((candidates (pmd--teams-candidates)))
    (when-let ((team-id (consult--read
                          candidates
                          :prompt "PMD Teams: "
                          :category pmd--team-type
                          :history 'pmd--teams-history
                          :require-match t
                          :group (pmd--grouping-fn "org_unit")
                          :lookup #'consult--lookup-candidate
                          :sort nil)))
      (browse-url (pmd--make-url (format "teams/%s" team-id))))))

(eval-when-compile
  (require 'marginalia))

(with-eval-after-load 'marginalia
  (defun pmd--teams-annotate (cand)
    "Annotate team CAND with metadata fields."
    (when-let ((data (pmd--candidate-data cand)))
      (marginalia--fields
        ((pmd--string (gethash "head" data)) :face 'marginalia-string)
        ((pmd--string (gethash "email" data)) :face 'marginalia-type)
        ((pmd--string (pmd--list-string (gethash "contacts" data))) :face 'marginalia-documentation))))

  (add-to-list 'marginalia-annotators `(,pmd--team-type pmd--teams-annotate)))

(provide 'consult-pmd-teams)
