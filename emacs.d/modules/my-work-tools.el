;;; my-work-tools.el --- Taskwarrior and PMD package integration -*- lexical-binding: t; -*-

;;;; PMD
(use-package consult-pmd
  :if my/pmd-enabled
  :commands +pmd-cache-clear
  :bind
  (:map my/pmd-prefix-map
        ("," . +pmd-projects)
        ("t" . +pmd-teams)
        ("p" . +pmd-people)
        ("s" . +pmd-servicegroups)
        ("c" . +pmd-cache-clear))
  :custom
  (pmd-base-url my/pmd-base-url)
  :load-path "user-lisp")

(provide 'my-work-tools)
;;; my-work-tools.el ends here
