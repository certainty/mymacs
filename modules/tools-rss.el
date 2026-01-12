;;; core-mymacs.el --- configure mymacs -*- lexical-binding: t; -*-

(use-package elfeed
  :general
  (leader-def
    "xr" 'elfeed)
  :custom
  (elfeed-search-filter "@2-week-ago +unread ")
  (elfeed-db-directory
    (expand-file-name my/elfeed-directory))
  (elfeed-show-entry-switch 'display-buffer)

  :config
  (add-hook 'elfeed-new-entry-hook
    (elfeed-make-tagger :before "4 weeks ago"
      :remove 'unread)
    (elfeed-make-tagger :feed-url "youtube\\.com"
      :add '(video youtube))))

(use-package elfeed-org
  :custom
  (rmh-elfeed-org-files (list (expand-file-name "data/elfeed.org" user-emacs-directory)))
  :init
  (with-eval-after-load 'elfeed
    (elfeed-org)))

(use-package org-web-tools
  :bind
  (("C-c w w" . org-web-tools-insert-link-for-url)))

(provide 'tools-rss)
