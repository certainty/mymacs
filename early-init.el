;;; early-init.el --- Early init for emacs -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:


(when (< emacs-major-version 30)
  (error "This configuration requires Emacs 30 or higher"))

;; Loosen GC during startup for speed; reset in `init.el'.
(setq gc-cons-threshold most-positive-fixnum
  gc-cons-percentage 0.6)

;; Disable package.el in favor of straight.el
(setq package-enable-at-startup nil)

(push '(undecorated . t) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; set background early to keep it dark
(push '(background-color . "black") default-frame-alist)
(push '(foreground-color . "white") default-frame-alist)


;; Native compilation settings
(when (and (fboundp 'native-comp-available-p)
        (native-comp-available-p))
  (setq native-comp-async-report-warnings-errors 'silent
    native-comp-jit-compilation t
    native-comp-async-jobs-number (max 2 (1- (num-processors)))
    native-comp-speed 2
    native-comp-prune-cache t))

(provide 'early-init)
;;; early-init.el ends here
