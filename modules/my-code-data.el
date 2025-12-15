;;; my-code-data.el --- Data -*- lexical-binding: t; -*-

(use-package yaml)

(use-package yaml-mode
  :ensure nil
  :mode ("\\.ya?ml\\'" . yaml-ts-mode)
  :hook
  ((yaml-mode  . eglot-ensure)
   (yaml-ts-mode . eglot-ensure)))

(use-package json-mode
  :mode ("\\.json\\'" . json-ts-mode)
  :hook
  ((json-mode . eglot-ensure)
   (json-ts-mode . eglot-ensure)))

(use-package csv-mode
  :hook (csv-mode . csv-guess-set-separator)
  :mode "\\.csv\\'")

(provide 'my-code-data)
