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
  :mode ("\\.ya?ml\\'"))

;;; TOML
(use-package toml-ts-mode
  :mode ("\\.toml\\'"))

;;; CSV
(use-package csv-mode
  :ensure t
  :mode ("\\.csv\\'" "\\.tsv\\'")
  :custom
  (csv-separators '("," ";" "\t"))
  (csv-align-padding 2))

;;; Go templates
(use-package go-ts-mode
  :mode ("\\.gotmpl\\'" . go-ts-mode))

(provide 'dev-data)
;;; dev-data.el ends here
