;;; writing-base.el --- Spell-check and style aids -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Writing tools: jinx for spell-checking (enchant backend).
;; Jinx is preferred over flyspell (faster, fewer false positives).
;;
;;; Code:

;;; Jinx (spell-checking via enchant)
(use-package jinx
  :ensure t
  :hook ((text-mode org-mode) . jinx-mode)
  :bind
  (:map jinx-mode-map
        ("C-," . jinx-correct))
  :custom
  (jinx-delay 0.2)
  :config
  (diminish 'jinx-mode))

(provide 'writing-base)
;;; writing-base.el ends here
