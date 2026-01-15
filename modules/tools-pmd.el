;;; tools-pmd.el --- Project metadata lookup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;;
;;; Code:

(require 'subr-x)

(defconst pmd--base-url "https://project-metadata.nwse.io"
  "Base URL for project metadata.")

(defconst pmd--projects-endpoint "projects"
  "Projects endpoint for project metadata.")

(defconst pmd--servicegroups-endpoint "service_groups"
  "Service groups endpoint for project metadata.")

(defconst pmd--teams-endpoint "teams"
  "Teams endpoint for project metadata.")

(defconst pmd--projects-json-url
  (format "%s/%s?format=json" pmd--base-url pmd--projects-endpoint)
  "Projects JSON endpoint.")

(defconst pmd--servicegroups-json-url
  (format "%s/%s?format=json" pmd--base-url pmd--servicegroups-endpoint)
  "Service groups JSON endpoint.")

(defconst pmd--teams-json-url
  (format "%s/%s?format=json" pmd--base-url pmd--teams-endpoint)
  "Teams JSON endpoint.")

(defun pmd--fetch-json (url)
  "Fetch JSON from URL and return parsed data."
  (require 'url)
  (require 'json)
  (let ((buffer (url-retrieve-synchronously url t t 10)))
    (unless buffer
      (user-error "PMD request failed"))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (let ((status (when (re-search-forward "^HTTP/[^ ]+ \\([0-9]+\\)" nil t)
                          (string-to-number (match-string 1)))))
            (unless (and status (<= 200 status 299))
              (error "PMD request failed (HTTP %s)" (or status "unknown"))))
          (unless (re-search-forward "\r?\n\r?\n" nil t)
            (error "PMD response headers not found"))
          (json-parse-buffer :object-type 'hash-table
                             :array-type 'list
                             :null-object nil))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(defun pmd--string (value)
  "Return VALUE as a string, or nil."
  (cond
    ((null value) nil)
    ((stringp value) value)
    (t (format "%s" value))))

(defun pmd--list-string (values)
  "Return VALUES as a comma-separated string."
  (when (listp values)
    (let ((items (delq nil (mapcar #'pmd--string values))))
      (when items
        (string-join items ", ")))))

(defun pmd--org-units-string (values)
  "Return org unit VALUES as a comma-separated string."
  (when (listp values)
    (let ((items
           (delq nil (mapcar (lambda (item)
                               (when (hash-table-p item)
                                 (pmd--string (gethash "org_unit" item))))
                             values))))
      (when items
        (string-join items ", ")))))

(defun pmd--project-display (project-id data)
  "Return display string for PROJECT-ID using DATA."
  (let ((name (pmd--string (gethash "name" data))))
    (if (and name (not (string-empty-p name)))
        (format "%s (%s)" project-id name)
      project-id)))

(defun pmd--project-candidate (project-id data)
  "Build a completion candidate for PROJECT-ID using DATA."
  (let ((display (pmd--project-display project-id data)))
    (propertize display
                'pmd-data data
                'pmd-id project-id
                'consult--candidate data)))

(defun pmd--projects-candidates ()
  "Return sorted project completion candidates."
  (let* ((projects (pmd--fetch-json pmd--projects-json-url))
         (candidates nil))
    (maphash
     (lambda (key data)
       (let ((project-id (or (pmd--string (gethash "id" data))
                             (pmd--string key))))
         (when project-id
           (push (pmd--project-candidate project-id data) candidates))))
     projects)
    (sort candidates #'string-lessp)))

(defun pmd--project-url (data)
  "Return the project URL for DATA."
  (let ((project-id (pmd--string (gethash "id" data))))
    (unless project-id
      (user-error "Project metadata missing id"))
    (format "%s/%s/%s" pmd--base-url pmd--projects-endpoint project-id)))

(defun pmd--browse-project (data)
  "Open project DATA in the browser."
  (browse-url (pmd--project-url data)))

(defun pmd--servicegroup-display (servicegroup-id data)
  "Return display string for SERVICEGROUP-ID using DATA."
  (let ((name (pmd--string (gethash "name" data))))
    (if (and name (not (string-empty-p name))
             (not (string= (downcase name) (downcase servicegroup-id))))
        (format "%s (%s)" servicegroup-id name)
      servicegroup-id)))

(defun pmd--servicegroup-candidate (servicegroup-id data)
  "Build a completion candidate for SERVICEGROUP-ID using DATA."
  (let ((display (pmd--servicegroup-display servicegroup-id data)))
    (propertize display
                'pmd-data data
                'pmd-id servicegroup-id
                'consult--candidate data)))

(defun pmd--servicegroups-candidates ()
  "Return sorted service group completion candidates."
  (let* ((servicegroups (pmd--fetch-json pmd--servicegroups-json-url))
         (candidates nil))
    (maphash
     (lambda (key data)
       (let ((servicegroup-id (or (pmd--string (gethash "id" data))
                                  (pmd--string key))))
         (when servicegroup-id
           (push (pmd--servicegroup-candidate servicegroup-id data) candidates))))
     servicegroups)
    (sort candidates #'string-lessp)))

(defun pmd--servicegroup-url (data)
  "Return the service group URL for DATA."
  (let ((servicegroup-id (pmd--string (gethash "id" data))))
    (unless servicegroup-id
      (user-error "Service group metadata missing id"))
    (format "%s/%s/%s" pmd--base-url pmd--servicegroups-endpoint servicegroup-id)))

(defun pmd--browse-servicegroup (data)
  "Open service group DATA in the browser."
  (browse-url (pmd--servicegroup-url data)))

(defun pmd--team-display (team-id data)
  "Return display string for TEAM-ID using DATA."
  (let ((name (pmd--string (gethash "name" data))))
    (if (and name (not (string-empty-p name))
             (not (string= (downcase name) (downcase team-id))))
        (format "%s (%s)" team-id name)
      team-id)))

(defun pmd--team-candidate (team-id data)
  "Build a completion candidate for TEAM-ID using DATA."
  (let ((display (pmd--team-display team-id data)))
    (propertize display
                'pmd-data data
                'pmd-id team-id
                'consult--candidate data)))

(defun pmd--teams-candidates ()
  "Return sorted team completion candidates."
  (let* ((teams (pmd--fetch-json pmd--teams-json-url))
         (candidates nil))
    (maphash
     (lambda (key data)
       (let ((team-id (or (pmd--string (gethash "id" data))
                          (pmd--string key))))
         (when team-id
           (push (pmd--team-candidate team-id data) candidates))))
     teams)
    (sort candidates #'string-lessp)))

(defun pmd--team-url (data)
  "Return the team URL for DATA."
  (let ((team-id (pmd--string (gethash "id" data))))
    (unless team-id
      (user-error "Team metadata missing id"))
    (format "%s/%s/%s" pmd--base-url pmd--teams-endpoint team-id)))

(defun pmd--browse-team (data)
  "Open team DATA in the browser."
  (browse-url (pmd--team-url data)))

;;;###autoload
(defun +pmd-projects ()
  "Select a project via consult and open it in the browser."
  (interactive)
  (require 'consult)
  (let* ((candidates (pmd--projects-candidates))
         (project (consult--read candidates
                                 :prompt "Project: "
                                 :sort nil
                                 :require-match t
                                 :category 'pmd-project
                                 :lookup #'consult--lookup-candidate)))
    (when project
      (pmd--browse-project project))))

;;;###autoload
(defun +pmd-servicegroups ()
  "Select a service group via consult and open it in the browser."
  (interactive)
  (require 'consult)
  (let* ((candidates (pmd--servicegroups-candidates))
         (servicegroup (consult--read candidates
                                      :prompt "Service group: "
                                      :sort nil
                                      :require-match t
                                      :category 'pmd-servicegroup
                                      :lookup #'consult--lookup-candidate)))
    (when servicegroup
      (pmd--browse-servicegroup servicegroup))))

;;;###autoload
(defun +pmd-teams ()
  "Select a team via consult and open it in the browser."
  (interactive)
  (require 'consult)
  (let* ((candidates (pmd--teams-candidates))
         (team (consult--read candidates
                              :prompt "Team: "
                              :sort nil
                              :require-match t
                              :category 'pmd-team
                              :lookup #'consult--lookup-candidate)))
    (when team
      (pmd--browse-team team))))

(with-eval-after-load 'marginalia
  (defun pmd--annotate-project (cand)
    "Annotate project CAND with metadata fields."
    (when-let ((data (get-text-property 0 'pmd-data cand)))
      (marginalia--fields
        ((pmd--string (gethash "service_group" data)) :face 'marginalia-type)
        ((pmd--string (gethash "team" data)) :face 'marginalia-value)
        ((pmd--string (gethash "product_lifecycle" data))
         :face 'marginalia-documentation)
        ((pmd--string (gethash "org_unit" data)) :face 'marginalia-key))))
  (defun pmd--annotate-servicegroup (cand)
    "Annotate service group CAND with metadata fields."
    (when-let ((data (get-text-property 0 'pmd-data cand)))
      (marginalia--fields
        ((pmd--string (gethash "current_lifecycle" data))
         :face 'marginalia-documentation)
        ((pmd--list-string (gethash "heads" data)) :face 'marginalia-value)
        ((pmd--org-units-string (gethash "org_units" data)) :face 'marginalia-key)
        ((pmd--list-string (gethash "cost_centres" data)) :face 'marginalia-type))))
  (defun pmd--annotate-team (cand)
    "Annotate team CAND with metadata fields."
    (when-let ((data (get-text-property 0 'pmd-data cand)))
      (marginalia--fields
        ((pmd--string (gethash "org_unit" data)) :face 'marginalia-key)
        ((pmd--string (gethash "head" data)) :face 'marginalia-value)
        ((pmd--list-string (gethash "contacts" data)) :face 'marginalia-documentation)
        ((pmd--string (gethash "cost_centre" data)) :face 'marginalia-type))))
  (add-to-list 'marginalia-annotators '(pmd-project pmd--annotate-project))
  (add-to-list 'marginalia-annotators '(pmd-servicegroup pmd--annotate-servicegroup))
  (add-to-list 'marginalia-annotators '(pmd-team pmd--annotate-team)))

(provide 'tools-pmd)
;;; tools-pmd.el ends here
