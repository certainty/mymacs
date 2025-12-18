;;; mymacs.el ---  -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defvar *my/features* nil "An association list of features that I use to conditionally execute code")

(cl-defun my/feature-setq (feature &optional (value t))
  "Add `FEATURE' to the MYMACS features list. This can later be used to run code conditionally.
   You can supply an optional `VALUE' which will be associated with this feature.
   If a `FEATURE' with that name already exists it will be replaced.
"
  (assoc-delete-all 'feature *my/features*)
  (setq *my/features*
    (cons (cons feature value) *my/features*)))

(cl-defun my/featurep (feature &key (value t))
  (equal value (alist-get feature *my/features*)))

(cl-defun my/require (file &key (guard t))
  "Load the file provided via `FILE' conditionally, depending on the value of `GUARD'."
  (when guard
    (message "loading file: %s" file)
    (require file)))

(cl-defun my/display-buffer-right (identifier &optional (size 0.3))
  "Simplified interface to manage where buffers are displayed"
  (add-to-list 'display-buffer-alist
    `(,identifier
       (display-buffer-reuse-window display-buffer-in-side-window)
       (reusable-frames . visible)
       (side . right)
       (window-hight . ,size))))

(provide 'mymacs)
;;; mymacs.el ends here
