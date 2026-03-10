;;; consult-pmd-core.el --- Core functions and settings -*- lexical-binding: t; -*-

(require 'consult)

(defcustom pmd-base-url "https://project-metadata.nwse.io"
  "Base URL for project metadata."
  :type 'string
  :group 'consult-pmd)

(defcustom pmd-api-key "dea"
  "API key for project metadata. This is simply the team id. It's not a SECRET."
  :type 'string
  :group 'consult-pmd)

(defcustom pmd-cache-duration 300
  "Duration in seconds for which fetched PMD entities are cached."
  :type 'integer
  :group 'consult-pmd)

;;; Helpers
(defun pmd--keyword->string (key)
  "Convert keyword KEY to string without leading colon."
  (format "%s" (substring (symbol-name key) 1)))

(defun pmd--plist->lol (plist)
  "Convert PLIST to a list of lists."
  (cl-loop for (key value) on plist by #'cddr
    collect (list (pmd--keyword->string key) value)))

(defun pmd--string (value)
  "Return `VALUE' as a string, or nil."
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
  "Return t if `VALUE' is non-nil and non-empty string."
  (and value
    (or (not (stringp value))
      (not (string-empty-p value)))))

(defun pmd--peek (value)
  "Prints the `VALUE' and returns it. This is used for debugging."
  (message "PMD Peek: %S" value)
  value)

(cl-defun pmd--dig (hsh &rest keys)
  "Dig into a nested hash table `HSH' using `KEYS' and return the value or nil."
  (let ((current hsh))
    (dolist (key keys)
      (when (and (hash-table-p current)
              (gethash key current))
        (setq current (gethash key current))))
    (if (hash-table-p current) ;; not a leaf node
      nil
      current)))

;;; API request helpers
(cl-defun pmd--make-url (path &rest params)
  "Make a URL for `PATH' with `PARAMS'. `PARAMS' is a plist containting key-value pairs."
  (let ((base-url (string-remove-suffix "/" pmd-base-url))
         (url-params (pmd--plist->lol params)))
    (if url-params
      (format "%s/%s?%s" base-url path (url-build-query-string url-params))
      (format "%s/%s" base-url path))))

(defun pmd--api-request (path &rest params)
  "Make an API request to `PATH' with `PARAMS' and return parsed JSON.
If `PARAMS' does not contain :format \"json\" it will be added. "

  (let ((url-params (if (plist-member params :format)
                      params
                      (append params '(:format "json")))))
    (require 'url)
    (require 'json)
    (let ((url-request-extra-headers
            `(("X-PMD-API-KEY" . ,pmd-api-key))))
      (let ((buffer (url-retrieve-synchronously (apply #'pmd--make-url path url-params) t t 10)))
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
            (kill-buffer buffer)))))))

(defun pmd--browse-url (path &rest params)
  "Open the pmd with the provides `path' and url `params' in the browser."
  (browse-url (apply #'pmd--make-url path params)))

;; It is surprisingly tricky to create completion candidates and reliably carry full object data associated
;; with those candidates around. While it works well if you stay within consult / vertico only with text-properties,
;; it gets surprisingly brittle when embark is involved. So the overall strategy we apply is that we store the
;; entities in a different variable and allow to recover a particular entity by type and id.

(defvar pmd--entities-data (make-hash-table)
  "A correlation store for PMD entities. It maps entity TYPE to a record.
Each record is an alist with keys:
- data: A hash table mapping entity ID to full entity data
- timestamp: The time when the data was fetched

The timestamps is used to implement caching strategies.
")

(defvar pmd--force-cache-refresh nil
  "A dynamic variable to force cache refresh for PMD entities.")

(defun pmd--fetch-entities (type &rest arguments)
  "Fetch entities from PMD and returns it.
As a side-effect it stores the data under the key `TYPE' in `pmd--entities-data' which
is used to recover the full object from the id in various parts of the system.
`ARGUMENTS' are passed through to `pmd--api-request'. "
  (if (bound-and-true-p pmd--force-cache-refresh)
    (pmd--cache-clear-type type)
    (pmd--maybe-invalidate-cache type))
  (let ((record (gethash type pmd--entities-data)))
    (if record
      (progn
        (message "PMD Cache hit for type %s" type)
        (alist-get 'data record))
      (when-let* ((data (apply #'pmd--api-request arguments)))
        (puthash type `((data . ,data) (timestamp . ,(current-time))) pmd--entities-data)
        data))))

(defun pmd--recover-entity (type id)
  "Recovers the entity of type `TYPE' with the given `ID'"
  (let ((record (gethash type pmd--entities-data)))
    (cl-assert record "[BUG] No data fetched for entity type %s" type)
    (let ((data (gethash id (alist-get 'data record))))
      (cl-assert (hash-table-p data) "[BUG] No data for entity with given id")
      data)))

(defun pmd--cache-clear-type (type)
  "Clear the PMD cache for entity `TYPE'."
  (remhash type pmd--entities-data))

(defun pmd--maybe-invalidate-cache (type)
  "Invalidate the cache for entity `TYPE' if the cache duration has expired."
  (when-let* ((record (gethash type pmd--entities-data))
               (timestamp (alist-get 'timestamp record))
               (elapsed (float-time (time-subtract (current-time) timestamp))))
    (when (> elapsed pmd-cache-duration)
      (pmd--cache-clear-type type))))

;;; Completion candidates
(cl-defun pmd--completion-candidate (display type id)
  "Build a completion condidate using the provided `DISPLAY', `ID' and `DATA'.
This propertizes the `DISPLAY' string with properties to retrieve `ID' and `DATA' later."
  (propertize display
    'pmd-id id
    'pmd-type type
    'consult--candidate id))

(cl-defun pmd--candidate-data (cand)
  "Return candidate data from completion `CAND'."
  (let* ((type (pmd--candidate-type cand))
          (id  (pmd--candidate-id cand)))
    (pmd--recover-entity type id)))

(cl-defun pmd--candidate-id (cand)
  "Return candidate id extracted from completion `CAND'."
  (let ((id (get-text-property 0 'pmd-id cand)))
    (cl-assert id "[BUG] no id poperty associated")
    id))

(cl-defun pmd--candidate-type (cand)
  "Return candidate type extracted from completion `CAND'."
  (let ((type (get-text-property 0 'pmd-type cand)))
    (cl-assert type "[BUG] no type property associated")
    type))

(defun pmd--grouping-fn (field)
  "Return a grouping function for FIELD."
  (lambda  (cand transform)
    (if transform cand
      (when-let ((data (pmd--candidate-data cand)))
        (pmd--string (gethash field data))))))

;;; nice display for candidate
(require 'nerd-icons)

(defun pmd--with-icon (icon caption)
  "Return `CAPTION' prefixed with `ICON'."
  ;; dispatch based on icon name prefix
  (let ((fn
          (cond
            ((string-prefix-p "nf-fa-" icon) #'nerd-icons-faicon)
            ((string-prefix-p "nf-oct-" icon) #'nerd-icons-octicon)
            ((string-prefix-p "nf-dev-" icon) #'nerd-icons-devicon)
            ((string-prefix-p "nf-cod-" icon)  #'nerd-icons-codicon)
            ((string-prefix-p "nf-md-" icon) #'nerd-icons-mdicon))))
    (concat (funcall fn icon :face 'nerd-icons-lred) " " (or (pmd--string caption) ""))))

(defun pmd--icon-github (caption)
  "Return `CAPTION' prefixed with an octicon."
  (pmd--with-icon "nf-fa-github" caption))

(defun pmd--icon-team (caption)
  "Return `CAPTION' prefixed with a team icon."
  (pmd--with-icon "nf-cod-organization" caption))

(defun pmd--icon-mail (caption)
  "Return `CAPTION' prefixed with a mail icon."
  (pmd--with-icon "nf-cod-mail" caption))

(defun pmd--icon-tags (caption)
  "Return `CAPTION' prefixed with a tags icon."
  (pmd--with-icon "nf-cod-tag" caption))

(defun pmd--icon-head (caption)
  "Return `CAPTION' prefixed with a head icon."
  (pmd--with-icon "nf-md-head" caption))

;;; make sure embark finds the correct target and we can restore the ID
(with-eval-after-load 'embark
  (defun pmd--embark-target ()
    "Embark target finder for PMD candidates in Vertico. "
    (when (and (boundp 'vertico--input) vertico--input
            (fboundp 'vertico--candidate))
      (when (eq vertico--input t) (vertico--exhibit))
      (when-let* ((cand (vertico--candidate))
                   (type (get-text-property 0 'pmd-type cand))
                   (id (get-text-property 0 'pmd-id cand)))
        `(,type ,id . nil))))
  (add-to-list 'embark-target-finders #'pmd--embark-target))

(defun +pmd-cache-clear ()
  "Clear the PMD cache for all entity types."
  (interactive)
  (clrhash pmd--entities-data)
  (message "PMD cache cleared."))

(cl-defmacro pmd--with-cache-control (&rest body)
  "Execute `BODY' with cache refresh forced, if universal argument is given."
  `(let ((pmd--force-cache-refresh (if current-prefix-arg t nil)))
     ,@body))

(provide 'consult-pmd-core)
