;;; my-projects.el --- Projects and version control -*- lexical-binding: t; -*-

;;; Projects
(use-package project
  :custom
  (project-vc-extra-root-markers '(".project.el"))

  :bind
  (:map my/leader-map
        ("v" . project-vc-dir)
        (";" . project-compile))
  (:map my/project-prefix-map
        ("p" . project-switch-project))
  (:map goto-map
        ("f" . project-find-file)
        ("P" . project-switch-project))
  (:map search-map
        ("*" . +project-find-symbol))
  :preface
  (defun +project-find-symbol ()
    "Search for symbol under point in whole project"
    (interactive)
    (consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol))))

;;;; vc
(use-package vc
  :hook
  (vc-dir-mode . my/disable-meow-locally)
  :custom
  (vc-auto-revert-mode t)
  (vc-allow-rewriting-published-history t)
  (vc-dir-hide-up-to-date-on-revert t))

(use-package diff-hl
  :ensure t
  :hook
  (prog-mode . turn-on-diff-hl-mode)
  (text-mode . turn-on-diff-hl-mode)
  (vc-dir-mode . turn-on-diff-hl-mode)
  :config
  (unless (display-graphic-p)
    (require 'diff-hl-margin)
    (setq diff-hl-margin-symbols-alist
          '((insert . " ") (delete . " ") (change . " ")
            (unknown . " ") (ignored . " ")))
    (diff-hl-margin-mode 1)))

;;;; magit
(use-package magit
  :ensure t
  :pin "nongnu"
  :commands (magit-status)
  :custom
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1))

(provide 'my-projects)
;;; my-projects.el ends here
