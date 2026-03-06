;;; core-dashboard.el --- Dashboard configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Clean, minimal dashboard on startup

;;; Code:

;;;; Dashboard


(use-package dashboard
  :demand t
  :custom
  (dashboard-items '((recents . 5)
                      (projects . 8)
                      (bookmarks . 5)
                      (registers . 5)))

  (dashboard-banner-logo-title "MYMACS")
  (dashboard-startup-banner 'official)
  (dashboard-center-content t)
  (dashboard-show-shortcuts t)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)

  (dashboard-footer-messages '("Welcome home!"))
  (dashboard-footer-icon (nerd-icons-codicon "nf-cod-heart"
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
         "Hackernews"
         "Browse Hackernews"
         (lambda (&rest _) (eww-browse-url "https://news.ycombinator.com")))

        (,(nerd-icons-mdicon "nf-md-web" :height 1.1 :v-adjust 0.0)
          "Lobste"
          "Browse Lobste"
          (lambda (&rest _) (eww-browse-url "https://lobste.rs")))

        (,(nerd-icons-faicon "nf-fa-refresh" :height 1.1 :v-adjust 0.0)
          "Reload"
          "Reload dashboard"
          (lambda (&rest _) (dashboard-refresh-buffer))))))

  ;; Startup
  (dashboard-projects-backend 'project-el)
  (dashboard-path-style 'truncate-middle)
  (dashboard-path-max-length 60)

  :config

  (use-package hide-mode-line :demand t)

  (add-hook 'dashboard-mode-hook #'hide-mode-line-mode)

  ;; Use dashboard as initial buffer
  (dashboard-setup-startup-hook)

  ;; Refresh dashboard when opened
  (add-hook 'dashboard-mode-hook
    (lambda ()
      ;; Disable line numbers
      (display-line-numbers-mode -1)
      ;; Center content better
      (setq-local truncate-lines t))))

(provide 'core-dashboard)
;;; my-dashboard.el ends here
