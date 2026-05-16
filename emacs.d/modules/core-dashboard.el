;;; core-dashboard.el --- Startup dashboard -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; A clean, minimal dashboard on startup. Displays recent files, projects,
;; and bookmarks. Uses nerd-icons for a modern look.
;;
;;; Code:

(use-package dashboard
  :custom
  (dashboard-items '((recents . 5)
                      (projects . 5)
                      (bookmarks . 5)))
  (dashboard-banner-logo-title "MYMACS")
  (dashboard-startup-banner 'official)
  (dashboard-center-content t)
  (dashboard-show-shortcuts t)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-set-navigator-icons t)
  (dashboard-footer-messages '("Ready to hack!"))
  (dashboard-footer-icon (nerd-icons-faicon "nf-fa-heart"
                           :height 1.1
                           :v-adjust -0.05
                           :face 'font-lock-keyword-face))

  (dashboard-startupify-list '(dashboard-insert-banner
                                dashboard-insert-newline
                                dashboard-insert-banner-title
                                dashboard-insert-newline
                                dashboard-insert-navigator
                                dashboard-insert-newline
                                dashboard-insert-init-info
                                dashboard-insert-items
                                dashboard-insert-newline
                                dashboard-insert-footer))

  (dashboard-navigator-buttons
    `(((,(nerd-icons-mdicon "nf-md-web" :height 1.1 :v-adjust 0.0)
         "HN"
         "Hackernews"
         (lambda (&rest _) (browse-url "https://news.ycombinator.com")))
        (,(nerd-icons-mdicon "nf-md-web" :height 1.1 :v-adjust 0.0)
          "Lobsters"
          "Browse Lobste.rs"
          (lambda (&rest _) (browse-url "https://lobste.rs")))
        (,(nerd-icons-faicon "nf-fa-refresh" :height 1.1 :v-adjust 0.0)
          "Reload"
          "Reload dashboard"
          (lambda (&rest _) (dashboard-refresh-buffer))))))

  (dashboard-projects-backend 'project-el)
  (dashboard-path-style 'truncate-middle)
  (dashboard-path-max-length 60)

  :config
  ;; Disable mode line on dashboard
  (use-package hide-mode-line
    :hook (dashboard-mode . hide-mode-line-mode))

  ;; Global setup
  :init
  (dashboard-setup-startup-hook)

  ;; Buffer-local settings
  (add-hook 'dashboard-mode-hook
    (lambda ()
      (display-line-numbers-mode -1)
      (setq-local truncate-lines t))))

(provide 'core-dashboard)
;;; core-dashboard.el ends here
