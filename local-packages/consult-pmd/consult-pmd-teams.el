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

(with-eval-after-load 'embark
  (defun pmd--team-channel-url (team-id)
    "Return the PMD team channel URL for TEAM-ID."
    (let* ((data (pmd--recover-entity pmd--team-type team-id)))
      (pmd--dig data "msteams" "channel_url")))

  (defun +pmd-open-team-channel (team-id)
    "Open the PMD team channel in the browser."
    (interactive)
    (when-let ((url (pmd--team-channel-url team-id)))
      (browse-url url)))

  (defun +pmd-copy-team-channel-url (team-id)
    "Copy the PMD team channel URL to the clipboard."
    (interactive)
    (when-let ((url (pmd--team-channel-url team-id)))
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
    "Open the PMD team alerting channel in the browser."
    (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
                 (alerting-url (pmd--string (pmd--dig data "alerting" "msteams_channel_url"))))
      (kill-new alerting-url)
      (message "Copied alerting channel URL to clipboard.")))

  (defun +pmd-open-team-confluence (team-id)
    "Open the Confluence page of TEAM-ID in the browser."
    (when-let* ((data (pmd--recover-entity pmd--team-type team-id))
                 (confluence-key (pmd--string (pmd--dig data "confluence" "key"))))
      (browse-url (format "https://new-work.atlassian.net/wiki/spaces/%s"))))

  (defvar-keymap pmd-teams-embark-map
    :doc "Keymap for PMD teams metadata embark actions."
    "t" '+pmd-open-team-channel
    "T" '+pmd-copy-team-channel-url
    "e" '+pmd-copy-team-email
    "c" '+pmd-open-team-confluence
    "a" '+pmd-open-team-alerting-channel
    "A" '+pmd-copy-team-alerting-channel)

  (add-to-list 'embark-keymap-alist `(,pmd--team-type . pmd-teams-embark-map)))

(provide 'consult-pmd-teams)
