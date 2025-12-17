;;; core-features.el --- Setup basic features -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;
;;
;;; Code:

;;; Context
(defvar my/context nil
  "Current context: 'work or 'private.
Set explicitly via environment variable MY_EMACS_CONTEXT or detected automatically.")

(defun my/detect-context ()
  "Detect whether we're in work or private environment.
Checks MYEMACS_CONTEXT environment variable first, then falls back to OS detection."
  (or my/context
      (let ((env-context (getenv "MYMACS_CONTEXT")))
        (cond
         ;; Explicit environment variable
         (env-context
          (intern (downcase env-context)))
         ((eq system-type 'darwin) 'work)
         ((eq system-type 'gnu/linux) 'private)
         (t 'private)))))

(setq my/context (my/detect-context))

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "MYMACS loaded in %s context" my/context)))


(my/feature-setq (if (eq my/context 'work) 'context/work 'context/private))
(my/feature-setq 'screen/wide)

(provide 'core-features)
;;; core-features.el ends here
