;;; tools-gh.el --- GitHub search helpers -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Helpers around consult-gh for repo/code/PR workflows and cloning.
;;
;;; Code:

(use-package consult-gh-embark
  :after consult-gh
  :config
  (consult-gh-embark-mode 1))

(use-package consult-gh
  :general
  (leader-def
    "sg" '(:ignore t :which-key "github")
    "sgr" 'my/consult-gh-search-repos
    "sgc" 'my/consult-gh-search-code
    "sgp" 'my/consult-gh-search-prs
    "sgR" 'my/consult-gh-review-queue)

  :custom
  (consult-gh-default-clone-directory my/repositories-path)
  (consult-gh-show-preview t)
  (consult-gh-preview-key "C-o")
  (consult-gh-repo-action #'consult-gh--repo-browse-files-action)
  (consult-gh-large-file-warning-threshold 2500000)
  (consult-gh-confirm-name-before-fork nil)
  (consult-gh-confirm-before-clone t)
  (consult-gh-notifications-show-unread-only nil)
  (consult-gh-default-interactive-command #'consult-gh-transient)
  (consult-gh-prioritize-local-folder nil)
  (consult-gh-group-dashboard-by :reason)

  :preface
  (defvar my/gh-organizations '("new-work" "xing-com" "onlyfy"))

  (defun my/gh--repo-path (reponame)
    "Return canonical path for REPONAME (OWNER/REPO) under `my/repositories-path`."
    (pcase-let* ((host (or (consult-gh--auth-account-host) consult-gh-default-host "github.com"))
                  (`(,owner ,repo) (split-string reponame "/"))
                  (root (file-name-as-directory my/repositories-path)))
      (expand-file-name (format "%s/%s/%s" host owner repo) root)))

  (defun my/gh--ensure-dir (path)
    (let ((dir (file-name-directory path)))
      (unless (file-exists-p dir)
        (make-directory dir t))
      dir))

  (defun my/gh-clone-permanent (cand)
    "Clone selected repo CAND to the canonical repos path."
    (interactive "sRepo (owner/repo): ")
    (let* ((reponame (if (stringp cand) cand (get-text-property 0 :repo cand)))
            (target (my/gh--repo-path reponame))
            (dir (my/gh--ensure-dir target))
            (name (file-name-nondirectory target)))
      (consult-gh--repo-clone reponame name dir)
      (message "Cloned %s to %s" reponame target)
      target))

  (defun my/gh-clone-temp (cand)
    "Clone selected repo CAND to a temporary directory."
    (interactive "sRepo (owner/repo): ")
    (let* ((reponame (if (stringp cand) cand (get-text-property 0 :repo cand)))
            (dir (make-temp-file "gh-repo-" t))
            (name (file-name-nondirectory reponame)))
      (consult-gh--repo-clone reponame name dir)
      (message "Cloned %s to %s" reponame dir)
      dir))

  (defun my/consult-gh-search-repos ()
    "Search GitHub repos (consult-gh) with known orgs prioritized."
    (interactive)
    (let ((consult-gh--known-orgs-list (append my/gh-organizations consult-gh--known-orgs-list)))
      (consult-gh-search-repos)))

  (defun my/consult-gh-search-code ()
    "Search GitHub code via consult-gh."
    (interactive)
    (consult-gh-search-code))

  (defun my/consult-gh-search-prs ()
    "Search GitHub PRs via consult-gh."
    (interactive)
    (consult-gh-search-prs))

  (defun my/consult-gh-review-queue ()
    "List PRs requesting your review."
    (interactive)
    (let ((consult-gh-search-prs-args '("search" "prs" "--review-requested" "@me")))
      (consult-gh-search-prs)))

  (with-eval-after-load 'embark
    (embark-define-keymap my/embark-consult-gh-repo-map
      "Actions for GitHub repos."
      ("c" my/gh-clone-permanent)
      ("t" my/gh-clone-temp)
      ("b" consult-gh--repo-browse-url-action)
      ("v" consult-gh--repo-view-action))
    (add-to-list 'embark-keymap-alist '(consult-gh-repos . my/embark-consult-gh-repo-map))

    (embark-define-keymap my/embark-consult-gh-pr-map
      "Actions for GitHub PRs."
      ("o" consult-gh-pr-browse-url)
      ("v" consult-gh-pr-view)
      ("e" my/consult-gh-pr-export-org))
    (add-to-list 'embark-keymap-alist '(consult-gh-prs . my/embark-consult-gh-pr-map)))

  (defun my/consult-gh-pr-export-org (cand)
    "Export PR CAND to an Org TODO heading in the current buffer."
    (interactive (list (or (and (boundp 'vertico-last-input) vertico-last-input) (thing-at-point 'line t))))
    (let* ((repo (get-text-property 0 :repo cand))
            (title (or (get-text-property 0 :title cand) (string-trim (or (get-text-property 0 :title cand) (substring-no-properties cand)))))
            (url (or (get-text-property 0 :url cand)
                   (when (string-match "\\(https?://[^ ]+\\)" cand) (match-string 1 cand)))))
      (unless (derived-mode-p 'org-mode)
        (user-error "Run this action from an Org buffer"))
      (let ((heading (format "* TODO Review PR: %s\n:PROPERTIES:\n:REPO: %s\n:URL: %s\n:END:\n"
                       title (or repo "") (or url ""))))
        (save-excursion
          (goto-char (point-max))
          (insert heading))
        (message "Added PR to Org TODO: %s" title)))))

(provide 'tools-gh)
;;; tools-gh.el ends here
