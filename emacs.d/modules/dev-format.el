;;; dev-format.el --- Format and Format on Save -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Formatter configuration. Uses `reformatter' to define external formatters
;; and falls back to Eglot or `indent-region' based on `my/format-policy'.
;;
;;; Code:

(use-package reformatter
  :ensure t)

(defvar-local my/format-policy 'dwim
  "Formatting policy for the current buffer.

Possible values:
- \='eglot    → always use Eglot (error if unavailable)
- \='external → always use external formatter
- \='dwim     → use Eglot if possible, otherwise external")

(defvar-local my/external-formatter nil
  "Function that formats the current buffer using an external formatter.")

(defvar-local my/format-on-save-enabled t
  "Non-nil if `+format-buffer' should be called automatically before saving.")

(defun my/format-buffer-with-indent-region ()
  "Format the entire buffer with `indent-region`, preserving point and narrowing."
  (save-excursion
    (save-restriction
      (widen)
      (indent-region (point-min) (point-max)))))

(defun my/eglot-can-format-p ()
  "Return non-nil if the current buffer can be formatted by Eglot."
  (when (and (fboundp 'eglot-managed-p) (eglot-managed-p))
    (eglot-server-capable :documentFormattingProvider)))

(defun +format-with-eglot ()
  "Format buffer using Eglot. Return t if formatting was requested."
  (interactive)
  (when (my/eglot-can-format-p)
    (eglot-format-buffer)
    t))

(defun +format-with-external ()
  "Format buffer using the external formatter."
  (interactive)
  (when (and my/external-formatter (functionp my/external-formatter))
    (funcall my/external-formatter)
    t))

(defun +format-buffer ()
  "Format the current buffer according to `my/format-policy`."
  (interactive)
  (pcase my/format-policy
    ('eglot
     (unless (+format-with-eglot)
       (user-error "Eglot formatting not available")))
    ('external
     (unless (+format-with-external)
       (user-error "No external formatter configured")))
    ('dwim
     (or
      (+format-with-eglot)
      (+format-with-external)
      (my/format-buffer-with-indent-region)))
    (_ (user-error "Unknown format policy: %s" my/format-policy))))

(defun +format-on-save ()
  "Format on save if it's enabled."
  (interactive)
  (and my/format-on-save-enabled
       (+format-buffer)))

(defun +format-debug ()
  "Show debug information for the current format settings."
  (interactive)
  (message "policy=%s eglot=%s on-save=%s"
           my/format-policy
           (my/eglot-can-format-p)
           my/format-on-save-enabled))

(defun +toggle-format-on-save ()
  "Toggle automatic formatting on save for the current buffer."
  (interactive)
  (setq-local my/format-on-save-enabled (not my/format-on-save-enabled))
  (message "format on save is %s" (if my/format-on-save-enabled "enabled" "disabled")))

(defun +disable-format-on-save ()
  "Disable format on-save for the current buffer."
  (interactive)
  (setq-local my/format-on-save-enabled nil))

(defun +enable-format-on-save ()
  "Enable format on-save for the current buffer."
  (interactive)
  (setq-local my/format-on-save-enabled t))

(add-hook 'before-save-hook #'+format-on-save nil)

(provide 'dev-format)
;;; dev-format.el ends here
