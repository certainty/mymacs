;;; my-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Completion
;; Fido-vertical-mode, Orderless, and Marginalia provide the minibuffer completion UI,
;; matching style, and annotations.  In-buffer completion remains built in.

;;;; Minibuffer
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

;; Minibuffer completion with Icomplete.
(use-package minibuffer
  :custom
  (completion-sort 'historical)
  (completion-eager-update t)
  (completion-eager-display nil)
  (completion-auto-select t)
  (completion-auto-help nil)
  (completions-max-height 8)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completions-format 'vertical)
  :init
  (fido-vertical-mode))

(use-package icomplete
  :bind
  (:map icomplete-fido-mode-map
        ("M-i" . icomplete-fido-exit))
  :custom
  (icomplete-vertical-mode t))

;;;; In-buffer completion with completion preview mode. I like this alot better than popups
(use-package completion-preview
  :hook ((prog-mode . completion-preview-mode)
         (markdown-ts-mode . completion-preview-mode))
  :bind
  (:map completion-preview-active-mode-map
        ("M-n" . completion-preview-next-candidate)
        ("M-p" . completion-preview-prev-candidate)
        ("M-y" . completion-preview-insert)
        ("C-y" . completion-preview-insert))
  :custom
  (completion-preview-message-format nil)
  (completion-preview-minimum-symbol-length nil)
  (completion-preview-idle-delay nil)
  :init
  (setq-default abbrev-mode t))

(use-package cape
  :ensure t
  :hook
  (prog-mode . my/cape-prog-completion)
  (emacs-lisp-mode . my/cape-elisp-completion)
  (text-mode . my/cape-text-completion)
  :preface
  (defun my/cape-super-set-local (capfs &optional individual-capfs)
    "Combine current CAPFs with CAPFS, then append INDIVIDUAL-CAPFS."
    (let* ((all-for-super (append completion-at-point-functions capfs))
           (all-minus-global (seq-uniq (delq t all-for-super)))
           (cape-super (apply #'cape-capf-super all-minus-global)))
      (setq-local completion-at-point-functions
                  (append (list cape-super) individual-capfs (list t)))))

  (defun my/cape-prog-completion ()
    "Combine programming-mode CAPFs with dabbrev candidates."
    (unless (derived-mode-p 'emacs-lisp-mode)
      (my/cape-super-set-local '(cape-dabbrev) '(cape-file))))

  (defun my/cape-text-completion ()
    (my/cape-super-set-local '(cape-dict cape-dabbrev) '(cape-file)))

  (defun my/cape-elisp-completion ()
    (my/cape-super-set-local
     '(cape-elisp-block cape-elisp-symbol cape-dabbrev)
     '(cape-file)))
  :init
  (setq-default completion-at-point-functions
                (seq-uniq (append (default-value 'completion-at-point-functions)
                                  (list #'cape-file #'cape-dabbrev)))))

(provide 'my-completion)
;;; my-completion.el ends here
