;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Runs before package initialization. Sets up GC, frame defaults,
;; native compilation, and local vendored package load paths.
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

;;; Vendored packages
;; Emacs 31 discovers `user-lisp' package directories automatically.
;; Add them explicitly so the same layout works on current releases too.
(defun my/add-vendored-load-paths (root)
  "Add ROOT and its package subdirectories to `load-path'."
  (when (file-directory-p root)
    (add-to-list 'load-path root)
    (dolist (entry (directory-files root t directory-files-no-dot-files-regexp))
      (when (file-directory-p entry)
        (add-to-list 'load-path entry)
        (dolist (subdir '("lisp" "src"))
          (let ((path (expand-file-name subdir entry)))
            (when (file-directory-p path)
              (add-to-list 'load-path path))))))))

(let* ((emacs-dir (file-name-as-directory user-emacs-directory))
       (real-emacs-dir (file-name-as-directory (file-truename user-emacs-directory)))
       (roots (delete-dups
               (delq nil
                     (list emacs-dir
                           real-emacs-dir
                           (file-name-directory (directory-file-name emacs-dir))
                           (file-name-directory (directory-file-name real-emacs-dir)))))))
  (dolist (root roots)
    (my/add-vendored-load-paths (expand-file-name "user-lisp" root))))

;;; Terminal clipboard integration
;; Enable OSC 52 clipboard export during terminal initialization.
(unless (display-graphic-p)
  (defvar xterm-extra-capabilities nil)
  (add-to-list 'xterm-extra-capabilities 'setSelection))

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
          ;; Avoid async native-comp cache races in batch/tooling sessions.
          native-comp-jit-compilation (not noninteractive)
          native-comp-async-jobs-number (max 2 (1- (num-processors)))
          native-comp-speed 2
          native-comp-prune-cache t)))

(provide 'early-init)
;;; early-init.el ends here
