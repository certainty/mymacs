;;; my-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Completion
;; I have previously used vertico, marginalia, orderless and corfu as the completion stack
;; but I found that the builtin icomplete can be configured to come very close.
;; For in-buffer completion I actually prefer icomplete-preview over corfu.

;;;; minibuffer
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
  (completion-styles '(substring partial-completion flex basic)))

(use-package icomplete
  :bind
  (:map icomplete-minibuffer-map
        ("C-n" . icomplete-forward-completions)
        ("C-p" . icomplete-backward-completions)
        ("C-y" . icomplete-force-complete-and-exit)
        ("C-<return>" . icomplete-force-complete))
  :custom
  (icomplete-delay-completions-threshold 0)
  (icomplete-in-buffer t)
  (icomplete-max-delay-chars 0)
  (icomplete-scroll t)
  (icomplete-prospects-height 10)
  (icomplete-show-matches-on-no-input t)
  :init
  (icomplete-vertical-mode))

;;;; In-buffer
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
