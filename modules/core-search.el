;;; core-search.el --- Find things -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;;; Consult - Enhanced commands
(use-package consult
  :custom
  (consult-narrow-key "<")
  (consult-project-function (lambda (_) (project-root (project-current))))

  :config
  (setq consult-narrow-key "C-<")
  (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)

  (consult-customize
    consult-theme :preview-key '(:debounce 0.2 any)
    consult-ripgrep consult-git-grep consult-grep
    consult-bookmark consult-recent-file consult-xref
    :preview-key '(:debounce 0.4 any)))

(use-package embark-consult
  :after embark
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep
  :commands wgrep-change-to-wgrep-mode
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-change-readonly-file nil)
  :config
  (setq wgrep-enable-key "i"))

(use-package eww
  :straight (:type built-in)
  :bind
  (:map eww-mode-map
    ("C-c C-o" . eww-browse-with-external-browser)))

(use-package consult-notes
  :commands (consult-notes
              consult-notes-search-in-all-notes)
  :custom
  (consult-notes-denote-files-function (lambda () (denote-directory-files nil t nil)))
  (consult-notes-file-dir-sources
    `(("Library" ?l ,my/library-path)
       ("Org" ?o ,my/org-path)
       ("Notes" ?n ,my/notes-path)))
  :config
  (with-eval-after-load 'denote
    (consult-notes-denote-mode)))

;;;  P-Search
;;;; P-search - Powerful project-wide search
(use-package p-search
  :preface
  (defun +psearch-library ()
    "Search in library with p-search"
    (interactive)
    (let ((default-directory (expand-file-name my/library-path)))
      (call-interactively #'p-search)))

  :custom
  (p-search-default-searcher 'rg)
  (p-search-default-save-buffers 'ask)
  (p-search-case-fold-search t))

;;; Easy access to web bookmarks

(defun +quicklink ()
  "Open a quick link defined via `my/quicklinks'."
  (interactive)
  (require 'consult)
  (let* ((bookmark-names (mapcar #'car my/quicklinks)))
    (when-let* ((selection (consult--read
                             bookmark-names
                             :prompt "Select bookmark: "
                             :sort nil)))
      (let ((url (cdr (assoc selection  my/quicklinks))))
        (when url
          (browse-url url))))))

(provide 'core-search)
;;; core-search.el ends here
