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
    "sgR" 'my/consult-gh-review-queue
    "sgg" '(:ignore t :which-key "global")
    "sggr" 'my/consult-gh-search-repos-global
    "sggc" 'my/consult-gh-search-code-global
    "sggp" 'my/consult-gh-search-prs-global
    "sggR" 'my/consult-gh-review-queue-global)

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
  (my/gh-organizations '("new-work" "xing-com" "onlyfy" "david-krentzlin"))

  :preface
  (defcustom my/gh-organizations nil
    "List of GitHub organizations/users to prioritize in prompts."
    :type '(repeat string)
    :group 'mymacs)
  (defvar my/gh-last-org nil)

  (defun my/gh--read-org ()
    (unless my/gh-organizations
      (user-error "Set `my/gh-organizations' to use org-scoped GitHub search"))
    (let ((choice (completing-read "Org: " my/gh-organizations nil t nil nil my/gh-last-org)))
      (setq my/gh-last-org choice)
      choice))

  (defun my/gh--org-prefill ()
    (format "org:%s#" (my/gh--read-org)))

  (defun my/gh--repo-path (reponame)
    "Return canonical path for REPONAME (OWNER/REPO) under `my/repositories-path`."
    (pcase-let* ((host (or (consult-gh--auth-account-host) consult-gh-default-host "github.com"))
                  (`(,owner ,repo) (split-string reponame "/"))
                  (root (file-name-as-directory my/repositories-path)))
      (expand-file-name (format "%s/%s/%s" host owner repo) root)))

  (defun my/gh--temp-repo-path (reponame)
    "Return temp path for REPONAME (OWNER/REPO) under ~/tmp/code."
    (pcase-let* ((`(,owner ,repo) (split-string reponame "/"))
                  (root (file-name-as-directory (expand-file-name "~/tmp/code"))))
      (expand-file-name (format "%s/%s" owner repo) root)))

  (defun my/gh--ensure-dir (path)
    (let ((dir (file-name-directory path)))
      (unless (file-exists-p dir)
        (make-directory dir t))
      dir))

  (defvar my/gh--last-clone-target nil
    "Most recent clone target to open in Dired after clone completes.")

  (defun my/gh--maybe-dired-after-clone (path)
    (when (and my/gh--last-clone-target
            (string= (file-truename path) (file-truename my/gh--last-clone-target)))
      (setq my/gh--last-clone-target nil)
      (dired-jump-other-window path)))

  (defun my/gh--repo-from-cand (cand)
    "Extract OWNER/REPO from CAND."
    (let* ((raw (cond
                  ((stringp cand) cand)
                  ((and (consp cand) (stringp (car cand))) (car cand))
                  (t (format "%s" cand)))))
      (or (get-text-property 0 :repo raw)
        (car (split-string (string-trim raw) "[[:space:]]+" t)))))

  (defun my/gh-clone-permanent (cand)
    "Clone selected repo CAND to the canonical repos path."
    (interactive "sRepo (owner/repo): ")
    (let* ((reponame (my/gh--repo-from-cand cand))
            (target (my/gh--repo-path reponame))
            (dir (my/gh--ensure-dir target))
            (name (file-name-nondirectory target)))
      (setq my/gh--last-clone-target target)
      (consult-gh--repo-clone reponame name dir)
      (message "Cloning %s to %s..." reponame target)
      target))

  (defun my/gh-clone-temp (cand)
    "Clone selected repo CAND to a temporary directory."
    (interactive "sRepo (owner/repo): ")
    (let* ((reponame (my/gh--repo-from-cand cand))
           (target (my/gh--temp-repo-path reponame))
           (dir (my/gh--ensure-dir target))
           (name (file-name-nondirectory target)))
      (setq my/gh--last-clone-target target)
      (consult-gh--repo-clone reponame name dir)
      (message "Cloning %s to %s..." reponame target)
      target))

  (defun my/consult-gh-search-repos ()
    "Search GitHub repos limited to internal organizations."
    (interactive)
    (consult-gh-search-repos (my/gh--org-prefill)))

  (defun my/consult-gh-search-repos-global ()
    "Search GitHub repos globally."
    (interactive)
    (consult-gh-search-repos))

  (defun my/consult-gh-search-code ()
    "Search GitHub code via consult-gh."
    (interactive)
    (consult-gh-search-code (my/gh--org-prefill)))

  (defun my/consult-gh-search-code-global ()
    "Search GitHub code globally."
    (interactive)
    (consult-gh-search-code))

  (defun my/consult-gh-search-prs ()
    "Search GitHub PRs via consult-gh."
    (interactive)
    (consult-gh-search-prs (my/gh--org-prefill)))

  (defun my/consult-gh-search-prs-global ()
    "Search GitHub PRs globally."
    (interactive)
    (consult-gh-search-prs))

  (defun my/consult-gh-review-queue ()
    "List PRs requesting your review."
    (interactive)
    (let ((consult-gh-search-prs-args '("search" "prs" "--review-requested" "@me")))
      (consult-gh-search-prs (my/gh--org-prefill))))

  (defun my/consult-gh-review-queue-global ()
    "List PRs requesting your review (global)."
    (interactive)
    (let ((consult-gh-search-prs-args '("search" "prs" "--review-requested" "@me")))
      (consult-gh-search-prs)))

  (add-hook 'consult-gh-repo-post-clone-hook #'my/gh--maybe-dired-after-clone)


  (defvar my/embark-consult-gh-repo-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "c") #'my/gh-clone-permanent)
      (define-key map (kbd "t") #'my/gh-clone-temp)
      (define-key map (kbd "b") #'consult-gh--repo-browse-url-action)
      (define-key map (kbd "v") #'consult-gh--repo-view-action)
      map)
    "Embark keymap for consult-gh repo candidates.")

  (defvar my/embark-consult-gh-pr-map
    (let ((map (make-sparse-keymap)))
      (define-key map (kbd "o") #'consult-gh-pr-browse-url)
      (define-key map (kbd "v") #'consult-gh-pr-view)
      (define-key map (kbd "e") #'my/consult-gh-pr-export-org)
      map)
    "Embark keymap for consult-gh PR candidates.")

  (with-eval-after-load 'embark
    (add-to-list 'embark-keymap-alist '(consult-gh-repos . my/embark-consult-gh-repo-map))
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
