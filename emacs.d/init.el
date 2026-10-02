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
(defcustom my/org-directory "~/org"
  "Directory for Org task management."
  :type 'directory
  :group 'mymacs)
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
        package-check-signature nil
        package-review-policy '((archive . "melpa"))
        package-native-compile t
        package-quickstart t)

;;; Modules
;;;; Shared maps and notebook
(require 'my-keymaps)

;;;; Environment setup (to start Emacs from a launcher)
(require 'my-environment)

;;;; Core UI
(require 'my-core-ui)

;;;; Completion
(require 'my-completion)

;;;; windows and buffers
(require 'my-windows)

;;;; auto-revert
(require 'my-session)

;;;; Editing
(require 'my-editing)

;;;; Files
(require 'my-files)

;;;; Search
(require 'my-search)

;;;; Projects
(require 'my-projects)

;;;; terminal
(require 'my-terminal)

;;;; Text
(require 'my-text)

;;;; Note taking
(require 'my-notes)

;;;; Task management
(require 'my-tasks)

;;;; Programming
(require 'my-programming)

;;;; Work tools
(require 'my-work-tools)
