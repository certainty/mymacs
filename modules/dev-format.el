;;; dev-format.el --- This is harder than it should be -*- lexical-binding: t; -*-

;;; Format and Format on Save

;; we use reformatter to easily define "external" formatters
;;
;; Here is an example on how I use it in my language modes
;;
;; rust.el
;;
;; (reformatter-define rustfmt
;;   :program "rustfmt")
;;
;; (add-hook 'rust-mode-hook
;;           (lambda ()
;;             (setq-local my/external-formatter #'rustfmt-buffer
;;                         my/format-policy 'external)))

(use-package reformatter)

(defvar-local my/format-policy 'dwim
  "Formatting policy for the current buffer.

Possible values:
- 'eglot    → always use Eglot (error if unavailable)
- 'external → always use external formatter
- 'dwim     → use Eglot if possible, otherwise external")

(defvar-local my/external-formatter nil
  "Function that formats the current buffer using an external formatter.")

(defvar-local my/format-on-save-enabled t
  "Non-nil if `my/format-buffer` should be called automatically before saving this buffer.")

(defun my/format-buffer-with-indent-region ()
  "Format the entire buffer with `indent-region`, preserving point and narrowing."
  (save-excursion
    (save-restriction
      (widen)
      (indent-region (point-min) (point-max)))))

(defun my/eglot-can-format-p ()
  "Return non-nil if the current buffer can be formatted by Eglot."
  (when (and (fboundp 'eglot-managed-p) (eglot-managed-p))
    (cl-some
      (lambda (server)
        (eglot--server-capable server :documentFormattingProvider))
      (eglot-current-server))))

(defun my/format-with-eglot ()
  "Format buffer using Eglot. Return t if formatting was requested."
  (interactive)
  (when (my/eglot-can-format-p)
    (eglot-format-buffer)
    t))

(defun my/format-with-external ()
  "Format buffer using the external formatter."
  (interactive)
  (when (and my/external-formatter (functionp my/external-formatter))
    (funcall my/external-formatter)
    t))

(defun my/format-buffer ()
  "Format the current buffer according to `my/format-policy`."
  (interactive)
  (pcase my/format-policy
    ('eglot
      (unless (my/format-with-eglot)
        (user-error "Eglot formatting not available")))
    ('external
      (unless (my/format-with-external)
        (user-error "No external formatter configured")))
    ('dwim
      (or
        (my/format-with-external)
        (my/format-with-eglot)
        (my/format-buffer-with-indent-region)))
    (_ (user-error "Unknown format policy: %s" my/format-policy))))

(defun my/format-on-save ()
  "Format on save if it's enabled."
  (interactive)
  (and my/format-on-save-enabled (my/format-buffer)))

(defun my/format-debug ()
  "Show debug information for the current format settings."
  (interactive)
  (message "policy=%s eglot=%s on-save=%s"
    my/format-policy
    (my/eglot-can-format-p)
    my/format-on-save-enabled))

(defun my/toggle-format-on-save ()
  "Toggle automatic formatting on save for the current buffer."
  (interactive)
  (setq-local my/format-on-save-enabled (not my/format-on-save-enabled))
  (message "format on save is %s" (if my/format-on-save-enabled "enabled" "disabled")))

(add-hook 'before-save-hook #'my/format-on-save nil)

(with-eval-after-load 'general
  (leader-def
    "tF" 'my/toggle-format-on-save))

(provide 'dev-format)
