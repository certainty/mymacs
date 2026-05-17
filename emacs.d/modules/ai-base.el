;;; ai-base.el --- AI compatibility helpers -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Shared helpers for AI feature detection.
;;
;;; Code:

(defun my/ai-available-p ()
  "Return non-nil when any AI integration is enabled."
  (or my/enable-ai
      my/ai-enable-aci
      my/ai-enable-eca))

(provide 'ai-base)
;;; ai-base.el ends here
