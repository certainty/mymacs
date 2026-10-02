;;; consult-pmd-marginalia.el --- Marginalia support for consult-pmd -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0") (marginalia "2.13"))
;;; Commentary:
;; Marginalia category annotators for consult-pmd.
;;; Code:

(require 'marginalia)
(require 'consult-pmd)

(defun pmd--marginalia-project-annotate (cand)
  "Return a Marginalia annotation for project candidate CAND."
  (when-let* ((data (pmd--candidate-data cand)))
    (marginalia--fields
     ((pmd--icon-team (gethash "team" data))
      :format "%-16s" :truncate 16 :face 'font-lock-variable-name-face)
     ((or (pmd--string (gethash "service_type" data)) "")
      :format "%-14s" :truncate 14 :face 'font-lock-type-face)
     ((or (pmd--string (gethash "org_unit" data)) "")
      :format "%-12s" :truncate 12 :face 'font-lock-variable-name-face)
     ((or (pmd--string (gethash "product_lifecycle" data)) "")
      :format "%-16s" :truncate 16 :face 'font-lock-doc-face)
     ((or (pmd--string (pmd--dig data "people" "head")) "")
      :format "%-18s" :truncate 18 :face 'success)
     ((or (pmd--list-string (pmd--dig data "people" "contact")) "")
      :format "%-28s" :truncate 28 :face 'font-lock-doc-face)
     ((pmd--icon-tags (pmd--list-string (gethash "tags" data)))
      :format "%-20s" :truncate 20 :face 'font-lock-constant-face))))

(defun pmd--marginalia-team-annotate (cand)
  "Return a Marginalia annotation for team candidate CAND."
  (when-let* ((data (pmd--candidate-data cand)))
    (marginalia--fields
     ((or (pmd--string (gethash "head" data)) "")
      :format "%-22s" :truncate 22 :face 'font-lock-string-face)
     ((or (pmd--string (gethash "email" data)) "")
      :format "%-30s" :truncate 30 :face 'font-lock-type-face)
     ((or (pmd--string (gethash "cost_centre" data)) "")
      :format "%-12s" :truncate 12 :face 'font-lock-constant-face)
     ((or (pmd--list-string (gethash "contacts" data)) "")
      :format "%-32s" :truncate 32 :face 'font-lock-doc-face))))

(defun pmd--marginalia-service-group-annotate (cand)
  "Return a Marginalia annotation for service-group candidate CAND."
  (when-let* ((data (pmd--candidate-data cand)))
    (marginalia--fields
     ((format "heads: %s" (or (pmd--list-string (gethash "heads" data)) ""))
      :format "%-32s" :truncate 32 :face 'font-lock-string-face)
     ((format "directors: %s" (or (pmd--list-string (gethash "directors" data)) ""))
      :format "%-36s" :truncate 36 :face 'success)
     ((or (pmd--string (gethash "description" data)) "")
      :format "%-42s" :truncate 42 :face 'font-lock-doc-face))))

(defun pmd--marginalia-person-annotate (cand)
  "Return a Marginalia annotation for person candidate CAND."
  (when-let* ((data (pmd--candidate-data cand)))
    (marginalia--fields
     ((pmd--icon-mail (gethash "email" data))
      :format "%-38s" :truncate 38 :face 'font-lock-string-face)
     ((pmd--icon-github (gethash "github_com" data))
      :format "%-32s" :truncate 32 :face 'font-lock-string-face))))

(dolist (entry '((pmd-project . pmd--marginalia-project-annotate)
                 (pmd-team . pmd--marginalia-team-annotate)
                 (pmd-service-group . pmd--marginalia-service-group-annotate)
                 (pmd-people . pmd--marginalia-person-annotate)))
  (setf (alist-get (car entry) marginalia-annotators)
        (list (cdr entry) 'builtin 'none)))

(provide 'consult-pmd-marginalia)
;;; consult-pmd-marginalia.el ends here
