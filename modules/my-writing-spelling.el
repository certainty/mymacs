;;; my-writing-spelling.el --- spelling -*- lexical-binding: t; -*-
(use-package emacs
  :ensure nil
  :demand t
  :custom
  (dictionary-server "dict.org"))

(use-package flyspell
  :ensure nil
  :hook
  (text-mode . flyspell-mode)
  (git-commit-mode . flyspell-mode)

  :general
  (my-writing-keymap
   ("u" . my/toggle-umlauts)
   ("sg" . my/dict-german)
   ("se" . my/dict-english))

  :config
  (unbind-key "C-," flyspell-mode-map)
  (unbind-key "C-." flyspell-mode-map)

  (defun my/toggle-umlauts()
    "Toggle being able to write umlauts with the Mac option modifier"
    (interactive)
    (if mac-option-modifier
      (setq mac-option-modifier nil)
      (setq mac-option-modifier 'meta)))

  (defun my/dict-german ()
    "Change the dictionary to german"
    (interactive)
    (ispell-change-dictionary "de_DE"))

  (defun my/dict-english ()
    "Change the dictionary to english"
    (interactive)
    (ispell-change-dictionary "en_US")))

(provide 'my-writing-spelling)
