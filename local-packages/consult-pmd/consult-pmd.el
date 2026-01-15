;;; consult-pmd.el --- Project metadata lookup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;; Author: David Krentzlin
;; Keywords: tools, convenience
;;
;;; Code:

(eval-when-compile
  (require 'marginalia))

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

(defvar pmd--projects-cache nil
  "Cache of project metadata keyed by project id.")

(defconst pmd--project-fields
  '((name . "Name")
    (service_group . "Service group")
    (team . "Team")
    (product_lifecycle . "Lifecycle")
    (org_unit . "Org unit"))
  "Fields available for project filtering.")

(defconst pmd--servicegroup-fields
  '((name . "Name")
    (current_lifecycle . "Lifecycle")
    (heads . "Heads")
    (org_units . "Org units")
    (cost_centres . "Cost centres"))
  "Fields available for service group filtering.")

(defconst pmd--team-fields
  '((name . "Name")
    (org_unit . "Org unit")
    (head . "Head")
    (contacts . "Contacts")
    (cost_centre . "Cost centre"))
  "Fields available for team filtering.")

(defun pmd--metadata-url (endpoint id)
  "Return metadata URL for ENDPOINT and ID."
  (format "%s/%s/%s" pmd--base-url endpoint id))

(defun pmd--field-label (fields field)
  "Return display label for FIELD in FIELDS."
  (or (cdr (assq field fields)) (symbol-name field)))

(defun pmd--select-field (fields prompt)
  "Select a field from FIELDS using PROMPT."
  (let* ((labels (mapcar #'cdr fields))
         (default (or (cdr (assq 'name fields)) (car labels)))
         (choice (completing-read prompt labels nil t nil nil default)))
    (or (car (rassoc choice fields)) 'name)))

(defun pmd--candidate-display (cand)
  "Return display string for candidate CAND."
  (or (get-text-property 0 'display cand) cand))

(defun pmd--sort-candidates (candidates)
  "Sort CANDIDATES by display string."
  (sort candidates
        (lambda (left right)
          (string-lessp (pmd--candidate-display left)
                        (pmd--candidate-display right)))))

(defun pmd--make-candidate (display data id &optional search index)
  "Build a candidate string with DISPLAY, DATA, and ID.
When SEARCH is non-nil, it is used for matching and DISPLAY is shown."
  (let* ((display (or display ""))
         (search (when search (string-trim search)))
         (raw (if search
                  (progn
                    (unless (fboundp 'consult--tofu-encode)
                      (require 'consult))
                    (concat search (consult--tofu-encode (or index 0))))
                display)))
    (when (string-empty-p raw)
      (setq raw (consult--tofu-encode (or index 0))))
    (let ((cand (copy-sequence raw)))
      (add-text-properties 0 (length cand)
                           `(pmd-data ,data pmd-id ,id consult--candidate ,data)
                           cand)
      (when search
        (put-text-property 0 (length cand) 'display display cand))
      cand)))

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

(defun pmd--copy-to-kill-ring (label value)
  "Copy VALUE to the kill ring and report LABEL."
  (kill-new value)
  (message "Copied %s: %s" label value))

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

(defun pmd--project-candidate (project-id data &optional search index)
  "Build a completion candidate for PROJECT-ID using DATA."
  (pmd--make-candidate (pmd--project-display project-id data)
                       data
                       project-id
                       search
                       index))

(defun pmd--project-field-value (data field)
  "Return DATA value for project FIELD as a string."
  (pcase field
    ('name (or (pmd--string (gethash "name" data))
               (pmd--string (gethash "id" data))
               ""))
    ('service_group (or (pmd--string (gethash "service_group" data)) ""))
    ('team (or (pmd--string (gethash "team" data)) ""))
    ('product_lifecycle (or (pmd--string (gethash "product_lifecycle" data)) ""))
    ('org_unit (or (pmd--string (gethash "org_unit" data)) ""))
    (_ "")))

(defun pmd--candidate-id (cand)
  "Return candidate id extracted from CAND."
  (cond
    ((hash-table-p cand) (pmd--string (gethash "id" cand)))
    ((stringp cand)
     (or (get-text-property 0 'pmd-id cand)
         (let ((trimmed (string-trim cand)))
           (when (string-match "\\`\\([^[:space:]]+\\)" trimmed)
             (match-string 1 trimmed)))))
    ((consp cand)
     (or (pmd--candidate-id (car cand))
         (pmd--candidate-id (cdr cand))))
    (t nil)))

(defun pmd--project-id-from-cand (cand)
  "Return project id extracted from CAND."
  (pmd--candidate-id cand))

(defun pmd--project-json-url (project-id)
  "Return project JSON URL for PROJECT-ID."
  (format "%s/%s/%s?format=json" pmd--base-url pmd--projects-endpoint project-id))

(defun pmd--project-data-from-cand (cand)
  "Return project data from completion CAND."
  (let ((data (cond
               ((hash-table-p cand) cand)
               ((stringp cand) (get-text-property 0 'pmd-data cand))
               ((consp cand)
                (or (and (hash-table-p (car cand)) (car cand))
                    (and (hash-table-p (cdr cand)) (cdr cand))
                    (and (stringp (car cand))
                         (get-text-property 0 'pmd-data (car cand)))
                    (and (stringp (cdr cand))
                         (get-text-property 0 'pmd-data (cdr cand)))))
               (t nil))))
    (or data
        (when-let ((project-id (pmd--project-id-from-cand cand)))
          (or (and (hash-table-p pmd--projects-cache)
                   (gethash project-id pmd--projects-cache))
              (pmd--fetch-json (pmd--project-json-url project-id))))
        (user-error "No project data available"))))

(defun pmd--project-msteams-url (data)
  "Return the Microsoft Teams channel URL for project DATA."
  (when-let ((msteams (gethash "msteams" data)))
    (when (hash-table-p msteams)
      (pmd--string (gethash "channel_url" msteams)))))

(defun pmd--project-repo-url (data)
  "Return the repository URL for project DATA."
  (when-let ((git (gethash "git" data)))
    (when (hash-table-p git)
      (let ((server (pmd--string (gethash "server_url" git)))
            (account (pmd--string (gethash "account" git)))
            (repo (pmd--string (gethash "repo" git))))
        (when (and server account repo)
          (format "%s/%s/%s"
                  (string-remove-suffix "/" server)
                  account
                  repo))))))

(defun pmd--project-repo-slug (data)
  "Return the repository slug (ORG/REPO) for project DATA."
  (when-let ((git (gethash "git" data)))
    (when (hash-table-p git)
      (let ((account (pmd--string (gethash "account" git)))
            (repo (pmd--string (gethash "repo" git))))
        (when (and account repo)
          (format "%s/%s" account repo))))))

(defun pmd--projects-candidates (&optional field)
  "Return sorted project completion candidates.
When FIELD is non-nil, match candidates by FIELD values."
  (let* ((projects (pmd--fetch-json pmd--projects-json-url))
         (candidates nil)
         (index 0))
    (setq pmd--projects-cache projects)
    (maphash
     (lambda (key data)
       (let ((project-id (or (pmd--string (gethash "id" data))
                             (pmd--string key))))
         (when project-id
           (setq index (1+ index))
           (push (pmd--project-candidate
                  project-id
                  data
                  (when field (pmd--project-field-value data field))
                  index)
                 candidates))))
     projects)
    (pmd--sort-candidates candidates)))

(defun pmd--project-url (data)
  "Return the project URL for DATA."
  (let ((project-id (pmd--string (gethash "id" data))))
    (unless project-id
      (user-error "Project metadata missing id"))
    (pmd--metadata-url pmd--projects-endpoint project-id)))

(defun pmd--browse-project (data)
  "Open project DATA in the browser."
  (browse-url (pmd--project-url data)))

(defun +pmd-browse-project-msteams (cand)
  "Open the Teams channel for project CAND."
  (interactive "sProject: ")
  (let* ((data (pmd--project-data-from-cand cand))
         (url (pmd--project-msteams-url data)))
    (unless url
      (user-error "No Teams channel URL for project"))
    (browse-url url)))

(defun +pmd-copy-project-url (cand)
  "Copy the repository URL for project CAND."
  (interactive "sProject: ")
  (let* ((data (pmd--project-data-from-cand cand))
         (url (pmd--project-repo-url data)))
    (unless url
      (user-error "No repository URL for project"))
    (pmd--copy-to-kill-ring "repo URL" url)))

(defun +pmd-copy-project-repo-slug (cand)
  "Copy the repository slug (ORG/REPO) for project CAND."
  (interactive "sProject: ")
  (let* ((data (pmd--project-data-from-cand cand))
         (slug (pmd--project-repo-slug data)))
    (unless slug
      (user-error "No repository slug for project"))
    (pmd--copy-to-kill-ring "repo slug" slug)))

(defun +pmd-copy-project-metadata-url (cand)
  "Copy the project metadata URL for project CAND."
  (interactive "sProject: ")
  (let* ((data (pmd--project-data-from-cand cand))
         (url (pmd--project-url data)))
    (pmd--copy-to-kill-ring "project metadata URL" url)))

(defun +pmd-copy-servicegroup-metadata-url (cand)
  "Copy the service group metadata URL for service group CAND."
  (interactive "sService group: ")
  (let ((servicegroup-id (pmd--candidate-id cand)))
    (unless servicegroup-id
      (user-error "No service group id available"))
    (pmd--copy-to-kill-ring
     "service group metadata URL"
     (pmd--metadata-url pmd--servicegroups-endpoint servicegroup-id))))

(defun +pmd-copy-team-metadata-url (cand)
  "Copy the team metadata URL for team CAND."
  (interactive "sTeam: ")
  (let ((team-id (pmd--candidate-id cand)))
    (unless team-id
      (user-error "No team id available"))
    (pmd--copy-to-kill-ring
     "team metadata URL"
     (pmd--metadata-url pmd--teams-endpoint team-id))))

(defun pmd--servicegroup-display (servicegroup-id data)
  "Return display string for SERVICEGROUP-ID using DATA."
  (let ((name (pmd--string (gethash "name" data))))
    (if (and name (not (string-empty-p name))
             (not (string= (downcase name) (downcase servicegroup-id))))
        (format "%s (%s)" servicegroup-id name)
      servicegroup-id)))

(defun pmd--servicegroup-candidate (servicegroup-id data &optional search index)
  "Build a completion candidate for SERVICEGROUP-ID using DATA."
  (pmd--make-candidate (pmd--servicegroup-display servicegroup-id data)
                       data
                       servicegroup-id
                       search
                       index))

(defun pmd--servicegroup-field-value (data field)
  "Return DATA value for service group FIELD as a string."
  (pcase field
    ('name (or (pmd--string (gethash "name" data))
               (pmd--string (gethash "id" data))
               ""))
    ('current_lifecycle (or (pmd--string (gethash "current_lifecycle" data)) ""))
    ('heads (or (pmd--list-string (gethash "heads" data)) ""))
    ('org_units (or (pmd--org-units-string (gethash "org_units" data)) ""))
    ('cost_centres (or (pmd--list-string (gethash "cost_centres" data)) ""))
    (_ "")))

(defun pmd--servicegroups-candidates (&optional field)
  "Return sorted service group completion candidates.
When FIELD is non-nil, match candidates by FIELD values."
  (let* ((servicegroups (pmd--fetch-json pmd--servicegroups-json-url))
         (candidates nil)
         (index 0))
    (maphash
     (lambda (key data)
       (let ((servicegroup-id (or (pmd--string (gethash "id" data))
                                  (pmd--string key))))
         (when servicegroup-id
           (setq index (1+ index))
           (push (pmd--servicegroup-candidate
                  servicegroup-id
                  data
                  (when field (pmd--servicegroup-field-value data field))
                  index)
                 candidates))))
     servicegroups)
    (pmd--sort-candidates candidates)))

(defun pmd--servicegroup-url (data)
  "Return the service group URL for DATA."
  (let ((servicegroup-id (pmd--string (gethash "id" data))))
    (unless servicegroup-id
      (user-error "Service group metadata missing id"))
    (pmd--metadata-url pmd--servicegroups-endpoint servicegroup-id)))

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

(defun pmd--team-candidate (team-id data &optional search index)
  "Build a completion candidate for TEAM-ID using DATA."
  (pmd--make-candidate (pmd--team-display team-id data)
                       data
                       team-id
                       search
                       index))

(defun pmd--team-field-value (data field)
  "Return DATA value for team FIELD as a string."
  (pcase field
    ('name (or (pmd--string (gethash "name" data))
               (pmd--string (gethash "id" data))
               ""))
    ('org_unit (or (pmd--string (gethash "org_unit" data)) ""))
    ('head (or (pmd--string (gethash "head" data)) ""))
    ('contacts (or (pmd--list-string (gethash "contacts" data)) ""))
    ('cost_centre (or (pmd--string (gethash "cost_centre" data)) ""))
    (_ "")))

(defun pmd--teams-candidates (&optional field)
  "Return sorted team completion candidates.
When FIELD is non-nil, match candidates by FIELD values."
  (let* ((teams (pmd--fetch-json pmd--teams-json-url))
         (candidates nil)
         (index 0))
    (maphash
     (lambda (key data)
       (let ((team-id (or (pmd--string (gethash "id" data))
                          (pmd--string key))))
         (when team-id
           (setq index (1+ index))
           (push (pmd--team-candidate
                  team-id
                  data
                  (when field (pmd--team-field-value data field))
                  index)
                 candidates))))
     teams)
    (pmd--sort-candidates candidates)))

(defun pmd--team-url (data)
  "Return the team URL for DATA."
  (let ((team-id (pmd--string (gethash "id" data))))
    (unless team-id
      (user-error "Team metadata missing id"))
    (pmd--metadata-url pmd--teams-endpoint team-id)))

(defun pmd--browse-team (data)
  "Open team DATA in the browser."
  (browse-url (pmd--team-url data)))

;;;###autoload
(defun +pmd-projects (arg)
  "Select a project via consult and open it in the browser."
  (interactive "P")
  (require 'consult)
  (let* ((field (when arg
                  (pmd--select-field pmd--project-fields "Project field: ")))
         (prompt (if field
                     (format "Project (%s): "
                             (pmd--field-label pmd--project-fields field))
                   "Project: "))
         (candidates (pmd--projects-candidates field))
         (project (consult--read candidates
                                 :prompt prompt
                                 :sort nil
                                 :require-match t
                                 :category 'pmd-project
                                 :lookup #'consult--lookup-candidate)))
    (when project
      (pmd--browse-project project))))

(with-eval-after-load 'embark
  (defvar pmd-project-embark-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "t") #'+pmd-browse-project-msteams)
      (define-key map (kbd "u") #'+pmd-copy-project-metadata-url)
      (define-key map (kbd "y") #'+pmd-copy-project-url)
      (define-key map (kbd "s") #'+pmd-copy-project-repo-slug)
      map)
    "Embark actions for PMD project candidates.")
  (defvar pmd-servicegroup-embark-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "u") #'+pmd-copy-servicegroup-metadata-url)
      map)
    "Embark actions for PMD service group candidates.")
  (defvar pmd-team-embark-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "u") #'+pmd-copy-team-metadata-url)
      map)
    "Embark actions for PMD team candidates.")
  (add-to-list 'embark-keymap-alist '(pmd-project . pmd-project-embark-map))
  (add-to-list 'embark-keymap-alist '(pmd-servicegroup . pmd-servicegroup-embark-map))
  (add-to-list 'embark-keymap-alist '(pmd-team . pmd-team-embark-map)))

;;;###autoload
(defun +pmd-servicegroups (arg)
  "Select a service group via consult and open it in the browser."
  (interactive "P")
  (require 'consult)
  (let* ((field (when arg
                  (pmd--select-field pmd--servicegroup-fields "Service group field: ")))
         (prompt (if field
                     (format "Service group (%s): "
                             (pmd--field-label pmd--servicegroup-fields field))
                   "Service group: "))
         (candidates (pmd--servicegroups-candidates field))
         (servicegroup (consult--read candidates
                                      :prompt prompt
                                      :sort nil
                                      :require-match t
                                      :category 'pmd-servicegroup
                                      :lookup #'consult--lookup-candidate)))
    (when servicegroup
      (pmd--browse-servicegroup servicegroup))))

;;;###autoload
(defun +pmd-teams (arg)
  "Select a team via consult and open it in the browser."
  (interactive "P")
  (require 'consult)
  (let* ((field (when arg
                  (pmd--select-field pmd--team-fields "Team field: ")))
         (prompt (if field
                     (format "Team (%s): "
                             (pmd--field-label pmd--team-fields field))
                   "Team: "))
         (candidates (pmd--teams-candidates field))
         (team (consult--read candidates
                              :prompt prompt
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

(provide 'consult-pmd)
;;; consult-pmd.el ends here
