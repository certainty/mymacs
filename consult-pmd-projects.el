;;; consult-pmd-projects.el --- Project metadata lookup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;; Author: David Krentzlin
;; Keywords: tools, convenience
;;
;;; Code:

(defconst pmd--project-data-fields
  '("id" "name" "service_group" "service_type" "documentation" "complexity_score" "maintainability_score" "team" "org_unit" "product_lifecycle" "git" "msteams" "people")
  "Fields to include in project completion candidate data.")

;;;###autoload
(defun +pmd-projects ()
  "Select a project via consult and open it in the browser."
  (interactive)
  (let* ((candidates (pmd--projects-fetch-candidates))
          (project (consult--read candidates
                     :prompt "Project: "
                     :sort nil
                     :require-match t
                     :category 'pmd-project
                     :group (pmd--grouping-fn "service_group")
                     :lookup #'consult--lookup-candidate)))
    (when project-id
      (browse-url (pmd--make-url (format "projects/%s" project-id))))))


;; TODO: add caching
(cl-defun pmd--projects-fetch-all ()
  "Fetch all projects from PMD."
  (pmd--fetch-entities 'pmd-project "projects" :format "json"))

(cl-defun pmd--projects-fetch-candidates ()
  "Create completion candidates for all projects.
The candidates are already sorted.
See also `pmd--completion-candidate' for details on the associated data of each candidate."
  (let ((projects-data (pmd--projects-fetch-all)))
    (cl-loop
      with candidates = nil
      for project-key being the hash-keys of projects-data
      do (let* ((project-data (apply #'pmd--slice-hash (gethash project-key projects-data) pmd--project-data-fields))
                 (project-id (pmd--dig project-data "id"))
                 (project-name (pmd--dig project-data "name"))
                 (display (if (pmd--present-p project-name) project-name project-id)))
           (push (pmd--completion-candidate display 'pmd-project project-id) candidates))
      finally (return (sort candidates #'string-lessp)))))

;;; Marginalia integration

(with-eval-after-load 'marginalia
  (defun pmd--projects-annotate (cand)
    "Annotate project CAND with metadata fields."
    (when-let ((data (pmd--candidate-data cand)))
      (let ((project-head (pmd--dig data "people" "head")))
        (marginalia--fields
          ((pmd--string (gethash "org_unit" data)) :face 'marginalia-symbol)
          ((pmd--string (gethash "team" data)) :face 'marginalia-type)
          ((pmd--string project-head) :face 'marginalia-key)
          ((pmd--string (gethash "product_lifecycle" data)) :face 'marginalia-documentation)))))

  (add-to-list 'marginalia-annotators '(pmd-project pmd--projects-annotate)))

;;; Embark integration

(with-eval-after-load 'embark
  (defun pmd--embark-target ()
    "Embark target finder for PMD candidates in Vertico. Returns (ENTITY-TYPE . PROPS).
As a side-effect, sets `pmd--embark-target-data' to the candidate data.
This allows us to transfer the data to the embark action functions. "
    (when (and (boundp 'vertico--input) vertico--input
            (fboundp 'vertico--candidate))
      (when (eq vertico--input t)
        (when (fboundp 'vertico--exhibit) (vertico--exhibit)))
      (when-let* ((cand  (vertico--candidate))
                   (entity (get-text-property 0 'pmd-type cand)))
        (when entity
          (let* ((id (pmd--candidate-id cand)))
            `(,entity ,id . nil))))))

  (add-to-list 'embark-target-finders #'pmd--embark-target)

  (defun +pmd-open-teams-channel (project-id)
    "Open the Teams channel for project target."
    (interactive "sProjectId")
    (message "p: %S" project-id))

  (defvar-keymap pmd-project-embark-map :doc "Embark actions for PMD project candidates"
    "t" '+pmd-open-teams-channel
    "r" '+pmd-open-repo-url
    "R" '+pmd-copy-repo-url
    "s" '+pmd-copy-repo-slug
    "e" '+pmd-copy-project-contact-email
    "y" '+pmd-copy-project-metadata-url)

  (add-to-list 'embark-keymap-alist '(pmd-project . pmd-project-embark-map))

  (with-eval-after-load 'consult-gh
    (defun +pmd-search-repo (cand)
      "Open GitHub search for the repository of project CAND."
      (interactive "sProject: ")
      (let* ((data (pmd--candidate-data cand))
              (account (pmd--dig data "git" "account"))
              (repo (pmd--dig data "git" "repo")))
        (unless (and account repo)
          (user-error "No repository information for project"))
        (consult-gh-search-code "" (format "%s/%s" account repo))))

    (keymap-set pmd-project-embark-map "S" #'+pmd-search-repo)))

(provide 'consult-pmd-projects)
