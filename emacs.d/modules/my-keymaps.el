;;; my-keymaps.el --- Leader keymaps and global minor mode -*- lexical-binding: t; -*-

;;; Customization
(defvar-keymap my/leader-map :doc "Shared leader keymap.")
(defvar-keymap my/notes-prefix-map :doc "Org notes leader submap.")
(defvar-keymap my/pmd-prefix-map :doc "PMD leader submap.")

(defvar-keymap my/open-prefix-map :doc "Open resources leader submap.")
(defvar-keymap my/project-prefix-map :doc "Project leader submap.")

(defvar-keymap my/task-prefix-map
  :doc "Task management leader submap.")

(defvar-keymap my/window-prefix-map
  :doc "Helix-style window keymap."
  "w" #'other-window
  "v" #'split-window-right
  "s" #'split-window-below
  "t" #'window-layout-transpose
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right
  "a" #'my/ace-select-any-window
  "q" #'delete-window
  "o" #'+delete-other-windows
  "H" #'windmove-swap-states-left
  "J" #'windmove-swap-states-down
  "K" #'windmove-swap-states-up
  "L" #'windmove-swap-states-right)

(keymap-set my/leader-map "j" my/notes-prefix-map)
(keymap-set my/leader-map "X" #'my/notes-capture)
(keymap-set my/leader-map "," my/pmd-prefix-map)

(keymap-set my/leader-map "o" my/open-prefix-map)
(keymap-set my/leader-map "p" my/project-prefix-map)

(keymap-set my/leader-map "t" my/task-prefix-map)
(keymap-set my/leader-map "w" my/window-prefix-map)

(defvar-keymap mymacs-mode-map
  :doc "mymacs global keys"
  "C-j" my/leader-map)

(keymap-set mymacs-mode-map "C-<" #'previous-buffer)
(keymap-set mymacs-mode-map "C->" #'next-buffer)

(defvar mymacs-emulation-mode-map-alist
  `((mymacs-mode . ,mymacs-mode-map))
  "Keymap alist giving `mymacs-mode-map' precedence.")

(define-minor-mode mymacs-mode
  "My personal minor mode"
  :init-value t
  :global t
  :group 'mymacs
  :lighter " MyM"
  :keymap mymacs-mode-map)

(add-to-list 'emulation-mode-map-alists 'mymacs-emulation-mode-map-alist)
(mymacs-mode 1) ;; enable immediately

(provide 'my-keymaps)
;;; my-keymaps.el ends here
