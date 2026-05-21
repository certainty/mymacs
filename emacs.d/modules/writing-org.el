;;; writing-org.el --- Org-mode configuration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Org-mode visual and behavioral configuration.  Focuses on readable
;; documents with org-modern for visual improvements.  GTD workflow
;; (capture, agenda) is in writing-gtd.el.
;;
;;; Code:

;;; Org-mode
(use-package org
  :straight (:type built-in)
  :mode ("\\.org\\'" . org-mode)
  :custom
  (org-directory (file-truename (expand-file-name my/org-path)))

  ;; Aesthetics
  (org-auto-align-tags t)
  (org-catch-invisible-edits 'smart)
  (org-cycle-separator-lines 0)
  (org-ellipsis " [...]")
  (org-fontify-quote-and-verse-blocks t)
  (org-hide-emphasis-markers t)
  (org-hide-leading-stars t)
  (org-image-actual-width 500)
  (org-pretty-entities t)
  (org-startup-folded t)

  ;; Indentation
  (org-adapt-indentation nil)
  (org-startup-indented t)
  (org-src-preserve-indentation t)

  ;; Editing
  (org-return-follows-link t)
  (org-insert-heading-respect-content nil)
  (org-M-RET-may-split-line '((default . t)))
  (org-yank-adjusted-subtrees t)
  (org-list-allow-alphabetical t)

  ;; Logging
  (org-log-done 'time)
  (org-log-into-drawer t)

  ;; Source blocks
  (org-src-fontify-natively t)
  (org-src-window-setup 'other-window)
  (org-src-tab-acts-natively t)
  (org-confirm-babel-evaluate t)

  ;; Refile
  (org-refile-targets '((nil :maxlevel . 5)
                        (org-agenda-files :maxlevel . 5)))
  (org-outline-path-complete-in-steps nil)
  (org-refile-use-outline-path t)

  ;; Navigation
  (org-imenu-depth 8)

  :config
  ;; Fixed-pitch for code/tables in variable-pitch org docs
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

;;; Org-modern (visual improvements)
(use-package org-modern
  :straight t
  :hook
  ((org-mode . org-modern-mode)
   (org-agenda-finalize . org-modern-agenda)))

(provide 'writing-org)
;;; writing-org.el ends here
