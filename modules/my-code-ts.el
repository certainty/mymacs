;;; my-code-ts.el --- JS/TS -*- lexical-binding: t; -*-

(use-package jest-test-mode)

(use-package typescript-mode
  :after jest
  :hook
  (typescript-mode . jest-test-mode)
  (typescript-mode . eglot-ensure)
  (typescript-ts-mode . eglot-ensure)
  (typescript-ts-mode . jest-test-mode)
  (js-mode . eglot-ensure)
  (js-ts-mode . eglot-ensure))

(use-package prettier-js
  :hook (typescript-mode typescrip-ts-mode))
(provide 'my-code-ts)
