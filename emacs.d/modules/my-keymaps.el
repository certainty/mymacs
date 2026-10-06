;;; my-keymaps.el --- Leader keymaps and global minor mode -*- lexical-binding: t; -*-

;;; Customization
(defvar-keymap my/leader-map :doc "Shared leader keymap.")
(defvar-keymap my/notes-prefix-map :doc "Org notes leader submap.")
(defvar-keymap my/pmd-prefix-map :doc "PMD leader submap.")

(defvar-keymap my/open-prefix-map :doc "Open resources leader submap.")
(defvar-keymap my/project-prefix-map :doc "Project leader submap.")
(defvar-keymap my/mise-prefix-map :doc "Mise task leader submap.")

(defvar-keymap my/task-prefix-map
  :doc "Task management leader submap.")

(defvar-keymap my/window-prefix-map
  :doc "Window commands"
  "w" #'ace-window
  "t" #'window-layout-transpose
  "a" #'my/ace-select-any-window
  "q" #'delete-window
  "o" #'+delete-other-windows
  "u" 'winner-undo
  "U" 'winner-redo)

(defvar-keymap mymacs-mode-map
  :doc "mymacs global keys"
  "C-j" my/leader-map)

(keymap-set my/leader-map "j" my/notes-prefix-map)
(keymap-set my/leader-map "X" #'my/notes-capture)
(keymap-set my/leader-map "o" my/open-prefix-map)
(keymap-set my/leader-map "p" my/project-prefix-map)
(keymap-set my/leader-map "m" my/mise-prefix-map)

(keymap-set my/leader-map "t" my/task-prefix-map)
(keymap-set my/leader-map "w" my/window-prefix-map)

;; TODO: this does not belong here
(keymap-set mymacs-mode-map "C-<" #'previous-buffer)
(keymap-set mymacs-mode-map "C->" #'next-buffer)

(keymap-set my/leader-map "," my/pmd-prefix-map)

(provide 'my-keymaps)
;;; my-keymaps.el ends here
