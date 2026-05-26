;;; my-modeline.el --- Minimal custom mode line -*- lexical-binding: t; -*-

;;; Commentary:

;; A small mode line inspired by Protesilaos Stavrou's custom modeline.
;; It stays close to the default while providing a compact Flymake segment.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'flymake)

(defgroup my/modeline nil
  "Minimal custom mode line."
  :group 'mode-line)

(defface my/modeline-indicator-gray
  '((t :inherit shadow))
  "Subtle face for modeline indicators."
  :group 'my/modeline)

(defface my/modeline-accent
  '((t :inherit mode-line-emphasis))
  "Accent face for prominent modeline indicators."
  :group 'my/modeline)

(defun my/modeline--buffer-name ()
  "Return the current buffer name for the mode line."
  (format-mode-line "%b"))

(defun my/modeline--buffer-identification-face ()
  "Return the appropriate face for the current buffer name."
  (let ((file (buffer-file-name)))
    (cond
     ((and (mode-line-window-selected-p) file (buffer-modified-p))
      '(italic mode-line-buffer-id))
     ((and file (buffer-modified-p))
      'italic)
     ((mode-line-window-selected-p)
      'mode-line-buffer-id)
     (t
      'mode-line-inactive))))

(defun my/modeline--major-mode ()
  "Return the current major mode name."
  (format-mode-line mode-name))

(defun my/modeline--flymake-show-zero-counter-p (type)
  "Return non-nil when TYPE should display a zero-valued counter."
  (cond
   ((eq flymake-suppress-zero-counters t)
    nil)
   (flymake-suppress-zero-counters
    (>= (flymake--severity type)
        (warning-numeric-level flymake-suppress-zero-counters)))
   (t
    t)))

(defun my/modeline--selected-window (construct)
  "Return formatted CONSTRUCT only in the selected window."
  (when (mode-line-window-selected-p)
    (format-mode-line construct)))

(defun my/modeline--vc ()
  "Return VC information without the backend prefix."
  (when-let* ((vc (format-mode-line '(vc-mode vc-mode))))
    (when (not (string-empty-p vc))
      (string-trim-left vc "[^-]+[:-]"))))

(defun my/modeline--flymake-count (type)
  "Return the number of diagnostics matching TYPE severity."
  (let ((count 0)
        (severity (flymake--severity type)))
    (dolist (diag (flymake-diagnostics) count)
      (when (= severity (flymake--severity (flymake-diagnostic-type diag)))
        (setq count (1+ count))))))

(defun my/modeline--flymake-token (type label)
  "Return a Flymake token for TYPE prefixed with LABEL."
  (let ((count (my/modeline--flymake-count type)))
    (when (or (> count 0)
              (my/modeline--flymake-show-zero-counter-p type))
      (propertize
       (format "%s%d" label count)
       'face (flymake--lookup-type-property type 'mode-line-face 'mode-line)))))

(defun my/modeline--flymake ()
  "Return a compact Flymake segment."
  (when (bound-and-true-p flymake-mode)
    (let ((exception (string-trim (format-mode-line flymake-mode-line-exception))))
      (cond
       ((not (string-empty-p exception))
        exception)
       ((not (flymake-running-backends))
        nil)
       (t
        (let ((errors (my/modeline--flymake-count :error))
              (warnings (my/modeline--flymake-count :warning))
              (infos (my/modeline--flymake-count :note)))
          (if (and (zerop errors) (zerop warnings) (zerop infos))
              (propertize "OK" 'face 'success)
            (string-join
             (delq nil
                   (list
                    (my/modeline--flymake-token :error "Ⓔ")
                    (my/modeline--flymake-token :warning "Ⓦ")
                    (my/modeline--flymake-token :note "Ⓘ")))
             " "))))))))

(defvar-local my/modeline-buffer-identification
  '(:eval
    (propertize
     (my/modeline--buffer-name)
     'face (my/modeline--buffer-identification-face)))
  "Mode line construct for the current buffer name.")

(defvar-local my/modeline-major-mode
  (list
   (propertize "%[" 'face 'my/modeline-indicator-gray)
   '(:eval
     (propertize
      (my/modeline--major-mode)
      'face (if (mode-line-window-selected-p)
                'bold
              'mode-line-inactive)))
   (propertize "%]" 'face 'my/modeline-indicator-gray))
  "Mode line construct for the current major mode.")

(defvar-local my/modeline-vc
  '(:eval
    (when (mode-line-window-selected-p)
      (when-let* ((vc (my/modeline--vc)))
        (propertize vc 'face 'my/modeline-accent))))
  "Mode line construct for VC branch information.")

(defvar-local my/modeline-flymake
  '(:eval
    (when (mode-line-window-selected-p)
      (my/modeline--flymake)))
  "Mode line construct for Flymake diagnostics.")

(defvar-local my/modeline-process
  '(:eval (my/modeline--selected-window mode-line-process))
  "Mode line construct for process information.")

(defvar-local my/modeline-misc-info
  '(:eval (my/modeline--selected-window mode-line-misc-info))
  "Mode line construct for miscellaneous information.")

(put 'my/modeline-buffer-identification 'risky-local-variable t)
(put 'my/modeline-major-mode 'risky-local-variable t)
(put 'my/modeline-vc 'risky-local-variable t)
(put 'my/modeline-flymake 'risky-local-variable t)
(put 'my/modeline-process 'risky-local-variable t)
(put 'my/modeline-misc-info 'risky-local-variable t)

(defvar my/modeline--saved-format nil
  "Saved default mode line format before `my/modeline-mode' is enabled.")

(defvar my/modeline-format
  '("%e"
    mode-line-front-space
    mode-line-modified
    mode-line-remote
    " "
    my/modeline-buffer-identification
    "  "
    my/modeline-major-mode
    my/modeline-process
    "  "
    my/modeline-vc
    "  "
    my/modeline-flymake
    "  "
    mode-line-format-right-align
    my/modeline-misc-info
    mode-line-end-spaces)
  "Default mode line format used by `my/modeline-mode'.")

;;;###autoload
(define-minor-mode my/modeline-mode
  "Use a minimal custom mode line."
  :global t
  (if my/modeline-mode
      (progn
        (unless my/modeline--saved-format
          (setq my/modeline--saved-format (default-value 'mode-line-format)))
        (setq-default mode-line-format my/modeline-format))
    (kill-local-variable 'mode-line-format)
    (when my/modeline--saved-format
      (setq-default mode-line-format my/modeline--saved-format)))
  (force-mode-line-update t))

(provide 'my-modeline)

;;; my-modeline.el ends here
