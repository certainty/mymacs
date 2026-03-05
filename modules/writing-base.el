;;; writing-base.el --- Writing aids: spell check, grammar, style -*- lexical-binding: t -*-

;;; Commentary:
;; Tools for better writing: spell checking, weak words detection, style improvements

;;; Code:

;;;; Spell Checking with Jinx
(use-package jinx
  :defer t
  :hook ((text-mode org-mode markdown-mode) . jinx-mode)
  :bind
  (:map jinx-mode-map
    ("C-," . jinx-correct))
  :custom
  (jinx-delay 0.2)
  :config
  (diminish 'jinx-mode))

;;;; Alternative: Flyspell (fallback if jinx not available)
(use-package flyspell
  :straight (:type built-in)
  :hook ((text-mode org-mode markdown-mode) . flyspell-mode)
  :bind
  (:map flyspell-mode-map
    ("C-c b" . flyspell-buffer))
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
  :custom
  (writegood-weasel-words
    '("many" "various" "very" "fairly" "several" "extremely"
       "exceedingly" "quite" "remarkably" "few" "surprisingly"
       "mostly" "largely" "huge" "tiny" "excellent" "interestingly"
       "significantly" "substantially" "clearly" "vast" "relatively"
       "completely"))
  :config
  (diminish 'writegood-mode))

(provide 'writing-base)
;;; writing-base.el ends here
