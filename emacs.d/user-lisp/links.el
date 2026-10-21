;;; links.el --- Frequently used web links -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0"))
;;; Commentary:
;; Select and open frequently used web links with Consult.
;;
;;; Code:

(require 'browse-url)
(require 'consult)
(require 'json)

(defvar links/quick-links-history nil
  "History of selections made by `+links-bookmarks'.")
(defvar links/pull-request-history nil
  "History of selections made by `+links-project-pull-requests'.")

(defun my--open-url (url)
  "Open URL with the platform URL handler."
  (let ((browse-url-generic-program
         (pcase system-type
           ('gnu/linux "xdg-open")
           ('darwin "open"))))
    (if browse-url-generic-program
        (let ((browse-url-browser-function #'browse-url-generic))
          (browse-url url))
      (browse-url url))))

(defun my--repository-remote-to-url (remote)
  "Return the browser URL corresponding to Git REMOTE.
REMOTE may use an HTTPS, Git, SSH, or SCP-like Git URL."
  (let ((remote (string-remove-suffix ".git" (string-trim remote))))
    (cond
     ((string-match
       "\\`\\(?:https?\\|git\\)://\\([^/]+\\)/\\(.+\\)\\'" remote)
      (format "https://%s/%s"
              (match-string 1 remote)
              (match-string 2 remote)))
     ((string-match
       "\\`\\(?:ssh://\\)?\\(?:[^@/:]+@\\)?\\([^/:]+\\)[:/]\\(.+\\)\\'" remote)
      (format "https://%s/%s"
              (match-string 1 remote)
              (match-string 2 remote)))
     (t
      (user-error "Cannot derive a browser URL from remote: %s" remote)))))

(defun my--project-root ()
  "Return the root directory of the current project."
  (require 'project)
  (let ((project (project-current nil)))
    (unless project
      (user-error "Current directory is not in a project"))
    (project-root project)))

(defun my--project-command (program &rest arguments)
  "Run PROGRAM with ARGUMENTS from the current project root.
Return its trimmed standard output or signal its error output as a user error."
  (let ((default-directory (my--project-root)))
    (with-temp-buffer
      (condition-case nil
          (if (zerop (apply #'process-file program nil t nil arguments))
              (string-trim (buffer-string))
            (user-error "%s" (string-trim (buffer-string))))
        (file-missing
         (user-error "%s executable is not available" program))))))

(defun my--project-origin-url ()
  "Return the browser URL for the current project's origin remote."
  (my--repository-remote-to-url
   (my--project-command "git" "remote" "get-url" "origin")))

;;;###autoload
(defun +links-project-repository ()
  "Open the current project's origin repository in a browser."
  (interactive)
  (my--open-url (my--project-origin-url)))

;;;###autoload
(defun my--github-pull-request-candidates ()
  "Return completion candidates for the current GitHub project's open PRs."
  (let* ((pull-requests
          (condition-case error-data
              (json-parse-string
               (my--project-command
                "gh" "pr" "list" "--limit" "100"
                "--json" "number,title,url,headRefName")
               :object-type 'alist
               :array-type 'list)
            (json-parse-error
             (user-error "Cannot parse GitHub pull requests: %s"
                         (error-message-string error-data)))))
         (candidates
          (mapcar
           (lambda (pull-request)
             (let ((number (alist-get "number" pull-request nil nil #'string=))
                   (title (alist-get "title" pull-request nil nil #'string=))
                   (branch (alist-get "headRefName" pull-request nil nil #'string=))
                   (url (alist-get "url" pull-request nil nil #'string=)))
               (cons (format "#%s %s (%s)" number title branch) url)))
           pull-requests)))
    (unless candidates
      (user-error "No open pull requests in this repository"))
    candidates))

;;;###autoload
(defun +links-project-pull-requests ()
  "Select and open an open pull request from the current GitHub project."
  (interactive)
  (let* ((candidates (my--github-pull-request-candidates))
         (selection (completing-read "Pull request: " candidates nil t nil
                                    'links/pull-request-history))
         (url (alist-get selection candidates nil nil #'string=)))
    (my--open-url url)))

;;;###autoload
(defun +links-current-branch-pull-request ()
  "Open the current branch PR or its GitHub creation page."
  (interactive)
  (let ((default-directory (my--project-root)))
    (condition-case nil
        (with-temp-buffer
          (if (zerop (process-file "gh" nil t nil
                                  "pr" "view" "--json" "url" "--jq" ".url"))
              (my--open-url (string-trim (buffer-string)))
            (my--project-command "gh" "pr" "create" "--web")))
      (file-missing
       (user-error "gh executable is not available")))))

(defun my--project-command-result (program &rest arguments)
  "Run PROGRAM with ARGUMENTS from the project root.
Return a cons of exit status and trimmed standard output."
  (let ((default-directory (my--project-root)))
    (with-temp-buffer
      (let ((status (apply #'process-file program nil t nil arguments)))
        (cons status (string-trim (buffer-string)))))))

(defun my--current-branch-pull-request ()
  "Return metadata for the current branch pull request, or nil if absent."
  (let ((branch (my--project-command "git" "branch" "--show-current")))
    (when (string-empty-p branch)
      (user-error "Current directory is not on a branch"))
    (car (json-parse-string
          (my--project-command "gh" "pr" "list"
                               "--head" branch "--state" "all"
                               "--limit" "1"
                               "--json"
                               "number,title,state,headRefName,reviewDecision,url")
          :object-type 'alist
          :array-type 'list))))

(defun my--pull-request-checks (number)
  "Return check details for pull request NUMBER, or :unavailable."
  (let* ((result (my--project-command-result
                  "gh" "pr" "checks" number
                  "--json" "name,bucket"))
         (checks (condition-case nil
                     (json-parse-string (cdr result)
                                        :object-type 'alist
                                        :array-type 'list)
                   (json-parse-error :invalid)))
         (status (car result)))
    (if (or (eq checks :invalid)
            (and (null checks) (not (zerop status))))
        :unavailable
      checks)))

(defun my--pull-request-check-summary (checks)
  "Return a concise summary for pull request CHECKS."
  (if (eq checks :unavailable)
      "unavailable"
    (let ((buckets (mapcar (lambda (check)
                             (alist-get "bucket" check nil nil #'string=))
                           checks)))
      (cond
       ((null checks) "no checks")
       ((member "fail" buckets) "failing")
       ((member "pending" buckets) "pending")
       ((member "cancel" buckets) "cancelled")
       ((equal buckets (make-list (length buckets) "pass")) "passing")
       ((member "skipping" buckets) "skipped")
       (t "mixed")))))

(defun my--display-pull-request-info (pull-request checks)
  "Display PULL-REQUEST and CHECKS in a read-only buffer."
  (let ((buffer (get-buffer-create "*Current PR*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (special-mode)
        (insert "Pull request status\n"
                "===================\n\n")
        (if pull-request
            (let ((number (alist-get "number" pull-request nil nil #'string=))
                  (title (alist-get "title" pull-request nil nil #'string=))
                  (state (alist-get "state" pull-request nil nil #'string=))
                  (branch (alist-get "headRefName" pull-request nil nil #'string=))
                  (review (alist-get "reviewDecision" pull-request nil nil #'string=))
                  (url (alist-get "url" pull-request nil nil #'string=)))
              (insert (format "#%s %s\n" number title)
                      (format "State:   %s\n" (downcase (or state "unknown")))
                      (format "Branch:  %s\n" (or branch "unknown"))
                      (format "Review:  %s\n"
                              (pcase review
                                ("APPROVED" "approved")
                                ("CHANGES_REQUESTED" "changes requested")
                                ("REVIEW_REQUIRED" "review required")
                                (_ "not yet approved")))
                      (format "Checks:  %s\n" (my--pull-request-check-summary checks))
                      (format "URL:     %s\n\n" (or url "unavailable"))
                      "Checks:\n")
              (cond
               ((eq checks :unavailable)
                (insert "  Check details unavailable.\n"))
               ((null checks)
                (insert "  No checks reported.\n"))
               (t
                (dolist (check checks)
                  (insert (format "  %s: %s\n"
                                  (upcase (or (alist-get "bucket" check nil nil #'string=)
                                              "unknown"))
                                  (or (alist-get "name" check nil nil #'string=)
                                      "Unnamed check")))))))
          (insert "No pull request found for the current branch.\n"))
        (goto-char (point-min))))
    (pop-to-buffer buffer)))

;;;###autoload
(defun +links-current-branch-pull-request-info ()
  "Show details and CI status for the current branch pull request."
  (interactive)
  (message "Gathering PR information...")
  (redisplay t)
  (condition-case nil
      (let* ((pull-request (my--current-branch-pull-request))
             (checks (when pull-request
                       (my--pull-request-checks
                        (number-to-string
                         (alist-get "number" pull-request nil nil #'string=))))))
        (my--display-pull-request-info pull-request checks))
    (file-missing (user-error "gh executable is not available"))))

;;;###autoload
(defun +links-bookmarks ()
  "Select a frequently used web bookmark and open it."
  (interactive)
  (when-let* ((description
               (consult--read
                (mapcar #'car my/quick-links)
                :prompt "Web bookmark: "
                :category 'links-bookmark
                :history 'links/quick-links-history
                :require-match t
                :sort nil))
              (url (alist-get description my/quick-links nil nil #'string=)))
    (my--open-url url)))

(provide 'links)
;;; links.el ends here
