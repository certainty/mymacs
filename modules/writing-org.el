;;; wriging-org.el --- Org -*- lexical-binding: t; -*-

(use-package org
  :commands (org-mode)
  :mode (("\\.org$" . org-mode))
  :custom
  (org-directory (file-truename (expand-file-name my/org-path))
    (org-attach-id-dir (concat org-directory "/.attach/")))

  ;; Aesthetics & UI
  (org-auto-align-tags t)
  (org-catch-invisible-edits 'smart)
  (org-cycle-separator-lines 0)
  (org-ellipsis "…")
  (org-fontify-quote-and-verse-blocks t)
  (org-hide-emphasis-markers t)
  (org-hide-leading-stars t)
  (org-image-actual-width  500)
  (org-pretty-entities t)
  (org-pretty-entities-include-sub-superscripts t)
  (org-read-date-prefer-future 'time)
  (org-startup-folded t)


  ;; Footnotes
  (org-footnote-section nil)   ;; place footnotes locally
  (org-footnote-auto-adjust t) ;; renumber footnotes

  ;; Indentation
  (org-adapt-indentation nil)      ;; adapt indentation
  (org-startup-indented t)         ;; start with indentation of headlines
  (org-src-preserve-indentation t) ;; preserve code indentation

  ;; Insertion/Yanking
  (org-insert-heading-respect-content nil) ;; I never want to insert after subtree NOOOO
  (org-M-RET-may-split-line '((default . t))) ;; don't split line when creating a new headline, list item, or table field
  (org-yank-adjusted-subtrees t) ;; adjust subtrees to depth when yanked

  ;; Lists
  (org-list-allow-alphabetical t) ;; allow alphabetical list

  ;; Logging
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-log-state-notes-insert-after-drawers nil)
  (org-log-redeadline nil) ;; don't log the time a task was rescheduled/redeadlined.
  (org-log-reschedule nil)

  ;; Movement
  (org-return-follows-link t) ;; make RET follow links
  (org-special-ctrl-a/e nil)

  ;; Searching
  (org-imenu-depth 12)   ;; scan to depth 8 w/imenu
  (imenu-auto-rescan t) ;; make sure imenu refreshes

  ;; Source block settings
  (org-src-fontify-natively t)         ;; use lang-specific fontification
  (org-src-window-setup 'other-window) ;; edit source in other window
  (org-src-tab-acts-natively t)        ;; use lang bindings
  (org-confirm-babel-evaluate t)       ;; confirm evaluation

  ;; Refiling
  (org-refile-targets
    '((nil :maxlevel . 5)
       (org-agenda-files :maxlevel . 5)))

  (org-outline-path-complete-in-steps nil)
  (org-refile-use-outline-path t)

  ;; Images
  (org-display-inline-images t)

  :config
  (require 'org-faces)

  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-formula nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)


                                        ; export
  (require 'ox-latex)
  (setq org-latex-pdf-process
    '("pdflatex -interaction nonstopmode -output-directory %o %f"
       "pdflatex -interaction nonstopmode -output-directory %o %f"))

  (add-to-list 'display-buffer-alist
    '("\\*Org \\(Select\\|Note\\)\\*"
       (display-buffer-in-side-window)
       (dedicated . t)
       (side . bottom)
       (slot . 0)
       (window-parameters . ((mode-line-format . none))))))

;; use org-modern
(use-package org-modern
  :straight (org-modern :type git :host github :repo "minad/org-modern")
  :hook
  (after-init . global-org-modern-mode)
  (org-agenda-finalize . org-modern-agenda)
  :custom
  (org-modern-fold-stars '(("◉" . "◉") ("○" . "○") ("◈" . "◈") ("◇" . "◇") ("◦" . "◦")))
  :config
  (org-indent-mode t))

(provide 'writing-org)
