;;; init.el ---  -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;;; Elpaca

(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

(use-package use-package
  :ensure nil
  :demand t
  :custom
  (use-package-always-defer t)
  (use-package-always-ensure t)
  (use-package-verbose t)
  (use-package-minmum-reported-time 0)
  (use-package-expand-minimally t))

;; secure connections
(use-package gnutls
  :ensure nil
  :init
  (setopt gnutls-verify-error t)
  (setopt gnutls-min-prime-bits 3072))

(use-package diminish
  :ensure t
  :demand t)

(require 'my-settings)
(require 'my-mode)
(require 'my-evil)
(require 'my-keys)
(require 'my-ui)
(require 'my-ux)
(require 'my-files)
(require 'my-windows)
(require 'my-sessions)
(require 'my-vcs)
(require 'my-tools-asdf)
(require 'my-tools-terminal)
(require 'my-org)

(require 'my-code-essentials)
(require 'my-code-treesitter)
(require 'my-code-checkers)
(require 'my-code-eglot)
(require 'my-code-elisp)
(require 'my-code-scala)
(require 'my-code-ruby)
(require 'my-code-ts)
(require 'my-code-web)
(require 'my-code-data)

(require 'my-writing-spelling)
(require 'my-writing-tools)
(require 'my-writing-denote)

(require 'my-ai)
(require 'my-tools-search)
