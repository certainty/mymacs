;;; my-code-checkers.el --- Checkers -*- lexical-binding: t; -*-

(use-package flymake
  :ensure nil
  :general
  (my-diagnostics-keymap
   "!"  '("All" . consult-flymake)
   "n"  '("Next" . flymake-goto-next-error)
   "p"  '("Prev" . flymake-goto-prev-error))
  :hook
  (prog-mode . flymake-mode)
  :custom
  (flymake-error-bitmap '(right-triangle compilation-error))
  (flymake-warning-bitmap '(right-triangle compilation-warning))
  (flymake-note-bitmap '(right-triangle compilation-info))
  (flymake-show-diagnostics-at-end-of-line nil))

(use-package flyspell
  :ensure nil
  :hook
  (prog-mode . flyspell-prog-mode)
  (conf-mode . flyspell-prog-mode)

  :general
  (my-diagnostics-keymap
   "s f" '("Fix word" . flyspell-correct-word)
   "s c" '("Check buffer" . flyspell-buffer)
   "s r" '("Check region" . flyspell-region))

  :config
  (unbind-key "C-," flyspell-mode-map)
  (unbind-key "C-." flyspell-mode-map)
  (unbind-key "C-;" flyspell-mode-map)

  (defun flyspell-correct-word ()
    "Run flyspell correction at point."
    (interactive)
    (if (fboundp 'flyspell-correct-at-point)
      (flyspell-correct-at-point)
      (flyspell-auto-correct-word))))

(provide 'my-code-checkers)
