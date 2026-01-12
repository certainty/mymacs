;;; core-help.el --- Help system -*- lexical-binding: t; -*-
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defun my/info-display-manual ()
  "Display Emacs manual."
  (interactive)
  (info "emacs"))

(defun my/info-elisp-manual ()
  "Display Emacs Lisp manual."
  (interactive)
  (info "elisp"))

(defun my/describe-face-at-point ()
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

(defun my/go-doc (query)
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

(defun my/ruby-doc (query)
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

(defun my/scala-doc (query)
  "Search Scala docs for QUERY via Zeal docsets."
  (interactive (list (read-string "Scala doc: " (thing-at-point 'symbol))))
  (if (fboundp 'zeal-at-point-search)
    (zeal-at-point-search query)
    (user-error "Zeal is not available on this system")))

(defvar my/web-search-provider "https://duckduckgo.com/?q=%s"
  "URL template for web search queries.")

(defun my/web-search (query)
  "Search the web for QUERY in the default browser."
  (interactive
    (list (read-string "Web search: " (thing-at-point 'symbol))))
  (browse-url (format my/web-search-provider (url-hexify-string query))))

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
  (([remap describe-function] . helpful-callable)
    ([remap describe-variable] . helpful-variable)
    ([remap describe-key] . helpful-key)
    ([remap describe-command] . helpful-command)
    ([remap describe-symbol] . helpful-symbol))
  :custom
  (helpful-max-buffers 2))

(with-eval-after-load 'general
  (leader-def
    "sh" '(:ignore t :which-key "help")
    "shf" 'helpful-callable
    "shF" 'helpful-function
    "shv" 'helpful-variable
    "shk" 'helpful-key
    "shc" 'helpful-command
    "shs" 'helpful-symbol
    "sh." 'helpful-at-point

    "shm" 'describe-mode
    "shb" 'describe-bindings
    "shK" 'describe-keymap
    "sha" 'apropos
    "shA" 'apropos-documentation

    "shw" 'woman
    "shi" 'info
    "shI" 'info-display-manual
    "she" 'my/info-elisp-manual
    "shE" 'my/info-display-manual

    "shP" 'describe-package
    "shC" 'describe-char
    "shT" 'describe-theme
    "shx" 'describe-syntax

    "shd" '(:ignore t :which-key "describe")
    "shdf" 'my/describe-face-at-point
    "shdF" 'describe-face
    "shdp" 'describe-text-properties
    "shl" '(:ignore t :which-key "language")
    "shlg" 'my/go-doc
    "shlr" 'my/ruby-doc
    "shls" 'my/scala-doc
    "shg" 'my/web-search
    "shD" 'devdocs-lookup
    "shS" 'devdocs-search
    ;; Which-key
    "sh?" 'which-key-show-top-level
    "shW" 'which-key-show-major-mode)

  (when (eq system-type 'gnu/linux)
    (leader-def
      "shz" 'zeal-at-point
      "shZ" 'zeal-at-point-search)))

;;;; Info mode enhancements
(use-package info
  :straight (:type built-in)
  :custom
  (Info-use-header-line nil))

(provide 'core-help)
;;; core-help.el ends here
