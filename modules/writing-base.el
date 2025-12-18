;;; writing-base.el --- Writing aids: spell check, grammar, style -*- lexical-binding: t -*-

;;; Commentary:
;; Tools for better writing: spell checking, weak words detection, style improvements

;;; Code:

;;;; Spell Checking with Jinx
(use-package jinx
  :defer t
  :hook ((text-mode org-mode markdown-mode) . jinx-mode)
  :general
  (local-leader-def
    :keymaps 'jinx-mode-map
    "!s" 'jinx-correct
    "!S" 'jinx-languages)
  :custom
  (jinx-delay 0.2)
  :config
  (diminish 'jinx-mode))

;;;; Alternative: Flyspell (fallback if jinx not available)
(use-package flyspell
  :straight (:type built-in)
  :hook ((text-mode org-mode markdown-mode) . flyspell-mode)
  :general
  (local-leader-def
    :keymaps 'flyspell-mode-map
    "!c" 'flyspell-correct-word-before-point
    "!b" 'flyspell-buffer)
  :custom
  (flyspell-issue-message-flag nil)
  (flyspell-issue-welcome-flag nil)
  :config
  (diminish 'flyspell-mode))

;;;; Ispell configuration
(use-package ispell
  :straight (:type built-in)
  :custom
  (ispell-program-name (or (executable-find "aspell")
                         (executable-find "hunspell")
                         (executable-find "ispell")))
  (ispell-dictionary "en_US")
  :config
  ;; Use aspell if available (faster and better)
  (when (executable-find "aspell")
    (setq ispell-extra-args '("--sug-mode=ultra" "--lang=en_US"))))

;;;; Writegood Mode - Detect weak words and passive voice
(use-package writegood-mode
  :hook ((text-mode org-mode markdown-mode) . writegood-mode)
  :general
  (local-leader-def
    :keymaps 'write-good-mode
    "wg" 'writegood-grade-level
    "wr" 'writegood-reading-ease)
  :custom
  (writegood-weasel-words
    '("many" "various" "very" "fairly" "several" "extremely"
       "exceedingly" "quite" "remarkably" "few" "surprisingly"
       "mostly" "largely" "huge" "tiny" "excellent" "interestingly"
       "significantly" "substantially" "clearly" "vast" "relatively"
       "completely"))
  :config
  (diminish 'writegood-mode))


;;;; Olivetti - Distraction-free writing
(use-package olivetti
  :commands olivetti-mode
  :general
  (local-leader-def
    :keymaps 'olivetti-mode
    "ow" 'olivetti-set-width)
  :custom
  (olivetti-body-width 100)
  (olivetti-minimum-body-width 80)
  :config
  (diminish 'olivetti-mode))

;;;; Helper: Enable all writing tools
(defun my/writing-mode ()
  "Enable all writing assistance tools."
  (interactive)
  (if (featurep 'jinx)
    (jinx-mode 1)
    (flyspell-mode 1))
  (writegood-mode 1)
  (wc-mode 1)
  (visual-line-mode 1)
  (message "Writing mode enabled"))

(defun my/prose-mode ()
  "Enable distraction-free prose writing."
  (interactive)
  (my-writing-mode)
  (olivetti-mode 1)
  (message "Prose mode enabled"))

(leader-def
  "Wm" 'my/writing-mode
  "Wp" 'my/prose-mode)


(provide 'writing-base)
;;; writing-base.el ends here
