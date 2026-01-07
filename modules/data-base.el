;;; data-base.el --- Data format configuration -*- lexical-binding: t -*-

;;; Commentary:
;; TOML, CSV, and JSON modes with tree-sitter where available

;;; Code:

;;;; TOML Mode
(use-package toml-ts-mode
  :straight (:type built-in)
  :mode (("\\.toml\\'" . toml-ts-mode)
          ("\\.toml\\.example\\'" . toml-ts-mode)
          ("Cargo\\.lock\\'" . toml-ts-mode)
          ("\\.mise\\.toml\\'" . toml-ts-mode))
  :hook (toml-ts-mode . display-line-numbers-mode))

;;;; CSV Mode
(use-package csv-mode
  :mode (("\\.csv\\'" . csv-mode)
          ("\\.tsv\\'" . csv-mode))
  :general
  (local-leader-def
    :keymaps 'csv-mode-map
    "a" 'csv-align-fields
    "u" 'csv-unalign-fields
    "s" 'csv-sort-fields
    "S" 'csv-sort-numeric-fields
    "r" 'csv-reverse-region
    "k" 'csv-kill-fields
    "t" 'csv-transpose)
  :custom
  (csv-separators '("," ";" "|" "\t"))
  (csv-align-padding 1)
  :config
  ;; Enable header line for column names
  (setq csv-header-lines 1))

;;;; JSON Mode (already configured in my-web.el, but add enhancements)
(with-eval-after-load 'json-ts-mode
  (defun my/json-pretty-print-buffer ()
    "Pretty print the current JSON buffer."
    (interactive)
    (save-excursion
      (mark-whole-buffer)
      (json-pretty-print (point-min) (point-max))))

  (defun my/json-mode-setup ()
    "Setup for JSON buffers."
    (setq-local js-indent-level 2)
    (eglot-ensure))

  (add-hook 'json-ts-mode-hook #'my/json-mode-setup)

  (local-leader-def
    :keymaps 'json-ts-mode-map
    "=" 'my/json-pretty-print-buffer))

;;;; YAML enhancements (already configured in my-ruby.el)
(with-eval-after-load 'yaml-ts-mode
  (defun my/yaml-mode-setup ()
    "Setup for YAML buffers."
    (setq-local yaml-indent-offset 2)
    (eglot-ensure))

  (add-hook 'yaml-ts-mode-hook #'my/yaml-mode-setup))

(provide 'data-base)
;;; data-base.el ends here
