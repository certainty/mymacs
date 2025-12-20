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

(defun my/format-buffer-with-indent-region ()
  "Format the entire buffer with `indent-region`, preserving point and narrowing."
  (save-excursion
    (save-restriction
      (widen)
      (indent-region (point-min) (point-max)))))

(defvar-local my/external-formatter #'my/format-buffer-with-indent-region
  "Function that formats the current buffer using an external formatter.")

(cl-defmacro my/define-mode-formatter (&key hook (policy 'dwim) (external))
  "Define a buffer-local formatter for a mode.
Keyword arguments:
- :hook     (required) the major-mode hook to attach to
- :policy   (required) one of 'eglot, 'external, or 'dwim
- :external (optional) a function to format the buffer for external formatting"
  `(add-hook ,hook
     (lambda ()
       ,@(when policy
           `((setq-local my/format-policy ,policy)))
       ,@(when external
           `((setq-local my/external-formatter ,external))))))

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
    (message "running with external formatter")
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
      (or (my/format-with-eglot)
        (my/format-with-external)))
    (_
      (user-error "Unknown format policy: %s" my/format-policy))))

(defun my/format-debug ()
  "Show debug information for the current format settings."
  (interactive)
  (message "policy=%s eglot=%s"
    my/format-policy
    (my/eglot-can-format-p)))

(defvar-local my/format-on-save-enabled nil
  "Non-nil if `my/format-buffer` should be called automatically before saving this buffer.")

(defun my/enable-format-on-save ()
  "Enables format on save."
  (interactive)
  (add-hook 'before-save-hook #'my/format-buffer nil t)
  (setq my/format-on-save-enabled t))

(defun my/disable-format-on-save ()
  "Disables format on save."
  (remove-hook 'before-save-hook #'my/format-buffer t)
  (setq my/format-on-save-enabled nil))

(defun my/toggle-format-on-save ()
  "Toggle automatic formatting on save for the current buffer."
  (interactive)
  (if my/format-on-save-enabled
    (my/disable-format-on-save)
    (my/enable-format-on-save)))

(provide 'dev-format)
