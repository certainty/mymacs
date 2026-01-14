;;; core-search.el --- Find things -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;;;; Consult - Enhanced commands
(use-package consult
  :general
  (leader-def
    "fr" 'consult-recent-file
    "gg" 'consult-goto-line
    "s!" 'consult-flymake
    "sC" 'consult-compile-error
    "sb" 'consult-buffer
    "sB" 'consult-buffer-other-window
    "sr" 'consult-bookmark
    "sm" 'consult-mark
    "sM" 'consult-global-mark
    "sl" 'consult-line
    "sL" 'consult-line-multi
    "sR" 'consult-ripgrep
    "si" 'consult-imenu
    "sI" 'consult-imenu-multi
    "sO" 'consult-outline)
  :custom
  (consult-narrow-key "<")
  (consult-project-function (lambda (_) (project-root (project-current))))

  :config
  (consult-customize
    consult-theme :preview-key '(:debounce 0.2 any)
    consult-ripgrep consult-git-grep consult-grep
    consult-bookmark consult-recent-file consult-xref
    consult--source-bookmark consult--source-file-register
    consult--source-recent-file consult--source-project-recent-file
    :preview-key '(:debounce 0.4 any)))

(defun my/consult-omni ()
  "Run consult-omni."
  (interactive)
  (call-interactively #'consult-omni))

(defun my/consult-omni-web ()
  "Search the web (engines/wiki) via consult-omni."
  (interactive)
  (consult-omni-multi nil "Web: " '("DuckDuckGo API" "Wikipedia") nil nil :group 'domain))

(defun my/consult-omni-local ()
  "Search local files and content via consult-omni."
  (interactive)
  (consult-omni-multi nil "Local: " '("fd" "locate" "ripgrep") nil))

(defun my/consult-omni-rtfm ()
  "Search reference material (man, notes, dictionaries, etc.) via consult-omni."
  (interactive)
  (consult-omni-multi nil "RTFM: " '("man" "Dictionary" "Notes Search" "Wikipedia") nil))

(use-package consult-omni
  :straight (consult-omni :type git :host github :repo "armindarvish/consult-omni" :branch "main" :files (:defaults "sources/*.el"))
  :general
  (leader-def
    "ss" 'my/consult-omni)
  (leader-def
    "sw" 'my/consult-omni-web
    "sf" 'my/consult-omni-local
    "sr" 'my/consult-omni-rtfm)

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
       consult-omni-elfeed
       consult-omni-notes
       consult-omni-calc))
  (consult-omni-sources-load-modules)
  (setq consult-omni-multi-sources '("man"
                                      "Wikipedia"
                                      "DuckDuckGo API"
                                      "Dictionary"
                                      "elfeed"
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


(provide 'core-search)
;;; core-search.el ends here
