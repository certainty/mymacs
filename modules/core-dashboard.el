;;; core-dashboard.el --- Dashboard configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Clean, minimal dashboard on startup

;;; Code:

;;;; Dashboard
(use-package dashboard
  :demand t
  :general
  (leader-def
    "td" 'dashboard-open)
  :custom
  (dashboard-items '((recents . 5)
                      (projects . 8)
                      (bookmarks . 5)
                      (registers . 5)))

  (dashboard-banner-logo-title "MYMACS")
  (dashboard-startup-banner 'logo)
  (dashboard-center-content t)
  (dashboard-show-shortcuts nil)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-set-navigator t)

  (dashboard-footer-messages '("Welcome home!"))
  (dashboard-footer-icon (nerd-icons-codicon "nf-cod-heart"
                           :height 1.1
                           :v-adjust -0.05
                           :face 'font-lock-keyword-face))

  (dashboard-navigator-buttons
    `(((,(nerd-icons-faicon "nf-fa-github" :height 1.1 :v-adjust 0.0)
         "GitHub"
         "Browse GitHub"
         (lambda (&rest _) (browse-url "https://github.com")))
        (,(nerd-icons-faicon "nf-fa-refresh" :height 1.1 :v-adjust 0.0)
          "Reload"
          "Reload dashboard"
          (lambda (&rest _) (dashboard-refresh-buffer))))))

  ;; Startup
  (dashboard-projects-backend 'project-el)
  (dashboard-path-style 'truncate-middle)
  (dashboard-path-max-length 60)

  :config
  ;; Use dashboard as initial buffer
  (dashboard-setup-startup-hook)

  ;; Refresh dashboard when opened
  (add-hook 'dashboard-mode-hook
    (lambda ()
      ;; Disable line numbers
      (display-line-numbers-mode -1)
      ;; Center content better
      (setq-local truncate-lines t)))

  ;; Evil bindings for dashboard
  (with-eval-after-load 'evil
    (evil-set-initial-state 'dashboard-mode 'normal)
    (evil-define-key 'normal dashboard-mode-map
      (kbd "R") 'dashboard-refresh-buffer
      (kbd "r") 'dashboard-jump-to-recents
      (kbd "p") 'dashboard-jump-to-projects
      (kbd "b") 'dashboard-jump-to-bookmarks
      (kbd "RET") 'dashboard-return
      (kbd "q") 'quit-window)))

(provide 'core-dashboard)
;;; my-dashboard.el ends here
