;;; dev-go.el --- Go development -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Go support via go-ts-mode (built-in) and gopls (eglot).
;; Formatting is handled by goimports via reformatter.
;;
;;; Code:

;;; Go tree-sitter mode
(use-package go-ts-mode
  :straight (:type built-in)
  :mode "\\.go\\'"
  :hook ((go-ts-mode . eglot-ensure)
         (go-ts-mode . (lambda () (setq-local my/external-formatter #'+goimports-buffer))))
  :init
  (setq-default go-ts-mode-indent-offset 4)
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(go-ts-mode . ("gopls")))))

;;; Go mod
(use-package go-mod-ts-mode
  :straight (:type built-in)
  :mode "go\\.mod\\'")

;;; Formatter: goimports (formats + manages imports)
(reformatter-define +goimports
  :program "goimports"
  :lighter " goimports")

;;; Gotest (test runner integration)
(use-package gotest
  :straight t
  :after go-ts-mode
  :bind (:map go-ts-mode-map
              ("C-c t t" . go-test-current-test)
              ("C-c t f" . go-test-current-file)
              ("C-c t p" . go-test-current-project)
              ("C-c t b" . go-test-current-benchmark)
              ("C-c t c" . go-test-current-coverage)
              ("C-c t r" . go-run)))

;;; Go-tag (struct tag management)
(use-package go-tag
  :straight t
  :after go-ts-mode
  :bind (:map go-ts-mode-map
              ("C-c t a" . go-tag-add)
              ("C-c t d" . go-tag-remove))
  :custom
  (go-tag-args '("-transform" "camelcase")))

(provide 'dev-go)
;;; dev-go.el ends here
