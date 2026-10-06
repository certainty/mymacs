;;; my-projects.el --- Projects and version control -*- lexical-binding: t; -*-

;;; Projects
(use-package project
  :bind
  (:map my/leader-map
        ("f" . project-find-file)
        ("e" . project-dired)
        (";" . project-compile))
  (:map my/project-prefix-map
        ("p" . project-switch-project))
  (:map goto-map
        ("f" . project-find-file)
        ("P" . project-switch-project))
  (:map search-map
        ("*" . +project-find-symbol))
  :custom
  (project-vc-extra-root-markers '(".project.el"))
  :preface
  (defun +project-find-symbol ()
    "Search for symbol under point in whole project"
    (interactive)
    (consult-ripgrep (project-root (project-current t)) (thing-at-point 'symbol))))

;;;; vc
(use-package vc
  :custom
  (vc-auto-revert-mode t)
  (vc-allow-rewriting-published-history t)
  (vc-dir-hide-up-to-date-on-revert t)
  :preface
  (defun my/vc-git-close-successful-pushpull (original command &rest args)
    "Close the VC Git output window after a successful push or pull."
    (let ((process (apply original command args)))
      (when (member command '("push" "pull"))
        (let ((buffer (process-buffer process)))
          (vc-exec-after
           (lambda ()
             (when (buffer-live-p buffer)
               (dolist (window (get-buffer-window-list buffer nil t))
                 (quit-window nil window))))
           0 process)))
      process))
  :config
  (with-eval-after-load 'vc-git
    (advice-add 'vc-git--pushpull :around
                #'my/vc-git-close-successful-pushpull)))

(use-package diff-hl
  :ensure t
  :hook
  (prog-mode . turn-on-diff-hl-mode)
  (text-mode . turn-on-diff-hl-mode)
  (vc-dir-mode . turn-on-diff-hl-mode)
  :custom
  (diff-hl-draw-borders nil)
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
  :bind
  (:map my/leader-map
        ("v" . magit-status))
  :custom
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1))

(provide 'my-projects)
;;; my-projects.el ends here
