;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Runs before package initialization. Sets up GC, frame defaults,
;; native compilation, and disables package.el in favor of straight.el.
;;
;;; Code:

(when (< emacs-major-version 30)
  (error "This configuration requires Emacs 30 or higher"))

;;; Garbage collection -- loosen during startup, reset after
(defvar my/original-gc-threshold gc-cons-threshold)
(defvar my/original-gc-percentage gc-cons-percentage)

(defun my/reset-gc ()
  "Restore GC thresholds to sane values after startup."
  (setq gc-cons-threshold my/original-gc-threshold
        gc-cons-percentage my/original-gc-percentage))

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook #'my/reset-gc)

;;; Prefer source over stale byte-compiled files
(setq load-prefer-newer t)

;;; Disable package.el -- straight.el manages packages
(setq package-enable-at-startup nil)

;;; Frame defaults -- remove decorations early to avoid flicker
(push '(undecorated . t) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

;;; Background -- set early to avoid flash of white
(push '(background-color . "black") default-frame-alist)
(push '(foreground-color . "white") default-frame-alist)

;;; Native compilation
(when (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (with-no-warnings
    (setq native-comp-async-report-warnings-errors 'silent
          native-comp-jit-compilation t
          native-comp-async-jobs-number (max 2 (1- (num-processors)))
          native-comp-speed 2
          native-comp-prune-cache t)))

(provide 'early-init)
;;; early-init.el ends here
