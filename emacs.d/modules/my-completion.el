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

;; Previous built-in minibuffer and Icomplete configuration, kept for reference.
(use-package minibuffer
  :custom
  (completion-sort 'historical)
  (completion-eager-update t)
  (completion-eager-display 'auto)
  (completion-auto-select t)
  (completions-auto-help 'visible)
  (completions-max-height 20)
  (completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (completions-format 'vertical)
  :init
  (fido-vertical-mode))

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
  (emacs-lisp-mode . my/cape-elisp-completion)
  (text-mode . my/cape-text-completion)
  :preface
  (defun my/cape-set-local-capfs (&rest capfs)
    (let ((locals (when (local-variable-p 'completion-at-point-functions)
                    (seq-remove (lambda (capf)
                                  (or (eq capf t)
                                      (memq capf capfs)))
                                completion-at-point-functions))))
      (setq-local completion-at-point-functions
                  (append capfs locals (list t)))))

  (defun my/cape-text-completion ()
    (my/cape-set-local-capfs #'cape-dict))

  (defun my/cape-elisp-completion ()
    (my/cape-set-local-capfs
     (cape-wrap-nonexclusive
      (cape-capf-super #'cape-elisp-block #'cape-elisp-symbol))))
  :init
  (setq-default completion-at-point-functions
                (seq-uniq (append (default-value 'completion-at-point-functions)
                                  (list #'cape-file #'cape-dabbrev)))))

(provide 'my-completion)
;;; my-completion.el ends here
