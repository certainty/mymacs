;;; my-sessions.el --- Sessions / Projects -*- lexical-binding: t; -*-

;;; project
(use-package project
  :ensure nil
  :general
  (search-map
   "R" '("Search/Replace" . project-query-replace-regexp))

  :custom
  (project-mode-line t)
  (project-switch-commands '((project-find-file "Find file")
                             (project-find-regexp "Find regexp")
                             (project-find-dir "Find directory")
                             (project-vc-dir "VC-Dir")
                             (project-magit-dir "Magit status")))

  (project-vc-extra-root-markers '(".project" "package.json" "autogen.sh" ".projectile" "go.mod")))

;;; Sessions

(use-package desktop
  :ensure nil
  :commands (desktop-save-mode)
  :custom
  (desktop-base-file-name "emacs.desktop")
  (desktop-base-lock-name "lock")
  (desktop-path (list desktop-dirname))
  (desktop-save 'ask-if-new)
  (desktop-files-not-to-save  (concat "^$" ".*magit$"))
  (desktop-restore-eager 4)
  (desktop-load-locked-desktop t)
  (desktop-buffers-not-to-save
   (concat "\\("
           "^nn\\.a[0-9]+\\|\\.log\\|(ftp)\\|^tags\\|^TAGS"
           "\\|\\.emacs.*\\|\\.diary\\|\\.newsrc-dribble\\|\\.bbdb"
           "\\)$")))

(use-package tab-bar
  :ensure nil
  :general
  (my-project-keymap
   "n" '("Next" . tab-next)
   "o" '("Recent" . tab-recent)
   "S" '("Select" . tab-switch))
  :custom
  (tab-bar-show 1)
  (tab-bar-tab-hints t) ;; show numbers in tabs
  (tab-bar-new-tab-choice "*scratch*")
  (tab-bar-select-tab-modifiers '(super))
  (tab-bar-close-tab-select 'recent)
  (tab-bar-new-tab-to 'rightmost)
  (tab-bar-new-button nil)
  (tab-bar-close-button nil)
  (tab-bar-auto-width nil)
  (tab-bar-format '(tab-bar-format-history
                    tab-bar-format-tabs
                    lem--tab-bar-suffix
                    tab-bar-format-add-tab)))

(use-package tabspaces
  :hook elpaca-after-init
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-initialize-project-with-todo t)
  :general
  (my-project-keymap
   "p" '("Open/Create" . tabspaces-open-or-create-project-and-workspace)
   "s" '("Switch" . tabspaces-switch-buffer-and-tab)
   "w" '("Switch/Create" . tabspaces-switch-or-create-workspace)
   "q" '("Shutdown" . tabspaces-kill-buffer-close-workspace)))

(provide 'my-sessions)
