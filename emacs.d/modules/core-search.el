;;; core-search.el --- Find things -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Search and navigation enhancements. Configures Consult for powerful
;; completing-read search commands, Wgrep for editable grep buffers,
;; and EWW for web browsing.
;;
;;; Code:

;;; Consult - Enhanced commands

(defun my/consult-project-root (_)
  "Return the root of the current project for consult."
  (when-let* ((project (project-current)))
    (project-root project)))

(use-package consult
  :defer 2
  :custom
  (consult-narrow-key "C-<")
  (consult-project-function #'my/consult-project-root)

  :config
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

;;; Wgrep - Editable grep buffers
(use-package wgrep
  :commands wgrep-change-to-wgrep-mode
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-change-readonly-file nil)
  :config
  (setq wgrep-enable-key "i"))

;;; EWW - Web browser
(use-package eww
  :straight (:type built-in)
  :bind
  (:map eww-mode-map
        ("C-c C-o" . eww-browse-with-external-browser)))

(provide 'core-search)
;;; core-search.el ends here
