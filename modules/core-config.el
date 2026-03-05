;;; core-config.el --- Basic configuration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(use-package emacs
  :custom
  (user-full-name "David Krentzlin")
  (custom-file (expand-file-name "custom.el" user-emacs-directory))

  :init

  (when (my/context-private-p)
    (setopt my/repositories-path "~/Code")
    (setopt user-mail-address "david@krentzlin.me"))

  (when (my/context-work-p)
    (setopt my/org-path "~/Documents/Org")
    (setopt my/notes-path "~/Documents/Notes")
    (setopt my/managed-documents-path "~/Documents/Notes")
    (setopt my/repositories-path "~/NewWork/Code")
    (setopt my/library-path "~/Documents/Library")
    (setopt user-mail-address "david.krentzlin@new-work.se")
    (setopt my/quicklinks
      '(("Platform Docs" . "https://platform.nwse.io/main/latest/landing-page.html")
         ("Jira" . "https://new-work.atlassian.net/jira/software/c/projects/BFX/boards/1618")
         ("Confluence" . "https://new-work-se.atlassian.net/wiki/home")
         ("Workday" . "https://wd103.myworkday.com/xing/d/home.htmld")
         ("NW1" . "https://github.com/new-work/new-work-one")
         ("Argo CD Preview" . "https://argocd.odyssey.preview.nwse.cloud")
         ("Argo CD Production" . "https://argocd.odyssey.production.nwse.cloud")
         ("Broker Secondary Production" . "https://central-messaging-broker-secondary-wkkgn.main.odyssey.production.nwse.cloud/")
         ("Broker Primary Production" . "https://central-messaging-broker-nlls7.main.odyssey.production.nwse.cloud/")
         ("Broker Primary Preview" . "https://central-messaging-broker-hqk78.main.odyssey.preview.nwse.cloud/"))))

  (when (memq window-system '(mac ns))
    (setopt my/font-size 130)
    (setopt my/bigger-font-size 170)
    (setopt my/presentation-font-size 230)))

(provide 'core-config)
;;; core-config.el ends here
