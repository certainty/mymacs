;;; core-help.el --- Help system -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defun +emacs-manual ()
  "Display Emacs manual."
  (interactive)
  (info "emacs"))

(defun +elisp-manual ()
  "Display Emacs Lisp manual."
  (interactive)
  (info "elisp"))

(defun +describe-face-at-point ()
  "Describe the face at point."
  (interactive)
  (let ((face (get-text-property (point) 'face)))
    (if face
      (describe-face face)
      (message "No face at point"))))

(defun my/doc--buffer (name content)
  "Show CONTENT in a temporary help-like buffer named NAME."
  (let ((buf (get-buffer-create name)))
    (with-current-buffer buf
      (read-only-mode -1)
      (erase-buffer)
      (insert content)
      (goto-char (point-min))
      (special-mode))
    (pop-to-buffer buf)))

(defun +go-doc (query)
  "Show Go docs for QUERY using `go doc`."
  (interactive (list (read-string "Go doc: " (thing-at-point 'symbol))))
  (let ((buf (get-buffer-create "*Go Doc*")))
    (with-current-buffer buf
      (read-only-mode -1)
      (erase-buffer)
      (if (zerop (call-process "go" nil buf nil "doc" query))
        (progn
          (goto-char (point-min))
          (special-mode)
          (pop-to-buffer buf))
        (message "go doc failed for %s" query)))))

(defun +ruby-doc (query)
  "Show Ruby docs for QUERY using `ri`."
  (interactive (list (read-string "Ruby doc (ri): " (thing-at-point 'symbol))))
  (let ((buf (get-buffer-create "*Ruby Doc*")))
    (with-current-buffer buf
      (read-only-mode -1)
      (erase-buffer)
      (if (zerop (call-process "ri" nil buf nil query))
        (progn
          (goto-char (point-min))
          (special-mode)
          (pop-to-buffer buf))
        (message "ri failed for %s" query)))))

(defun +scala-doc (query)
  "Search Scala docs for QUERY via Zeal docsets."
  (interactive (list (read-string "Scala doc: " (thing-at-point 'symbol))))
  (if (fboundp 'zeal-at-point-search)
    (zeal-at-point-search query)
    (user-error "Zeal is not available on this system")))

(when (eq system-type 'gnu/linux)
  (use-package zeal-at-point
    :commands (zeal-at-point zeal-at-point-search)
    :custom
    (zeal-at-point-mode-alist
      '((go-mode . ("Go"))
         (go-ts-mode . ("Go"))
         (ruby-mode . ("Ruby"))
         (ruby-ts-mode . ("Ruby"))
         (scala-mode . ("Scala"))
         (scala-ts-mode . ("Scala"))))
    (zeal-at-point-docsets '("Go" "Ruby" "Scala"))))

(use-package devdocs
  :commands (devdocs-lookup devdocs-search)
  :custom
  (devdocs-data-dir (expand-file-name "data/devdocs" user-emacs-directory)))

(use-package helpful
  :bind
  (:map +help-search
    ("f" . helpful-callable)
    ("F" . helpful-function)
    ("v" . helpful-variable)
    ("k" . helpful-key)
    ("c" . helpful-command)
    ("s" . helpful-symbol)
    ("." . helpful-at-point)
    ("m" . describe-mode)
    ("b" . describe-bindings)
    ("K" . describe-keymap)
    ("a" . apropos)
    ("A" . apropos-documentation)
    ("P" . describe-package)
    ("C" . describe-char)
    ("T" . describe-theme)
    ("x" . describe-syntax))

  (([remap describe-function] . helpful-callable)
    ([remap describe-variable] . helpful-variable)
    ([remap describe-key] . helpful-key)
    ([remap describe-command] . helpful-command)
    ([remap describe-symbol] . helpful-symbol))
  :custom
  (helpful-max-buffers 2))

;;;; Info mode enhancements
(use-package info
  :straight (:type built-in)
  :bind
  (:map  +help-search
    ("i" . info)
    ("I" . info-apropos)
    ("w" . woman)
    ("e" . +emacs-manual)
    ("E" . +elisp-manual))
  :custom
  (Info-use-header-line nil))


(use-package emacs
  :straight (:type built-in)
  :preface
  (define-prefix-command '+language)
  (define-key +help-search "l" +language)

  :bind
  (:map +language
    ("g" . +go-doc)
    ("r" . +ruby-doc)
    ("s" . +scala-doc)
    ("d" . devdocs-lookup)
    ("D" . devdocs-search)
    ("z" . zeal-at-point)
    ("Z" . zeal-at-point-search)))

(provide 'core-help)
;;; core-help.el ends here
