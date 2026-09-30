;;; my-text.el --- Text and documentation modes -*- lexical-binding: t; -*-

(use-package markdown-ts-mode
  :mode
  ("\\.md\\'" . markdown-ts-mode)
  ("\\.markdown\\'" . markdown-ts-mode)
  ("\\.mdown\\'" . markdown-ts-mode)
  ("\\.mkdn\\'" . markdown-ts-mode)
  ("\\.mdwn\\'" . markdown-ts-mode))

(use-package flyspell
  :hook (text-mode . flyspell-mode)
  :commands (flyspell-mode flyspell-prog-mode)
  :custom
  (ispell-program-name "aspell")
  (ispell-dictionary "en_US")
  :config
  (keymap-set flyspell-mode-map "C-," nil))

(use-package eldoc
  :custom
  (eldoc-idle-delay 1000000)
  (eldoc-echo-area-use-multiline-p nil)
  :config
  (defun my/eldoc-display-manually-only (docs interactive)
    (when interactive
      (or (eldoc-display-in-echo-area docs interactive)
          (eldoc-display-in-buffer docs interactive))))
  (setq eldoc-display-functions '(my/eldoc-display-manually-only)))


(provide 'my-text)
;;; my-text.el ends here
