;;; core-dashboard.el --- Startup behavior -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Startup settings that do not rely on an external dashboard package.
;;
;;; Code:

(use-package emacs
  :init
  (setq inhibit-startup-screen t
        inhibit-startup-message t
        inhibit-startup-echo-area-message user-login-name
        initial-buffer-choice nil))

(provide 'core-dashboard)
;;; core-dashboard.el ends here
