;;; writing-base.el --- Spell-check and style aids -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Writing tools: jinx for spell-checking (enchant backend) and
;; writegood-mode for detecting weak words and passive voice.
;; Jinx is preferred over flyspell (faster, fewer false positives).
;;
;;; Code:

;;; Jinx (spell-checking via enchant)
(use-package jinx
  :straight t
  :hook ((text-mode org-mode) . jinx-mode)
  :bind
  (:map jinx-mode-map
        ("C-," . jinx-correct))
  :custom
  (jinx-delay 0.2)
  :config
  (diminish 'jinx-mode))

;;; Writegood - Detect weak words and passive voice
(use-package writegood-mode
  :straight t
  :commands writegood-mode
  :config
  (diminish 'writegood-mode))

(provide 'writing-base)
;;; writing-base.el ends here
