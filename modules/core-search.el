;;; core-search.el --- Find things -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;;; Consult - Enhanced commands
(use-package consult
  :bind
  (:map my/leader-map
    ("r" . consult-recent-file))
  (:map +search
    ("d" . consult-flymake)
    ("b" . consult-buffer)
    ("B" . consult-buffer-other-window)
    ("r" . consult-bookmark)
    ("g" . consult-goto-line)
    ("j" . consult-global-mark) ;; jump list
    ("l" . consult-line)
    ("L" . consult-line-multi)
    ("r" . consult-ripgrep)
    ("i" . consult-imenu)
    ("I" . consult-imenu-multi))
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

(defun +search-web ()
  "Search the web (engines/wiki) via consult-omni."
  (interactive)
  (consult-omni-multi nil "Web: " '("DuckDuckGo API" "Wikipedia") nil nil :group 'domain))

(defun +system-files ()
  "Search local files and content via consult-omni."
  (interactive)
  (consult-omni-multi nil "Local: " '("fd" "locate") nil))

(defun +rtfm ()
  "Search reference material (man, notes, dictionaries, etc.) via consult-omni."
  (interactive)
  (consult-omni-multi nil "RTFM: " '("man" "Dictionary" "Notes Search" "Wikipedia") nil))

(use-package consult-omni
  :straight (consult-omni :type git :host github :repo "armindarvish/consult-omni" :branch "main" :files (:defaults "sources/*.el"))
  :bind
  (:map +search
    ("S" . consult-omni)
    ("W" . +search-web)
    ("F" . +system-files)
    ("R" . +rtfm))

  :custom
  (consult-omni-default-browse-function #'eww-browse-url)
  (consult-omni-default-preview-function #'eww-browse-url)
  (consult-omni-alternate-browse-function #'browse-url)
  :config
  (require 'consult-omni-sources)
  (require 'consult-omni-embark)
  (setq consult-omni-sources-modules-to-load
    '(consult-omni-man
       consult-omni-wikipedia
       consult-omni-duckduckgo
       consult-omni-dict
       consult-omni-locate
       consult-omni-fd
       consult-omni-ripgrep
       consult-omni-org-agenda
       consult-omni-notes
       consult-omni-calc))
  (consult-omni-sources-load-modules)
  (setq consult-omni-multi-sources '("man"
                                      "Wikipedia"
                                      "DuckDuckGo API"
                                      "Dictionary"
                                      "Notes Search"
                                      "Org Agenda")))


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

  :bind
  (:map +search
    ("x" . p-search))
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
    (when-let ((selection (consult--read
                            bookmark-names
                            :prompt "Select bookmark: "
                            :sort nil)))
      (let ((url (cdr (assoc selection  my/quicklinks))))
        (when url
          (browse-url url))))))

(define-key +search "q" '+quicklink)

(provide 'core-search)
;;; core-search.el ends here
