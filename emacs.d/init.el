;; -*- lexical-binding: t; -*-

;;; Conventions
;; - user defined functions use my/ prefix
;; - private user defined functions use my-- prefix
;; - user defined interactive functions use + prefix
;;
;; Use of use-package
;;
;; All uses of use-package put the options into the same order which is defined below.
;; If an option doesn't apply the order resumes with the next one.
;;
;; - :if / :unless
;; - :ensure
;; - :demand
;; - :pin
;; - :mode
;; - :hook
;; - :commands
;; - :bind
;; - :custom
;; - :preface
;; - :init
;; - :config

;;; Customization
(defgroup mymacs nil
  "User configuration for my emacs"
  :prefix "my/"
  :group 'emacs)

(defcustom my/user-name "john doe" "Full name" :type 'string :group 'mymacs)
(defcustom my/theme 'modus-vivendi "The theme to use" :type 'symbol :group 'mymacs)
(defcustom my/font "Maple Mono NF" "The font to use" :type 'string :group 'mymacs)
(defcustom my/font-height 110 "The font height" :type 'number :group 'mymacs)
(defcustom my/font-weight 'light "The font weigh" :type 'symbol :group 'mymacs)

(defcustom my/notes-directory "~/notes"
  "Directory for personal notes."
  :type 'directory
  :group 'mymacs)
(defcustom my/pmd-enabled nil "Enable consult-pmd" :type 'boolean :group 'mymacs)
(defcustom my/pmd-base-url nil "The pmd url" :type 'string :group 'mymacs)
(defcustom my/quick-links nil
  "Alist of frequently used web bookmarks.
Each entry is a cons cell of the form (DESCRIPTION . URL)."
  :type '(alist :key-type string :value-type string)
  :group 'mymacs)

(defcustom my/org-directory "~/org"
  "Directory for Org task management."
  :type 'directory
  :group 'mymacs)

(defcustom my/org-tasks-file  "todo.org" "Path to the tasks file relative to the org-directory" :type 'string :group 'mymacs)
(defcustom my/gptel-enabled nil "Use gptel with mistral" :type 'boolean :group 'mymacs)
(defcustom my/agent-shell-enabled nil "Use agent-shell with acp" :type 'boolean :group 'mymacs)

;;;; load custom file
(setopt custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; Packages

;; The main objective for packages is to strike a good balance between security
;; and functionality. This is achieved by:
;; - using as few packages as possible
;; - pin to the conservative archives
;; - require review for melpa packages
(require 'package)
(require 'use-package)
(add-to-list 'load-path (directory-file-name
                         (expand-file-name "modules" user-emacs-directory)))
(setq use-package-always-pin "gnu")
(setopt package-archives
        '(("gnu" . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")
          ("melpa" . "https://melpa.org/packages/"))
        package-archive-priorities
        '(("gnu" . 20)
          ("nongnu" . 10)
          ("melpa" . 3))
        ;; we have to pin all packages by default to prevent melpa packages
        ;; from getting precedence
        network-security-level 'high
        gnutls-verify-error t
        package-install-upgrade-built-in nil
        package-check-signature 'allow-unsigned
        package-review-policy '((archive . "melpa"))
        package-native-compile t
        package-quickstart t)

;;; Modules
;;;; Shared maps and notebook
(require 'my-keymaps)

(defvar mymacs-emulation-mode-map-alist
  `((mymacs-mode . ,mymacs-mode-map))
  "Keymap alist giving `mymacs-mode-map' precedence.")

(define-minor-mode mymacs-mode
  "My personal minor mode"
  :init-value t
  :global t
  :group 'mymacs
  :lighter " MyM"
  :keymap mymacs-mode-map)

(add-to-list 'emulation-mode-map-alists 'mymacs-emulation-mode-map-alist)
(mymacs-mode 1)

;;;; Environment setup (to start Emacs from a launcher)
(require 'my-environment)
(require 'my-core-ui)
(require 'my-completion)
(require 'my-windows)
(require 'my-editing)
(require 'my-files)
(require 'my-search)
(require 'my-projects)
(require 'my-tools)
(require 'my-notes)
(require 'my-tasks)
(require 'my-programming)
(require 'my-ai)
