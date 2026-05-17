;;; ai-base.el --- AI compatibility helpers -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Compatibility aliases for the older `agent-shell' key entry points.
;; The actual integrations live in `ai-aci.el' and `ai-eca.el'.
;;
;;; Code:

(defun my/ai-available-p ()
  "Return non-nil when any AI integration is enabled."
  (or my/enable-ai
      my/ai-enable-aci
      my/ai-enable-eca))

(defun my/ai-command ()
  "Dispatch the legacy AI entry point to the enabled integration."
  (interactive)
  (cond
   ((and (or my/enable-ai my/ai-enable-aci) (fboundp 'ai-code-menu))
    (ai-code-menu))
   ((and my/ai-enable-eca (fboundp 'eca))
    (call-interactively #'eca))
   (t
    (user-error "No AI integration is enabled"))))

(defalias 'agent-shell #'my/ai-command)
(defalias 'agent-shell-new-shell #'my/ai-command)
(defalias 'agent-shell-toggle #'my/ai-command)

(provide 'ai-base)
;;; ai-base.el ends here
