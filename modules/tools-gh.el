;;; tools-gh.el --- GitHub search helpers -*- lexical-binding: t; -*-
;;
;;; Commentary:
;; Helpers around consult-gh for repo/code/PR workflows and cloning.
;;
;;; Code:

(use-package consult-gh
  :general
  (leader-def
    "sg" '(:ignore t :which-key "github")
    "sgg" 'consult-gh-repo-list
    "sgu" 'consult-gh-user-repos
    "sgf" 'consult-gh-favorite-repos
    "sgp" '(:ignore t :which-key "prs")
    "sgpp" 'consult-gh-pr-list
    "sga" '(:ignore t :which-key "actions")
    "sgaa" 'consult-gh-run-list
    "sgd" 'consult-gh-dashboard)
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
  (consult-gh-group-repos-by t)
  (consult-gh-repo-maxnum 1000) ; we have lots of repos
  (consult-gh-favorite-orgs-list '("xing-com" "new-work"))

  :preface
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

  (defun +clone-permanent (cand)
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

  (defun +clone-temp (cand)
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

  :config
  (add-hook 'consult-gh-repo-post-clone-hook #'my/gh--maybe-dired-after-clone))

(use-package consult-gh-embark
  :after embark
  :general
  (:keymaps 'consult-gh-embark-repos-actions-map
    "rp" '+clone-permanent
    "rt" '+clone-temp)
  :init
  (consult-gh-embark-mode 1))

(use-package consult-gh-forge
  :config
  (consult-gh-forge-mode +1))

(provide 'tools-gh)
;;; tools-gh.el ends here
