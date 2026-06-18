;;; consult-pmd.el --- Project metadata lookup -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0"))
;;; Commentary:
;; Consult helpers for internal project metadata.
;;
;;; Code:

(require 'cl-lib)
(require 'bookmark)
(require 'consult)
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

(defun pmd--browse-url (path &rest params)
  "Open PATH with PARAMS in the browser."
  (browse-url (apply #'pmd--make-url path params)))

(defvar pmd--entities-data (make-hash-table)
  "Store PMD entities by type.
Each value is an alist with `data' and `timestamp' keys.")

(defvar pmd--force-cache-refresh nil
  "Dynamic variable to force PMD cache refresh.")

(defun pmd--fetch-entities (type &rest arguments)
  "Fetch entities from PMD and return them."
  (if (bound-and-true-p pmd--force-cache-refresh)
      (pmd--cache-clear-type type)
    (pmd--maybe-invalidate-cache type))
  (let ((record (gethash type pmd--entities-data)))
    (if record
        (progn
          (message "PMD Cache hit for type %s" type)
          (alist-get 'data record))
      (when-let* ((data (apply #'pmd--api-request arguments)))
        (puthash type `((data . ,data) (timestamp . ,(current-time)))
                 pmd--entities-data)
        data))))

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
  (remhash type pmd--entities-data))

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

(defun +pmd-cache-clear ()
  "Clear the PMD cache for all entity types."
  (interactive)
  (clrhash pmd--entities-data)
  (message "PMD cache cleared."))

(cl-defmacro pmd--with-cache-control (&rest body)
  "Execute BODY with forced cache refresh if a prefix argument is given."
  `(let ((pmd--force-cache-refresh (if current-prefix-arg t nil)))
     ,@body))

;;;; Projects

(defconst pmd--project-type 'pmd-project)

(defcustom pmd-code-path "~/code"
  "Base directory used for permanent project clones."
  :type 'directory
  :group 'consult-pmd)

(defcustom pmd-code-temp-path temporary-file-directory
  "Base directory used for temporary project clones."
  :type 'directory
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
                    :annotate #'pmd--projects-annotate
                    :group (pmd--grouping-fn "service_group")
                    :sort nil)))
        (pmd--browse-url (format "projects/%s" project-id))))))

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

(defun pmd--projects-forge-name (repo-url)
  "Return a local forge name derived from REPO-URL."
  (when-let* ((parsed-url (url-generic-parse-url repo-url))
              (host (url-host parsed-url)))
    (pcase host
      ("github.com" "github")
      ("codeberg.org" "codeberg")
      ("gitlab.com" "gitlab")
      (_ host))))

(defun pmd--projects-preferred-clone-url (repo-url)
  "Return clone URL for REPO-URL, preferring SSH when URL uses HTTPS."
  (if (string-prefix-p "https://" repo-url)
      (let* ((parsed-url (url-generic-parse-url repo-url))
             (host (url-host parsed-url))
             (path (string-trim (or (url-filename parsed-url) "") "/")))
        (format "git@%s:%s" host path))
    repo-url))

(defun pmd--projects-clone-repository (project base-path &optional include-forge)
  "Clone PROJECT to BASE-PATH.
When INCLUDE-FORGE is non-nil, clone under a forge-specific subdirectory."
  (unless (and (stringp base-path) (not (string-empty-p base-path)))
    (user-error "Clone base path is not configured"))
  (when-let* ((repo-url (pmd--projects-repository-url project))
              (repo-slug (pmd--projects-repository-slug project)))
    (let* ((target-root
            (if include-forge
                (let ((forge (or (pmd--projects-forge-name repo-url)
                                 (user-error "Could not derive forge from %s" repo-url))))
                  (expand-file-name forge (file-name-as-directory base-path)))
              (file-name-as-directory base-path)))
           (target-dir (expand-file-name repo-slug target-root))
           (clone-url (pmd--projects-preferred-clone-url repo-url)))
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
  (interactive "sProject ID: ")
  (pmd--projects-clone-repository project pmd-code-path t))

(defun +pmd-clone-repository-temporary (project)
  "Clone PROJECT to `pmd-code-temp-path'."
  (interactive "sProject ID: ")
  (pmd--projects-clone-repository project pmd-code-temp-path))

(defun +pmd-copy-repo-url (project)
  "Copy the repository URL for PROJECT to the clipboard."
  (interactive "sProject ID: ")
  (when-let* ((repo-url (pmd--projects-repository-url project)))
    (kill-new repo-url)
    (message "Copied repository URL: %s" repo-url)))

(defun +pmd-open-repository (project)
  "Open the repository URL for PROJECT in the browser."
  (interactive "sProject ID: ")
  (when-let* ((repo-url (pmd--projects-repository-url project)))
    (browse-url repo-url)))

(defun +pmd-copy-repo-slug (project)
  "Copy the repository slug for PROJECT to the clipboard."
  (interactive "sProject ID: ")
  (when-let* ((repo-slug (pmd--projects-repository-slug project)))
    (kill-new repo-slug)
    (message "Copied repository slug: %s" repo-slug)))

(defun +pmd-open-teams-channel (project)
  "Open the MS Teams channel for PROJECT in the browser."
  (interactive "sProject ID: ")
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (teams-channel (pmd--dig data "msteams" "channel_url")))
    (browse-url teams-channel)))

(defun +pmd-open-teams-alerting-channel (project)
  "Open the MS Teams alerting channel for PROJECT in the browser."
  (interactive "sProject ID: ")
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (alerting-channel (pmd--dig data "alerting" "msteams_channel_url")))
    (browse-url alerting-channel)))

(defun +pmd-open-project-documentation (project)
  "Open the project documentation URL for PROJECT in the browser."
  (interactive "sProject ID: ")
  (when-let* ((data (pmd--recover-entity pmd--project-type project))
              (doc-url (pmd--dig data "documentation")))
    (if doc-url
        (browse-url doc-url)
      (message "No documentation URL found for project %s" project))))

(defun +pmd-search-github-repo (project-id)
  "Search code in the GitHub repository for PROJECT-ID."
  (interactive "sProject ID: ")
  (when-let* ((repo-slug (pmd--projects-repository-slug project-id)))
    (consult-gh-search-code nil repo-slug)))

(defun +pmd-browse-github-repo (project-id)
  "Browse the GitHub repository for PROJECT-ID."
  (interactive "sProject ID: ")
  (when-let* ((repo-slug (pmd--projects-repository-slug project-id)))
    (consult-gh-dired repo-slug)))

(with-eval-after-load 'embark
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
    (keymap-set pmd-projects-embark-map "e" '+pmd-browse-github-repo))
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
                  :annotate #'pmd--teams-annotate
                  :group (pmd--grouping-fn "org_unit")
                  :lookup #'consult--lookup-candidate
                  :sort nil)))
      (pmd--browse-url (format "teams/%s" team-id)))))

(defun pmd--team-channel-url (team-id)
  "Return the PMD team channel URL for TEAM-ID."
  (let ((data (pmd--recover-entity pmd--team-type team-id)))
    (pmd--dig data "msteams" "channel_url")))

(defun +pmd-open-team-channel (team-id)
  "Open the PMD team channel in the browser."
  (interactive)
  (when-let* ((url (pmd--team-channel-url team-id)))
    (browse-url url)))

(defun +pmd-copy-team-channel-url (team-id)
  "Copy the PMD team channel URL to the clipboard."
  (interactive)
  (when-let* ((url (pmd--team-channel-url team-id)))
    (kill-new url)
    (message "Copied team channel URL to clipboard.")))

(defun +pmd-open-team-alerting-channel (team-id)
  "Open the PMD team alerting channel in the browser."
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (alerting-url (pmd--string (pmd--dig data "alerting" "msteams_channel_url"))))
    (browse-url alerting-url)))

(defun +pmd-copy-team-email (team-id)
  "Copy the email address of TEAM-ID to the clipboard."
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (email (pmd--string (gethash "email" data))))
    (kill-new email)
    (message "Copied email: %s" email)))

(defun +pmd-copy-team-alerting-channel (team-id)
  "Copy the PMD team alerting channel URL to the clipboard."
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (alerting-url (pmd--string (pmd--dig data "alerting" "msteams_channel_url"))))
    (kill-new alerting-url)
    (message "Copied alerting channel URL to clipboard.")))

(defun +pmd-open-team-confluence (team-id)
  "Open the Confluence page of TEAM-ID in the browser."
  (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
              (confluence-key (pmd--string (pmd--dig data "confluence" "key"))))
    (browse-url (format "https://new-work.atlassian.net/wiki/spaces/%s"
                        confluence-key))))

(with-eval-after-load 'embark
  (defvar-keymap pmd-teams-embark-map
    :doc "Keymap for PMD teams metadata embark actions."
    "t" '+pmd-open-team-channel
    "T" '+pmd-copy-team-channel-url
    "e" '+pmd-copy-team-email
    "c" '+pmd-open-team-confluence
    "a" '+pmd-open-team-alerting-channel
    "A" '+pmd-copy-team-alerting-channel)
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
                  :annotate #'pmd--servicegroups-annotate
                  :lookup #'consult--lookup-candidate
                  :require-match t
                  :sort nil)))
      (pmd--browse-url (format "service_groups/%s" team-id)))))

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
                  :annotate #'pmd--people-annotate
                  :require-match t
                  :sort nil)))
      (let ((data (pmd--recover-entity pmd--people-type person-id)))
        (browse-url
         (format "https://github.com/%s"
                 (pmd--string (gethash "github_com" data))))))))

(defun +pmd-copy-person-email (person-id)
  "Copy the email address of PERSON-ID to the clipboard."
  (when-let* ((data (pmd--recover-entity pmd--people-type person-id))
              (email (pmd--string (gethash "email" data))))
    (kill-new email)
    (message "Copied email: %s" email)))

(with-eval-after-load 'embark
  (defvar-keymap pmd-people-embark-map
    "e" '+pmd-copy-person-email)
  (add-to-list 'embark-keymap-alist `(,pmd--people-type . pmd-people-embark-map)))

(provide 'consult-pmd)
;;; consult-pmd.el ends here
