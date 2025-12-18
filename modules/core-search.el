;;; core-search.el --- Find things -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 David Krentzlin
;;
;; Author: David Krentzlin <david.krentzlin@new-work.se>
;; Maintainer: David Krentzlin <david.krentzlin@new-work.se>
;; Created: December 17, 2025
;; Modified: December 17, 2025
;; Version: 0.0.1
;; Keywords: Symbol’s value as variable is void: finder-known-keywords
;; Homepage: https://github.com/david-krentzlin/core-search
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;;; Consult - Enhanced commands
(use-package consult
  :bind (;; M-s bindings (search map)
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)

         ;; M-g bindings (goto map)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi))
  :general
  (leader-def
   "!!" 'consult-flymake
   "!c" 'consult-compile-error
   "bb" 'consult-buffer
   "fr" 'consult-recent-file
   "gg" 'consult-goto-line
   "go" 'consult-outline
   "gm" 'consult-mark
   "ss" 'consult-line
   "sr" 'consult-ripgrep
   "si" 'consult-imenu
   "sI" 'consult-imenu-multi
   "sO" 'consult-outline)
  :custom
  (consult-narrow-key "<")
  (consult-project-function (lambda (_) (project-root (project-current))))

  :config
                                        ; Configure preview
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   :preview-key '(:debounce 0.4 any)))

(use-package wgrep
  :commands wgrep-change-to-wgrep-mode
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-change-readonly-file nil)
  :config
  (setq wgrep-enable-key "i"))

;;;  P-Search
;;;; P-search - Powerful project-wide search
(use-package p-search
  :general
  (leader-def
   "sx" 'p-search
   "sX" 'p-search-directory)
  :custom
  (p-search-default-searcher 'rg)
  (p-search-default-save-buffers 'ask)
  (p-search-case-fold-search t))

;;;; Helper functions for directory-specific searches
(defun my/search-in-directory (dir)
  "Search in DIR using p-search."
  (let ((default-directory (expand-file-name dir)))
    (call-interactively #'p-search)))

(defun my/search-notes ()
  "Search in notes directory using p-search."
  (interactive)
  (my-search-in-directory my/notes-path))

(defun my/search-org ()
  "Search in org directory using p-search."
  (interactive)
  (my-search-in-directory my/org-path))



(provide 'core-search)
;;; core-search.el ends here
