;;; dev-data.el --- Data format modes -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Tree-sitter modes for common data formats: JSON, YAML, TOML, CSV,
;; and Go templates.  Formatters are configured via reformatter where
;; an external tool is available (jq for JSON).
;;
;;; Code:

;;; JSON
(use-package json-ts-mode
  :straight (:type built-in)
  :mode ("\\.json\\'" "\\.jsonl\\'")
  :custom
  (json-ts-mode-indent-offset 2)
  :hook (json-ts-mode . (lambda ()
                          (setq-local my/external-formatter #'+json-format-buffer))))

(reformatter-define +json-format
  :program "jq"
  :args '(".")
  :lighter " jq")

;;; YAML
(use-package yaml-ts-mode
  :straight (:type built-in)
  :mode ("\\.ya?ml\\'"))

;;; TOML
(use-package toml-ts-mode
  :straight (:type built-in)
  :mode ("\\.toml\\'"))

;;; CSV
(use-package csv-mode
  :mode ("\\.csv\\'" "\\.tsv\\'")
  :custom
  (csv-separators '("," ";" "\t"))
  (csv-align-padding 2))

;;; Go templates
(use-package go-ts-mode
  :straight (:type built-in)
  :mode ("\\.gotmpl\\'" . go-ts-mode))

(provide 'dev-data)
;;; dev-data.el ends here
