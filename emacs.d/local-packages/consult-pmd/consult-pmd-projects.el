;;; consult-pmd-projects.el --- Project metadata lookup -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Consult helpers for internal project metadata.
;; Author: David Krentzlin
;; Keywords: tools, convenience
;;
;;; Code:

(require 'consult-pmd-core)
(require 'bookmark)
(require 'subr-x)
(require 'url-parse)

(defconst pmd--project-type 'pmd-project)

(defcustom my/code-path "~/code"
  "Base directory used for permanent project clones."
  :type 'directory
  :group 'consult-pmd)

(defcustom my/code-temp-path temporary-file-directory
  "Base directory used for temporary project clones."
  :type 'directory
  :group 'consult-pmd)

(defvar pmd--projects-history nil
  "History for PMD projects completion.")

(defun pmd--projects-display (data)
  "Return a display string for project metadata DATA."
  (let ((name (pmd--string (gethash "name" data)))
         (id (pmd--string (gethash "id" data))))
    (if (pmd--present-p name)
      name
      id)))

(defun pmd--projects-candidates ()
  "Return a list of project candidates for completion, sorted by name"
  (let ((projects (pmd--fetch-entities pmd--project-type "projects"))
         (candidates '()))
    (maphash
      (lambda (id value)
        (push (pmd--completion-candidate (pmd--projects-display value) pmd--project-type id) candidates))
      projects)
    (sort candidates #'string-lessp)))


;;;###autoload
(defun +pmd-projects ()
  "Consult project metadata projects."
  (interactive)
  (pmd--with-cache-control
    (let ((candidates (pmd--projects-candidates)))
      (when-let* ((project-id (consult--read
                                candidates
                                :prompt "PMD Projects: "
                                :category pmd--project-type
                                :history 'pmd--projects-history
                                :require-match t
                                :lookup #'consult--lookup-candidate
                                :group (pmd--grouping-fn "service_group")
                                :sort nil)))
        (pmd--browse-url (format "projects/%s" project-id))))))

(eval-when-compile
  (require 'marginalia))

(with-eval-after-load 'marginalia
  (defun pmd--projects-annotate (cand)
    "Annotate project CAND with metadata fields."
    (when-let* ((data (pmd--candidate-data cand)))
      (let ((contacts (pmd--list-string (pmd--dig data "people" "contact")))
             (head (pmd--string (pmd--dig data "people" "head"))))
        (marginalia--fields
          ((pmd--icon-team (gethash "team" data)) :face 'marginalia-value :width 18)
          ((pmd--string (gethash "service_type" data)) :face 'marginalia-type :width 20)
          ((pmd--string (gethash "org_unit" data)) :face 'marginalia-value :width 10)
          ((pmd--string (gethash "product_lifecycle" data)) :face 'marginalia-documentation :width 20)
          (head :face 'marginalia-on :width 20)
          (contacts :face 'marginalia-documentation :truncate 60)
          ((pmd--icon-tags (pmd--list-string (gethash "tags" data))) :face 'marginalia-symbol :width 20)))))

  (add-to-list 'marginalia-annotators `(,pmd--project-type pmd--projects-annotate)))

(with-eval-after-load 'embark
  (defun pmd--projects-repository-url (project)
    "Returns the full repository URL for `PROJECT'"
    (when-let* ((data (pmd--recover-entity pmd--project-type project)))
      (let* ((server-url (pmd--dig data "git" "server_url"))
              (account (pmd--dig data "git" "account"))
              (repo (pmd--dig data "git" "repo")))
        (format "%s/%s/%s" server-url account repo))))

  (defun pmd--projects-repository-slug (project)
    "Returns the repository slug for `PROJECT'"
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

  (defun pmd--projects-clone-repository (project base-path)
    "Clone PROJECT to BASE-PATH, reusing existing clones when present."
    (unless (and (stringp base-path) (not (string-empty-p base-path)))
      (user-error "Clone base path is not configured"))
    (when-let* ((repo-url (pmd--projects-repository-url project))
                 (repo-slug (pmd--projects-repository-slug project)))
      (let* ((forge (or (pmd--projects-forge-name repo-url)
                        (user-error "Could not derive forge from %s" repo-url)))
             (target-dir (expand-file-name
                           repo-slug
                           (expand-file-name forge (file-name-as-directory base-path))))
              (clone-url (pmd--projects-preferred-clone-url repo-url)))
        (if (file-directory-p target-dir)
          (message "Repository already exists: %s" target-dir)
          (make-directory (file-name-directory target-dir) t)
          (with-current-buffer (get-buffer-create "*pmd-git-clone*")
            (erase-buffer)
            (let ((exit-code (call-process "git" nil (current-buffer) t "clone" clone-url target-dir)))
              (if (zerop exit-code)
                (progn
                  (bookmark-store repo-slug `((filename . ,target-dir)) nil)
                  (message "Cloned %s to %s" repo-slug target-dir))
                (user-error "git clone failed for %s (see *pmd-git-clone*)" repo-slug))))))))

  (defun +pmd-clone-repository-permanent (project)
    "Clone PROJECT to `my/code-path'."
    (interactive "sProject ID: ")
    (pmd--projects-clone-repository project my/code-path))

  (defun +pmd-clone-repository-temporary (project)
    "Clone PROJECT to `my/code-temp-path'."
    (interactive "sProject ID: ")
    (pmd--projects-clone-repository project my/code-temp-path))

  (defun +pmd-copy-repo-url (project)
    "Copy the repository URL for `PROJECT' to clipboard."
    (interactive "sProject ID: ")
    (when-let* ((repo-url (pmd--projects-repository-url project)))
      (kill-new repo-url)
      (message "Copied repository URL: %s" repo-url)))

  (defun +pmd-open-repository (project)
    "Open the repository URL for `PROJECT' in browser."
    (interactive "sProject ID: ")
    (when-let* ((repo-url (pmd--projects-repository-url project)))
      (browse-url repo-url)))

  (defun +pmd-copy-repo-slug (project)
    "Copy the repository slug for `PROJECT' to clipboard."
    (interactive "sProject ID: ")
    (when-let* ((repo-slug (pmd--projects-repository-slug project)))
      (kill-new repo-slug)
      (message "Copied repository slug: %s" repo-slug)))

  (defun +pmd-open-teams-channel (project)
    "Open the MS Teams channel for `PROJECT' in browser."
    (interactive "sProject ID: ")
    (when-let* ((data (pmd--recover-entity pmd--project-type project))
                 (teams-channel (pmd--dig data "msteams" "channel_url")))
      (browse-url teams-channel)))

  (defun +pmd-open-teams-alerting-channel (project)
    "Open the MS Teams alerting channel for `PROJECT' in browser."
    (interactive "sProject ID: ")
    (when-let* ((data (pmd--recover-entity pmd--project-type project))
                 (alerting-channel (pmd--dig data "alerting" "msteams_channel_url")))
      (browse-url alerting-channel)))

  (defun +pmd-open-project-documentation (project)
    "Open the project documentation URL for `PROJECT' in browser."
    (interactive "sProject ID: ")
    (when-let* ((data (pmd--recover-entity pmd--project-type project))
                 (doc-url (pmd--dig data "documentation")))
      (if doc-url
        (browse-url doc-url)
        (message "No documentation URL found for project %s" project))))

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
    (defun +pmd-search-github-repo (project-id)
      (interactive "sProject ID: ")
      (when-let* ((repo-slug (pmd--projects-repository-slug project-id)))
        (consult-gh-search-code nil repo-slug)))

    (defun +pmd-browse-github-repo (project-id)
      (interactive "sProject ID: ")
      (when-let* ((repo-slug (pmd--projects-repository-slug project-id)))
        (consult-gh-dired repo-slug)))

    (keymap-set pmd-projects-embark-map "g" '+pmd-search-github-repo)
    (keymap-set pmd-projects-embark-map "e" '+pmd-browse-github-repo))

  (add-to-list 'embark-keymap-alist '(pmd-project . pmd-projects-embark-map)))


(provide 'consult-pmd-projects)
