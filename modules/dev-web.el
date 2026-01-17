;;; dev-web.el --- Web development configuration -*- lexical-binding: t -*-

;;;; HTML
(use-package html-ts-mode
  :straight (:type built-in)
  :mode (("\\.html\\'" . html-ts-mode)
          ("\\.htm\\'" . html-ts-mode))
  :hook (html-ts-mode . eglot-ensure)
  :custom
  (sgml-basic-offset 2))

;;;; CSS
(use-package css-ts-mode
  :straight (:type built-in)
  :mode (("\\.css\\'" . css-ts-mode)
          ("\\.scss\\'" . css-ts-mode))
  :hook (css-ts-mode . eglot-ensure)
  :custom
  (css-indent-offset 2))

;;;; Emmet - HTML/CSS abbreviations
(use-package emmet-mode
  :hook ((html-ts-mode . emmet-mode)
          (css-ts-mode . emmet-mode)
          (web-mode . emmet-mode)
          (typescript-ts-mode . emmet-mode)
          (tsx-ts-mode . emmet-mode))
  :custom
  (emmet-move-cursor-between-quotes t)
  :general
  (local-leader-def
    :keymaps '(html-ts-mode-map css-ts-mode-map web-mode-map)
    "e" 'emmet-expand-line))

;;;; Rainbow Mode - Show colors inline
(use-package rainbow-mode
  :hook ((css-ts-mode . rainbow-mode)
          (html-ts-mode . rainbow-mode)
          (web-mode . rainbow-mode)))

;;;; Web-mode - for mixed content files
(use-package web-mode
  :mode (("\\.html?\\'" . web-mode)
          ("\\.phtml\\'" . web-mode)
          ("\\.erb\\'" . web-mode)
          ("\\.html\\.erb\\'" . web-mode)
          ("\\.tpl\\.php\\'" . web-mode)
          ("\\.jsp\\'" . web-mode)
          ("\\.as[cp]x\\'" . web-mode)
          ("\\.mustache\\'" . web-mode)
          ("\\.handlebars\\'" . web-mode)
          ("\\.hbs\\'" . web-mode)
          ("\\.vue\\'" . web-mode)
          ("\\.svelte\\'" . web-mode))
  :general
  (local-leader-def
    :keymaps 'web-mode-map
    "n" 'web-mode-tag-match
    "e" 'emmet-expand-line
    "r" 'web-mode-element-rename
    "w" 'web-mode-element-wrap)
  :custom
  (web-mode-markup-indent-offset 2)
  (web-mode-css-indent-offset 2)
  (web-mode-code-indent-offset 2)
  (web-mode-enable-auto-pairing t)
  (web-mode-enable-auto-closing t)
  (web-mode-enable-current-element-highlight t)
  (web-mode-enable-css-colorization t)
  (web-mode-enable-block-face t)
  (web-mode-enable-part-face t)
  (web-mode-enable-comment-interpolation t)
  (web-mode-enable-heredoc-fontification t))

(provide 'dev-web)
;;; dev-web.el ends here
