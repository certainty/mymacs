;;; ai-aci.el --- AI Code Interface integration -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; AI Code Interface provides the unified AI coding workflow.
;;
;;; Code:

(defun my/ai-aci-configure-backend ()
  "Apply the configured AI Code backend."
  (when (fboundp 'ai-code-set-backend)
    (ai-code-set-backend my/ai-aci-backend)))

(defun my/ai-aci-setup-magit ()
  "Enable optional AI Code integration with Magit."
  (when (and my/ai-aci-enable-magit-integration
             (fboundp 'ai-code-magit-setup-transients))
    (ai-code-magit-setup-transients)))

(when (or my/enable-ai my/ai-enable-aci)
  (use-package ai-code
    :straight (:type git :host github :repo "tninja/ai-code-interface.el")
    :commands (ai-code-menu
               ai-code-magit-setup-transients
               ai-code-set-backend
               ai-code-select-backend
               ai-code-install-backend-skills)
    :config
    (my/ai-aci-configure-backend)
    (with-eval-after-load 'magit
      (my/ai-aci-setup-magit))))

(provide 'ai-aci)
;;; ai-aci.el ends here
