;;; consult-pmd.el --- Project metadata lookup -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0"))
;;; Commentary:
;; Consult helpers for internal project metadata.
;;
;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'bookmark)
(require 'consult)
(require 'browse-url)
(require 'subr-x)
(require 'url-parse)

(defvar embark-keymap-alist)
(declare-function consult-gh-dired "ext:consult-gh")
(declare-function consult-gh-search-code "ext:consult-gh")

;;;; Core

(defgroup consult-pmd nil
  "Project metadata helpers."
  :group 'tools)

(defcustom pmd-base-url ""
  "Base URL for project metadata."
  :type 'string
  :group 'consult-pmd)

(defcustom pmd-api-key nil
  "PMD API key override.
When nil, resolve the value from `auth-source'."
  :type '(choice (const :tag "Resolve from auth-source" nil)
                 string)
  :group 'consult-pmd)

(defcustom pmd-auth-source-user "pmd-api-key"
  "Auth-source user to search when resolving the PMD API key."
  :type 'string
  :group 'consult-pmd)

(defcustom pmd-cache-duration 300
  "Duration in seconds for which fetched PMD entities are cached."
  :type 'integer
  :group 'consult-pmd)

(defconst pmd--amqp-catalog-url
  "https://project-metadata.nwse.io/amqp_catalog.json"
  "URL for the AMQP catalog JSON feed.")

(defconst pmd--amqp-namespace-type 'pmd-amqp-namespace)

(defvar pmd--entity-catalog-data (make-hash-table)
  "Store full JSON catalogs by entity type for detail views.")

(defun pmd--keyword->string (key)
  "Convert keyword KEY to string without leading colon."
  (format "%s" (substring (symbol-name key) 1)))

(defun pmd--plist->lol (plist)
  "Convert PLIST to a list of lists."
  (cl-loop for (key value) on plist by #'cddr
           collect (list (pmd--keyword->string key) value)))

(defun pmd--string (value)
  "Return VALUE as a string, or nil."
  (cond
   ((null value) nil)
   ((stringp value) value)
   ((eq value :false) "false")
   ((eq value t) "true")
   (t (format "%s" value))))

(defun pmd--list-string (values)
  "Return VALUES as a comma-separated string."
  (when (listp values)
    (let ((items (delq nil (mapcar #'pmd--string values))))
      (when items
        (string-join items ", ")))))

(defun pmd--present-p (value)
  "Return t if VALUE is non-nil and not an empty string."
  (and value
       (or (not (stringp value))
           (not (string-empty-p value)))))

(defun pmd--peek (value)
  "Print VALUE and return it."
  (message "PMD Peek: %S" value)
  value)

(defun pmd--auth-source-host ()
  "Return the host name to use for PMD auth-source lookups."
  (url-host (url-generic-parse-url pmd-base-url)))

(defun pmd--auth-source-secret ()
  "Return the PMD API key from `auth-source', or nil."
  (require 'auth-source)
  (when-let* ((host (pmd--auth-source-host))
              (match (car (auth-source-search
                           :host host
                           :user pmd-auth-source-user
                           :require '(:secret)
                           :max 1)))
              (secret (plist-get match :secret)))
    (if (functionp secret)
        (funcall secret)
      secret)))

(defun pmd--api-key ()
  "Return the configured PMD API key."
  (or pmd-api-key
      (pmd--auth-source-secret)
      (user-error
       "No PMD API key configured; set pmd-api-key or add an auth-source entry for %s as user %s"
       (or (pmd--auth-source-host) pmd-base-url)
       pmd-auth-source-user)))

(cl-defun pmd--dig (hsh &rest keys)
  "Dig into HSH using KEYS and return the leaf value or nil."
  (let ((current hsh))
    (dolist (key keys)
      (when (and (hash-table-p current)
                 (gethash key current))
        (setq current (gethash key current))))
    (unless (hash-table-p current)
      current)))

(cl-defun pmd--make-url (path &rest params)
  "Make a URL for PATH with PARAMS."
  (let ((base-url (string-remove-suffix "/" pmd-base-url))
        (url-params (pmd--plist->lol params)))
    (if url-params
        (format "%s/%s?%s" base-url path (url-build-query-string url-params))
      (format "%s/%s" base-url path))))

(defun pmd--api-request (path &rest params)
  "Make an API request to PATH with PARAMS and return parsed JSON."
  (defvar url-request-extra-headers)
  (let ((url-params (if (plist-member params :format)
                        params
                      (append params '(:format "json")))))
    (require 'url)
    (require 'json)
    (let ((url-request-extra-headers
           `(("X-PMD-API-KEY" . ,(pmd--api-key)))))
      (let ((buffer
             (url-retrieve-synchronously
              (apply #'pmd--make-url path url-params) t t 10)))
        (unless buffer
          (user-error "PMD request failed"))
        (unwind-protect
            (with-current-buffer buffer
              (goto-char (point-min))
              (let ((status
                     (when (re-search-forward "^HTTP/[^ ]+ \\([0-9]+\\)" nil t)
                       (string-to-number (match-string 1)))))
                (unless (and status (<= 200 status 299))
                  (error "PMD request failed (HTTP %s)" (or status "unknown"))))
              (unless (re-search-forward "\r?\n\r?\n" nil t)
                (error "PMD response headers not found"))
              (json-parse-buffer :object-type 'hash-table
                                 :array-type 'list
                                 :null-object nil))
          (when (buffer-live-p buffer)
            (kill-buffer buffer)))))))

(defun pmd--json-request (url)
  "Request URL without PMD authentication and return parsed JSON."
  (defvar url-request-extra-headers)
  (require 'url)
  (require 'json)
  (let ((url-request-extra-headers nil)
        (buffer (url-retrieve-synchronously url t t 10)))
    (unless buffer
      (user-error "PMD catalog request failed"))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (let ((status
                 (when (re-search-forward "^HTTP/[^ ]+ \\([0-9]+\\)" nil t)
                   (string-to-number (match-string 1)))))
            (unless (and status (<= 200 status 299))
              (error "PMD catalog request failed (HTTP %s)" (or status "unknown"))))
          (unless (re-search-forward "\r?\n\r?\n" nil t)
            (error "PMD catalog response headers not found"))
          (json-parse-buffer :object-type 'hash-table
                             :array-type 'list
                             :null-object nil))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(defun pmd--json-catalog-entities (type url collection id-field)
  "Fetch URL and return COLLECTION records indexed by ID-FIELD for TYPE."
  (let* ((catalog (pmd--json-request url))
         (items (gethash collection catalog))
         (entities (make-hash-table :test #'equal)))
    (unless (listp items)
      (error "PMD catalog %s has no %s array" url collection))
    (puthash type catalog pmd--entity-catalog-data)
    (dolist (item items)
      (unless (hash-table-p item)
        (error "PMD catalog %s contains a non-object in %s" url collection))
      (let ((id (pmd--string (gethash id-field item))))
        (when (pmd--present-p id)
          (puthash id item entities))))
    entities))

(defun pmd--fetch-json-catalog (type url collection id-field)
  "Fetch and cache JSON catalog COLLECTION from URL for entity TYPE."
  (pmd--fetch-cached-entities
   type #'pmd--json-catalog-entities type url collection id-field))

(defun pmd--open-url (url)
  "Open URL with the platform URL handler."
  (let ((browse-url-generic-program
         (pcase system-type
           ('gnu/linux "xdg-open")
           ('darwin "open"))))
    (if browse-url-generic-program
        (let ((browse-url-browser-function #'browse-url-generic))
          (browse-url url))
      (browse-url url))))

(defvar pmd--entities-data (make-hash-table)
  "Store PMD entities by type.
Each value is an alist with `data' and `timestamp' keys.")

(defvar pmd--force-cache-refresh nil
  "Dynamic variable to force PMD cache refresh.")

(defun pmd--fetch-cached-entities (type fetch-function &rest arguments)
  "Fetch entities of TYPE using FETCH-FUNCTION and cache the result."
  (if (bound-and-true-p pmd--force-cache-refresh)
      (pmd--cache-clear-type type)
    (pmd--maybe-invalidate-cache type))
  (let ((record (gethash type pmd--entities-data)))
    (if record
        (progn
          (message "PMD Cache hit for type %s" type)
          (alist-get 'data record))
      (when-let* ((data (apply fetch-function arguments)))
        (puthash type `((data . ,data) (timestamp . ,(current-time)))
                 pmd--entities-data)
        data))))

(defun pmd--fetch-entities (type &rest arguments)
  "Fetch entities from PMD and return them."
  (apply #'pmd--fetch-cached-entities type #'pmd--api-request arguments))

(defun pmd--recover-entity (type id)
  "Recover the entity of TYPE with ID."
  (let ((record (gethash type pmd--entities-data)))
    (cl-assert record "[BUG] No data fetched for entity type %s" type)
    (let* ((entities (alist-get 'data record))
           (resolved-id (pmd--resolve-entity-id type id entities))
           (data (and resolved-id (gethash resolved-id entities))))
      (cl-assert (hash-table-p data) "[BUG] No data for entity with given id")
      data)))

(defun pmd--entity-display-function (type)
  "Return display function for entity TYPE."
  (pcase type
    (`pmd-project #'pmd--projects-display)
    (`pmd-team #'pmd--teams-display)
    (`pmd-service-group #'pmd--servicegroups-display)
    (`pmd-people #'pmd--people-display)
    (`pmd-amqp-namespace #'pmd--amqp-namespaces-display)
    (_ nil)))

(defun pmd--resolve-entity-id (type target entities)
  "Resolve PMD TARGET for TYPE to canonical entity id in ENTITIES."
  (or (get-text-property 0 'pmd-id target)
      (and (stringp target)
           (gethash target entities)
           target)
      (when-let* ((display-fn (pmd--entity-display-function type)))
        (catch 'match
          (maphash
           (lambda (id data)
             (when (equal (funcall display-fn data) target)
               (throw 'match id)))
           entities)
          nil))))

(defun pmd--cache-clear-type (type)
  "Clear the PMD cache for TYPE."
  (remhash type pmd--entities-data)
  (remhash type pmd--entity-catalog-data))

(defun pmd--maybe-invalidate-cache (type)
  "Invalidate the cache for TYPE if it has expired."
  (when-let* ((record (gethash type pmd--entities-data))
              (timestamp (alist-get 'timestamp record))
              (elapsed (float-time (time-subtract (current-time) timestamp))))
    (when (> elapsed pmd-cache-duration)
      (pmd--cache-clear-type type))))

(cl-defun pmd--completion-candidate (display type id)
  "Build a completion candidate from DISPLAY, TYPE, and ID."
  (propertize display
              'pmd-id id
              'pmd-type type
              'consult--candidate id))

(defun pmd--catalog-candidates (type url collection id-field display-field)
  "Return candidates from JSON catalog URL.
COLLECTION is the array name; ID-FIELD and DISPLAY-FIELD name record fields."
  (let ((entities (pmd--fetch-json-catalog type url collection id-field))
        candidates)
    (maphash
     (lambda (id data)
       (push (pmd--completion-candidate
              (or (pmd--string (gethash display-field data)) id)
              type id)
             candidates))
     entities)
    (sort candidates #'string-lessp)))

(cl-defun pmd--candidate-data (cand)
  "Return candidate data from CAND."
  (let* ((type (pmd--candidate-type cand))
         (id (pmd--candidate-id cand)))
    (pmd--recover-entity type id)))

(cl-defun pmd--candidate-id (cand)
  "Return candidate id extracted from CAND."
  (let ((id (get-text-property 0 'pmd-id cand)))
    (cl-assert id "[BUG] no id property associated")
    id))

(cl-defun pmd--candidate-type (cand)
  "Return candidate type extracted from CAND."
  (let ((type (get-text-property 0 'pmd-type cand)))
    (cl-assert type "[BUG] no type property associated")
    type))

(defvar-local pmd-item-type nil
  "PMD entity type displayed in the current item buffer.")

(defvar-local pmd-item-id nil
  "PMD entity ID displayed in the current item buffer.")

(defun pmd--interactive-item-id (type prompt)
  "Return the current item's ID for TYPE, or read one using PROMPT."
  (if (derived-mode-p 'pmd-item-mode)
      (progn
        (unless (eq type pmd-item-type)
          (user-error "This action does not apply to the displayed PMD item"))
        pmd-item-id)
    (read-string prompt)))

(defun pmd--grouping-fn (field)
  "Return a grouping function for FIELD."
  (lambda (cand transform)
    (if transform
        cand
      (when-let* ((data (pmd--candidate-data cand)))
        (pmd--string (gethash field data))))))

(defun pmd--with-label (label caption)
  "Return CAPTION prefixed with LABEL."
  (format "%s %s" label (or (pmd--string caption) "")))

(defun pmd--icon-github (caption)
  "Return CAPTION prefixed with a GitHub label."
  (pmd--with-label "gh:" caption))

(defun pmd--icon-team (caption)
  "Return CAPTION prefixed with a team label."
  (pmd--with-label "team:" caption))

(defun pmd--icon-mail (caption)
  "Return CAPTION prefixed with a mail label."
  (pmd--with-label "mail:" caption))

(defun pmd--icon-tags (caption)
  "Return CAPTION prefixed with a tags label."
  (pmd--with-label "tags:" caption))

(defun pmd--icon-head (caption)
  "Return CAPTION prefixed with a head label."
  (pmd--with-label "head:" caption))

(defun pmd--pad (value width)
  "Return VALUE padded or truncated to WIDTH."
  (truncate-string-to-width (or (pmd--string value) "") width 0 ?\s t))

(defun pmd--annotate-columns (cand columns)
  "Return affixation data for CAND using COLUMNS."
  (list cand
        ""
        (string-join
         (delq nil
               (mapcar
                (lambda (column)
                  (pcase-let ((`(,value ,width ,face) column))
                    (when (pmd--present-p value)
                      (propertize (pmd--pad value width) 'face face))))
                columns))
         "  ")))

(defun pmd--consult-annotator (annotator)
  "Return ANNOTATOR unless Marginalia mode is active."
  (unless (bound-and-true-p marginalia-mode)
    annotator))

(defun +pmd-cache-clear ()
  "Clear the PMD cache for all entity types."
  (interactive)
  (clrhash pmd--entities-data)
  (clrhash pmd--entity-catalog-data)
  (message "PMD cache cleared."))

(cl-defmacro pmd--with-cache-control (&rest body)
  "Execute BODY with forced cache refresh if a prefix argument is given."
  `(let ((pmd--force-cache-refresh (if current-prefix-arg t nil)))
     ,@body))

;;;; Projects

(defconst pmd--project-type 'pmd-project)

(defcustom pmd-code-path "~/code/xing"
  "Base directory used for permanent project clones."
  :type 'directory
  :group 'consult-pmd)

(defcustom pmd-code-temp-path temporary-file-directory
  "Base directory used for temporary project clones."
  :type 'directory
  :group 'consult-pmd)

(defcustom pmd-project-local-target-path-function
  #'pmd--projects-default-local-target-path
  "Function that resolves a local target path for a PMD project and base path.
The function receives the PMD project item and the selected clone base path."
  :type 'function
  :group 'consult-pmd)

(defvar pmd--projects-history nil
  "History for PMD projects completion.")

(defun pmd--projects-display (data)
  "Return a display string for project metadata DATA."
  (let ((name (pmd--string (gethash "name" data)))
        (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name) name id)))

(defun pmd--projects-candidates ()
  "Return project candidates for completion, sorted by name."
  (let ((projects (pmd--fetch-entities pmd--project-type "projects"))
        (candidates '()))
    (maphash
     (lambda (id value)
       (push (pmd--completion-candidate
              (pmd--projects-display value) pmd--project-type id)
             candidates))
     projects)
    (sort candidates #'string-lessp)))

(defun pmd--projects-annotate (cand)
  "Annotate project CAND with PMD metadata."
  (when-let* ((data (pmd--candidate-data cand)))
    (let ((contacts (pmd--list-string (pmd--dig data "people" "contact")))
          (head (pmd--string (pmd--dig data "people" "head"))))
      (pmd--annotate-columns
       cand
       `((,(pmd--icon-team (gethash "team" data)) 20 font-lock-variable-name-face)
         (,(pmd--string (gethash "service_type" data)) 20 font-lock-type-face)
         (,(pmd--string (gethash "org_unit" data)) 12 font-lock-variable-name-face)
         (,(pmd--string (gethash "product_lifecycle" data)) 22 font-lock-doc-face)
         (,head 20 success)
         (,contacts 60 font-lock-doc-face)
         (,(pmd--icon-tags (pmd--list-string (gethash "tags" data))) 24 font-lock-constant-face))))))

;;;###autoload
(defun +pmd-projects ()
  "Consult project metadata projects."
  (interactive)
  (pmd--with-cache-control
    (let ((candidates (pmd--projects-candidates)))
      (when-let* ((project-id
                   (consult--read
                    candidates
                    :prompt "PMD Projects: "
                    :category pmd--project-type
                    :history 'pmd--projects-history
                    :require-match t
                    :lookup #'consult--lookup-candidate
                    :annotate (pmd--consult-annotator #'pmd--projects-annotate)
                    :group (pmd--grouping-fn "service_group")
                    :sort nil)))
        (pmd--display-entity pmd--project-type project-id)))))

(defun pmd--projects-repository-url (project)
  "Return the full repository URL for PROJECT."
  (when-let* ((data (pmd--recover-entity pmd--project-type project)))
    (let* ((server-url (pmd--dig data "git" "server_url"))
           (account (pmd--dig data "git" "account"))
           (repo (pmd--dig data "git" "repo")))
      (format "%s/%s/%s" server-url account repo))))

(defun pmd--projects-repository-slug (project)
  "Return the repository slug for PROJECT."
  (when-let* ((data (pmd--recover-entity pmd--project-type project)))
    (let* ((account (pmd--dig data "git" "account"))
           (repo (pmd--dig data "git" "repo")))
      (format "%s/%s" account repo))))

(defun pmd--projects-path-component (value)
  "Return VALUE as a safe path component."
  (when-let* ((component (pmd--string value)))
    (setq component (string-trim component))
    (unless (or (string-empty-p component)
                (member component '("." ".."))
                (string-match-p "[/\\\\]" component))
      component)))

(defun pmd--projects-default-local-target-path (project base-path)
  "Resolve PMD PROJECT to its default local path under BASE-PATH.
Use `backend-foundations' as the first directory when PROJECT's team is
`backend-foundations'; use `others' for every other team. The next directory
is PROJECT's service group when present. Otherwise, map service types as
follows: `service' to `services', `library' to `libraries',
`infrastructure' to `infra', `documentation' to `docs', `mono-repo' to
`service-groups', `third-party' to `third-party', and `tool' to `tools'.
Use PROJECT's `git.repo' as the final directory."
  (let* ((team (downcase (or (pmd--string (gethash "team" project)) "")))
         (org-dir (if (string-equal team "backend-foundations")
                      "backend-foundations"
                    "others"))
         (service-group (pmd--projects-path-component
                         (gethash "service_group" project)))
         (service-type (pmd--string (gethash "service_type" project)))
         (type-dir (cdr (assoc service-type
                               '(("documentation" . "docs")
                                 ("infrastructure" . "infra")
                                 ("library" . "libraries")
                                 ("mono-repo" . "service-groups")
                                 ("service" . "services")
                                 ("third-party" . "third-party")
                                 ("tool" . "tools")))))
         (category (or service-group type-dir))
         (repo (pmd--projects-path-component (pmd--dig project "git" "repo"))))
    (unless (and category repo)
      (user-error "PMD project lacks a usable service group or service type, or git.repo"))
    (expand-file-name
     (mapconcat #'identity (list org-dir category repo) "/")
     (expand-file-name base-path))))

(defun pmd--projects-preferred-clone-url (repo-url)
  "Return clone URL for REPO-URL, preferring SSH when URL uses HTTPS."
  (if (string-prefix-p "https://" repo-url)
      (let* ((parsed-url (url-generic-parse-url repo-url))
             (host (url-host parsed-url))
             (path (string-trim (or (url-filename parsed-url) "") "/")))
        (format "git@%s:%s" host path))
    repo-url))

(defun pmd--projects-clone-repository (project base-path)
  "Clone PROJECT to BASE-PATH.
Resolve the local clone path with `pmd-project-local-target-path-function'."
  (unless (and (stringp base-path) (not (string-empty-p base-path)))
    (user-error "Clone base path is not configured"))
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (repo-url (pmd--projects-repository-url project)))
    (let* ((target-dir
            (funcall pmd-project-local-target-path-function data base-path))
           (repo-slug (pmd--projects-repository-slug project))
           (clone-url (pmd--projects-preferred-clone-url repo-url)))
      (unless (and (stringp target-dir) (not (string-empty-p target-dir)))
        (user-error "PMD local target path function returned no path"))
      (if (file-directory-p target-dir)
          (message "Repository already exists: %s" target-dir)
        (make-directory (file-name-directory target-dir) t)
        (with-current-buffer (get-buffer-create "*pmd-git-clone*")
          (erase-buffer)
          (let ((exit-code
                 (call-process "git" nil (current-buffer) t
                               "clone" clone-url target-dir)))
            (if (zerop exit-code)
                (progn
                  (bookmark-store repo-slug `((filename . ,target-dir)) nil)
                  (message "Cloned %s to %s" repo-slug target-dir))
              (user-error "git clone failed for %s (see *pmd-git-clone*)" repo-slug))))))))

(defun +pmd-clone-repository-permanent (project)
  "Clone PROJECT to `pmd-code-path'."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (pmd--projects-clone-repository project pmd-code-path))

(defun +pmd-clone-repository-temporary (project)
  "Clone PROJECT to `pmd-code-temp-path'."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (pmd--projects-clone-repository project pmd-code-temp-path))

(defun +pmd-copy-repo-url (project)
  "Copy the repository URL for PROJECT to the clipboard."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((repo-url (pmd--projects-repository-url project)))
    (kill-new repo-url)
    (message "Copied repository URL: %s" repo-url)))

(defun +pmd-open-repository (project)
  "Open the repository URL for PROJECT in the browser."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((repo-url (pmd--projects-repository-url project)))
    (pmd--open-url repo-url)))

(defun +pmd-copy-repo-slug (project)
  "Copy the repository slug for PROJECT to the clipboard."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((repo-slug (pmd--projects-repository-slug project)))
    (kill-new repo-slug)
    (message "Copied repository slug: %s" repo-slug)))

(defun +pmd-open-teams-channel (project)
  "Open the MS Teams channel for PROJECT in the browser."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (teams-channel (pmd--dig data "msteams" "channel_url")))
    (pmd--open-url teams-channel)))

(defun +pmd-open-teams-alerting-channel (project)
  "Open the MS Teams alerting channel for PROJECT in the browser."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (alerting-channel (pmd--dig data "alerting" "msteams_channel_url")))
    (pmd--open-url alerting-channel)))

(defun +pmd-open-project-documentation (project)
  "Open the project documentation URL for PROJECT in the browser."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (doc-url (pmd--dig data "documentation")))
    (if doc-url
        (pmd--open-url doc-url)
      (message "No documentation URL found for project %s" project))))

(defun +pmd-search-github-repo (project-id)
  "Search code in the GitHub repository for PROJECT-ID."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((repo-slug (pmd--projects-repository-slug project-id)))
    (consult-gh-search-code nil repo-slug)))

(defun +pmd-browse-github-repo (project-id)
  "Browse the GitHub repository for PROJECT-ID."
  (interactive (list (pmd--interactive-item-id pmd--project-type "Project ID: ")))
  (when-let* ((repo-slug (pmd--projects-repository-slug project-id)))
    (consult-gh-dired repo-slug)))

(defvar-keymap pmd-projects-embark-map
  "r" '+pmd-open-repository
  "R" '+pmd-copy-repo-url
  "s" '+pmd-copy-repo-slug
  "t" '+pmd-open-teams-channel
  "a" '+pmd-open-teams-alerting-channel
  "d" '+pmd-open-project-documentation
  "c" '+pmd-clone-repository-permanent
  "C" '+pmd-clone-repository-temporary)

(with-eval-after-load 'consult-gh
  (keymap-set pmd-projects-embark-map "g" '+pmd-search-github-repo)
  (keymap-set pmd-projects-embark-map "e" '+pmd-browse-github-repo)
  (when (boundp 'pmd-project-mode-map)
    (keymap-set pmd-project-mode-map "g" '+pmd-search-github-repo)
    (keymap-set pmd-project-mode-map "e" '+pmd-browse-github-repo)))

(with-eval-after-load 'embark
  (add-to-list 'embark-keymap-alist '(pmd-project . pmd-projects-embark-map)))

;;;; Teams

(defconst pmd--team-type 'pmd-team)

(defvar pmd--teams-history nil
  "History for PMD teams completion.")

(defun pmd--teams-display (data)
  "Return a display string for team metadata DATA."
  (let ((name (pmd--string (gethash "name" data)))
        (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name) name id)))

(defun pmd--teams-candidates ()
  "Return team candidates for completion, sorted by name."
  (message "Fetching team metadata...")
  (let ((teams (pmd--fetch-entities pmd--team-type "teams"))
        (candidates '()))
    (maphash
     (lambda (id value)
       (push (pmd--completion-candidate
              (pmd--teams-display value) pmd--team-type id)
             candidates))
     teams)
    (sort candidates #'string-lessp)))

(defun pmd--teams-annotate (cand)
  "Annotate team CAND with PMD metadata."
  (when-let* ((data (pmd--candidate-data cand)))
    (pmd--annotate-columns
     cand
     `((,(pmd--string (gethash "head" data)) 24 font-lock-string-face)
       (,(pmd--string (gethash "email" data)) 32 font-lock-type-face)
       (,(pmd--string (gethash "cost_centre" data)) 12 font-lock-constant-face)
       (,(pmd--list-string (gethash "contacts" data)) 40 font-lock-doc-face)))))

;;;###autoload
(defun +pmd-teams ()
  "Consult project metadata teams."
  (interactive)
  (let ((candidates (pmd--teams-candidates)))
    (when-let* ((team-id
                 (consult--read
                  candidates
                  :prompt "PMD Teams: "
                  :category pmd--team-type
                  :history 'pmd--teams-history
                  :require-match t
                  :annotate (pmd--consult-annotator #'pmd--teams-annotate)
                  :group (pmd--grouping-fn "org_unit")
                  :lookup #'consult--lookup-candidate
                  :sort nil)))
      (pmd--display-entity pmd--team-type team-id))))

(defun pmd--team-channel-url (team-id)
  "Return the PMD team channel URL for TEAM-ID."
  (let ((data (pmd--recover-entity pmd--team-type team-id)))
    (pmd--dig data "msteams" "channel_url")))

(defun +pmd-open-team-channel (team-id)
  "Open the PMD team channel in the browser."
  (interactive (list (pmd--interactive-item-id pmd--team-type "Team ID: ")))
  (when-let* ((url (pmd--team-channel-url team-id)))
    (pmd--open-url url)))

(defun +pmd-copy-team-channel-url (team-id)
  "Copy the PMD team channel URL to the clipboard."
  (interactive (list (pmd--interactive-item-id pmd--team-type "Team ID: ")))
  (when-let* ((url (pmd--team-channel-url team-id)))
    (kill-new url)
    (message "Copied team channel URL to clipboard.")))

(defun +pmd-open-team-alerting-channel (team-id)
  "Open the PMD team alerting channel in the browser."
  (interactive (list (pmd--interactive-item-id pmd--team-type "Team ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (alerting-url (pmd--string (pmd--dig data "alerting" "msteams_channel_url"))))
    (pmd--open-url alerting-url)))

(defun +pmd-copy-team-email (team-id)
  "Copy the email address of TEAM-ID to the clipboard."
  (interactive (list (pmd--interactive-item-id pmd--team-type "Team ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (email (pmd--string (gethash "email" data))))
    (kill-new email)
    (message "Copied email: %s" email)))

(defun +pmd-copy-team-alerting-channel (team-id)
  "Copy the PMD team alerting channel URL to the clipboard."
  (interactive (list (pmd--interactive-item-id pmd--team-type "Team ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (alerting-url (pmd--string (pmd--dig data "alerting" "msteams_channel_url"))))
    (kill-new alerting-url)
    (message "Copied alerting channel URL to clipboard.")))

(defun +pmd-open-team-confluence (team-id)
  "Open the Confluence page of TEAM-ID in the browser."
  (interactive (list (pmd--interactive-item-id pmd--team-type "Team ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (confluence-key (pmd--string (pmd--dig data "confluence" "key"))))
      (pmd--open-url (format "https://new-work.atlassian.net/wiki/spaces/%s"
                           confluence-key))))

(defvar-keymap pmd-teams-embark-map
  :doc "Keymap for PMD teams metadata actions."
  "t" '+pmd-open-team-channel
  "T" '+pmd-copy-team-channel-url
  "e" '+pmd-copy-team-email
  "c" '+pmd-open-team-confluence
  "a" '+pmd-open-team-alerting-channel
  "A" '+pmd-copy-team-alerting-channel)

(with-eval-after-load 'embark
  (add-to-list 'embark-keymap-alist `(,pmd--team-type . pmd-teams-embark-map)))

;;;; Service Groups

(defconst pmd--servicegroup-type 'pmd-service-group)

(defvar pmd--servicegroups-history nil
  "History for PMD servicegroups completion.")

(defun pmd--servicegroups-display (data)
  "Return a display string for servicegroup metadata DATA."
  (let ((name (pmd--string (gethash "name" data)))
        (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name) name id)))

(defun pmd--servicegroups-candidates ()
  "Return service group candidates for completion, sorted by name."
  (message "Fetching servicegroups metadata...")
  (let ((teams (pmd--fetch-entities pmd--servicegroup-type "service_groups"))
        (candidates '()))
    (maphash
     (lambda (id value)
       (push (pmd--completion-candidate
              (pmd--servicegroups-display value) pmd--servicegroup-type id)
             candidates))
     teams)
    (sort candidates #'string-lessp)))

(defun pmd--servicegroups-annotate (cand)
  "Annotate service group CAND with PMD metadata."
  (when-let* ((data (pmd--candidate-data cand)))
    (pmd--annotate-columns
     cand
     `((,(format "heads: %s" (pmd--list-string (gethash "heads" data))) 52 font-lock-string-face)
       (,(format "directors: %s" (pmd--list-string (gethash "directors" data))) 52 success)
       (,(pmd--string (gethash "description" data)) 80 font-lock-doc-face)))))

;;;###autoload
(defun +pmd-servicegroups ()
  "Consult project metadata servicegroups."
  (interactive)
  (let ((candidates (pmd--servicegroups-candidates)))
    (when-let* ((team-id
                 (consult--read
                  candidates
                  :prompt "PMD ServiceGroup: "
                  :category pmd--servicegroup-type
                  :history 'pmd--servicegroups-history
                  :annotate (pmd--consult-annotator #'pmd--servicegroups-annotate)
                  :lookup #'consult--lookup-candidate
                  :require-match t
                  :sort nil)))
      (pmd--display-entity pmd--servicegroup-type team-id))))

;;;; People

(defconst pmd--people-type 'pmd-people)

(defvar pmd--people-history nil
  "History for PMD people completion.")

(defun pmd--people-display (data)
  "Return a display string for people metadata DATA."
  (let ((name (pmd--string (gethash "display_name" data)))
        (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name) name id)))

(defun pmd--people-candidates ()
  "Return people candidates for completion, sorted by name."
  (message "Fetching people metadata...")
  (let ((people (pmd--fetch-entities pmd--people-type "emails"))
        (candidates '()))
    (maphash
     (lambda (id value)
       (push (pmd--completion-candidate
              (pmd--people-display value) pmd--people-type id)
             candidates))
     people)
    (sort candidates #'string-lessp)))

(defun pmd--people-annotate (cand)
  "Annotate person CAND with PMD metadata."
  (when-let* ((data (pmd--candidate-data cand)))
    (pmd--annotate-columns
     cand
     `((,(pmd--icon-mail (gethash "email" data)) 40 font-lock-string-face)
       (,(pmd--icon-github (gethash "github_com" data)) 28 font-lock-string-face)))))

;;;###autoload
(defun +pmd-people ()
  "Consult project metadata people."
  (interactive)
  (let ((candidates (pmd--people-candidates)))
    (when-let* ((person-id
                 (consult--read
                  candidates
                  :prompt "PMD People: "
                  :category pmd--people-type
                  :history 'pmd--people-history
                  :lookup #'consult--lookup-candidate
                  :annotate (pmd--consult-annotator #'pmd--people-annotate)
                  :require-match t
                  :sort nil)))
      (pmd--display-entity pmd--people-type person-id))))

(defun +pmd-copy-person-email (person-id)
  "Copy the email address of PERSON-ID to the clipboard."
  (interactive (list (pmd--interactive-item-id pmd--people-type "Person ID: ")))
  (when-let* ((data (pmd--recover-entity pmd--people-type person-id))
              (email (pmd--string (gethash "email" data))))
    (kill-new email)
    (message "Copied email: %s" email)))

(defvar-keymap pmd-people-embark-map
  "e" '+pmd-copy-person-email)

(with-eval-after-load 'embark
  (add-to-list 'embark-keymap-alist `(,pmd--people-type . pmd-people-embark-map)))

;;;; AMQP Catalog

(defvar pmd--amqp-catalog-history nil
  "History for the AMQP namespace completion.")

(defun pmd--amqp-namespaces-display (data)
  "Return the namespace name for AMQP catalog DATA."
  (pmd--string (gethash "namespace" data)))

(defun pmd--amqp-catalog-candidates ()
  "Return AMQP namespace candidates from the JSON catalog."
  (message "Fetching AMQP catalog...")
  (pmd--catalog-candidates
   pmd--amqp-namespace-type pmd--amqp-catalog-url
   "namespaces" "namespace" "namespace"))

(defun pmd--amqp-catalog-annotate (candidate)
  "Annotate AMQP namespace CANDIDATE with its message count."
  (when-let* ((data (pmd--candidate-data candidate)))
    (pmd--annotate-columns
     candidate
     `((,(format "messages: %s" (or (pmd--string (gethash "message_count" data)) "—"))
        24 font-lock-constant-face)))))

;;;###autoload
(defun +pmd-amqp-catalog ()
  "Consult AMQP namespaces from the project metadata catalog."
  (interactive)
  (let ((candidates (pmd--amqp-catalog-candidates)))
    (when-let* ((namespace
                 (consult--read
                  candidates
                  :prompt "PMD AMQP Namespace: "
                  :category pmd--amqp-namespace-type
                  :history 'pmd--amqp-catalog-history
                  :require-match t
                  :lookup #'consult--lookup-candidate
                  :annotate (pmd--consult-annotator #'pmd--amqp-catalog-annotate)
                  :sort nil)))
      (pmd--display-entity pmd--amqp-namespace-type namespace))))

;;;; Detail buffers

(defvar pmd-item--emulation-mode-map-alist nil
  "Emulation keymaps active in PMD item buffers.")

(defvar-local pmd-item--mask-embark nil
  "Non-nil in PMD item buffers to suppress global Embark entry keys.")

(add-to-list 'emulation-mode-map-alists 'pmd-item--emulation-mode-map-alist)

(defvar pmd-item--embark-suppression-map
  (let ((map (make-sparse-keymap)))
    (dolist (key '("C-." "C-," "C-c ." "C-c ,"))
      (keymap-set map key 'undefined))
    map)
  "Map that masks global Embark entry keys in PMD item buffers.")

(defun pmd--property-label (key)
  "Return a readable label for property KEY."
  (capitalize (replace-regexp-in-string "[-_]" " " key)))

(defun pmd--property-group (key)
  "Return the display group for property KEY."
  (let ((name (downcase key)))
    (cond
     ((equal name "description") 'overview)
     ((member name '("audit" "collected_at" "diagnostics" "environment"
                     "namespace_count" "stale"))
      'catalog)
     ((or (member name '("team" "org_unit" "people" "head" "heads"
                         "director" "directors" "contacts" "contact"
                         "owner" "owners" "email" "cost_centre"))
          (string-match-p "\\(?:lead\\|owner\\|contact\\)" name))
      'ownership)
     ((or (member name '("technology" "technologies" "technology_stack"
                         "service_type" "tags"))
          (string-match-p "\\(?:technolog\\|language\\|framework\\|runtime\\|platform\\|tag\\)" name))
      'technology)
     ((or (member name '("service_group" "product_lifecycle" "lifecycle"
                         "status" "maturity" "tier" "namespace"
                         "message_count"))
          (string-match-p "\\(?:lifecycle\\|service_group\\)" name))
      'service-context)
     ((or (member name '("git" "msteams" "alerting" "confluence"
                         "documentation" "github_com" "website"))
          (string-match-p "\\(?:url\\|uri\\|link\\)\\'" name))
      'links)
     (t 'other))))

(defconst pmd--property-group-order
  '((overview . "Overview")
    (catalog . "Catalog")
    (ownership . "Ownership")
    (technology . "Technology")
    (service-context . "Service context")
    (links . "Links and channels")
    (other . "Other properties"))
  "Ordered groups used when rendering PMD entity properties.")

(defun pmd--insert-grouped-properties (data)
  "Insert DATA's properties under semantic section headings."
  (let (properties)
    (maphash (lambda (key value)
               (unless (member key '("name" "display_name" "id"))
                 (push (cons key value) properties)))
             data)
    (dolist (group pmd--property-group-order)
      (let ((items (sort
                    (seq-filter
                     (lambda (property)
                       (eq (pmd--property-group (car property)) (car group)))
                     (copy-sequence properties))
                    (lambda (left right)
                      (string-lessp (car left) (car right))))))
        (when items
          (insert (propertize (cdr group) 'face '(:weight bold :height 1.1))
                  "\n")
          (dolist (property items)
            (pmd--insert-property (car property) (cdr property) 1))
          (insert "\n"))))))

(defun pmd--copy-action-bindings (source target)
  "Copy direct bindings from action keymap SOURCE into mode keymap TARGET."
  (map-keymap
   (lambda (event binding)
     (unless (keymapp binding)
       (define-key target (vector event) binding)))
   source))

(defun pmd--insert-property-value (value depth)
  "Insert VALUE recursively, indented by DEPTH levels."
  (let ((indent (make-string (* 2 depth) ?\s)))
    (cond
     ((hash-table-p value)
      (let (keys)
        (maphash (lambda (key _value) (push key keys)) value)
        (if keys
            (dolist (key (sort keys #'string-lessp))
              (pmd--insert-property key (gethash key value) depth))
          (insert "—\n"))))
     ((and (listp value) value)
      (dolist (item value)
        (insert indent "• ")
        (cond
         ((or (hash-table-p item) (and (listp item) item))
          (insert "\n")
          (pmd--insert-property-value item (1+ depth)))
         (t
          (insert (replace-regexp-in-string
                   "\n" (concat "\n" indent "  ")
                   (or (pmd--string item) "—"))
                  "\n")))))
     ((null value) (insert "—\n"))
     (t
      (insert (replace-regexp-in-string
               "\n" (concat "\n" indent)
               (pmd--string value))
              "\n")))))

(defun pmd--insert-property (key value depth)
  "Insert property KEY and VALUE at indentation DEPTH."
  (let ((indent (make-string (* 2 depth) ?\s)))
    (insert indent (propertize (pmd--property-label key)
                               'face 'font-lock-keyword-face)
            ": ")
    (if (or (hash-table-p value)
            (and (listp value) value))
        (cond
         ((and (hash-table-p value) (= (hash-table-count value) 0))
          (insert "—\n"))
         ((and (listp value) (null value))
          (insert "—\n"))
         (t
          (insert "\n")
          (pmd--insert-property-value value (1+ depth))))
      (pmd--insert-property-value value depth))))

(define-derived-mode pmd-item-mode special-mode "PMD Item"
  "Major mode for read-only PMD entity details.
Entity-specific actions are available from the derived PMD modes."
  (setq-local truncate-lines nil)
  (visual-line-mode 1)
  (setq-local pmd-item--mask-embark t)
  (setq-local pmd-item--emulation-mode-map-alist
              `((pmd-item--mask-embark . ,pmd-item--embark-suppression-map)))
  (setq buffer-read-only t))

(define-derived-mode pmd-project-mode pmd-item-mode "PMD Project"
  "Major mode for project detail buffers.
Bindings match `pmd-projects-embark-map'.")

(define-derived-mode pmd-team-mode pmd-item-mode "PMD Team"
  "Major mode for team detail buffers.
Bindings match `pmd-teams-embark-map'.")

(define-derived-mode pmd-people-mode pmd-item-mode "PMD Person"
  "Major mode for person detail buffers.
Bindings match `pmd-people-embark-map'.")

(define-derived-mode pmd-service-group-mode pmd-item-mode "PMD Service Group"
  "Major mode for service-group detail buffers.")

(define-derived-mode pmd-amqp-namespace-mode pmd-item-mode "PMD AMQP Namespace"
  "Major mode for AMQP namespace detail buffers.")

(pmd--copy-action-bindings pmd-projects-embark-map pmd-project-mode-map)
(pmd--copy-action-bindings pmd-teams-embark-map pmd-team-mode-map)
(pmd--copy-action-bindings pmd-people-embark-map pmd-people-mode-map)

(defun pmd--entity-mode (type)
  "Return the detail-buffer mode for PMD entity TYPE."
  (pcase type
    ('pmd-project #'pmd-project-mode)
    ('pmd-team #'pmd-team-mode)
    ('pmd-service-group #'pmd-service-group-mode)
    ('pmd-people #'pmd-people-mode)
    ('pmd-amqp-namespace #'pmd-amqp-namespace-mode)
    (_ #'pmd-item-mode)))

(defun pmd--entity-action-map (type)
  "Return the detail-mode action map for entity TYPE."
  (pcase type
    ('pmd-project pmd-projects-embark-map)
    ('pmd-team pmd-teams-embark-map)
    ('pmd-people pmd-people-embark-map)
    (_ nil)))

(defun pmd--insert-binding-legend (type)
  "Insert the available detail-buffer bindings for entity TYPE."
  (let ((bindings '(("q" . "Close detail buffer")))
        (map (pmd--entity-action-map type)))
    (when map
      (map-keymap
       (lambda (event command)
         (when (and (symbolp command) (commandp command))
           (push (cons (key-description (vector event))
                       (pmd--property-label
                        (string-remove-prefix "+pmd-" (symbol-name command))))
                 bindings)))
       map))
    (setq bindings
          (sort bindings (lambda (left right)
                           (string-lessp (car left) (car right)))))
    (insert (propertize "Bindings: " 'face 'font-lock-keyword-face)
            (mapconcat
             (lambda (binding)
               (concat (propertize (car binding) 'face 'font-lock-constant-face)
                       " " (cdr binding)))
             bindings "  ·  ")
            "\n")))

(defun pmd--insert-catalog-details (type)
  "Insert catalog-level data for entity TYPE, if it has a catalog."
  (when-let* ((catalog (gethash type pmd--entity-catalog-data)))
    (let ((details (copy-hash-table catalog)))
      ;; Namespace entries already have their own Consult selection.
      (remhash "namespaces" details)
      (puthash "namespace_count"
               (length (gethash "namespaces" catalog)) details)
      (pmd--insert-grouped-properties details))))

(defun pmd--display-entity (type id)
  "Display the PMD entity of TYPE and ID in a details buffer."
  (let* ((data (pmd--recover-entity type id))
         (display-fn (pmd--entity-display-function type))
         (name (or (and display-fn (funcall display-fn data))
                   (pmd--string id)))
         (entity-mode (pmd--entity-mode type))
         (buffer (get-buffer-create
                  (format "*PMD %s: %s [%s]*"
                          (pmd--property-label
                           (string-remove-prefix "pmd-" (symbol-name type)))
                          name id))))
    (with-current-buffer buffer
      (funcall entity-mode)
      (setq-local pmd-item-type type
                  pmd-item-id id)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (propertize name 'face '(:weight bold :height 1.2)) "\n")
        (pmd--insert-binding-legend type)
        (insert (propertize (format "%s · %s\n\n"
                                    (pmd--property-label
                                     (string-remove-prefix "pmd-" (symbol-name type)))
                                    id)
                            'face 'shadow))
        (pmd--insert-grouped-properties data)
        (pmd--insert-catalog-details type)
        (goto-char (point-min))
        (set-buffer-modified-p nil)))
    (pop-to-buffer buffer)))

(provide 'consult-pmd)

(with-eval-after-load 'marginalia
  (require 'consult-pmd-marginalia))

;;; consult-pmd.el ends here
