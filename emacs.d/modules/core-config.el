;;; core-config.el --- Authoritative configuration values -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Central location for user-facing configuration values, feature toggles,
;; platform assumptions, and paths.  All conditional logic in other modules
;; depends on values defined here.  This file is a good candidate for
;; templating via chezmoi or similar tools.
;;
;; Do NOT scatter defcustoms across modules.  If a value might vary
;; between machines or contexts, define it here and reference it elsewhere.
;;
;;; Code:

(defgroup mymacs nil
  "User configuration for this Emacs setup."
  :prefix "my/"
  :group 'emacs)

;;; Identity
(defcustom my/user-full-name "example user"
  "Full name used by Emacs."
  :type 'string
  :group 'mymacs)

(defcustom my/user-mail-address "user@example.com"
  "Default email address."
  :type 'string
  :group 'mymacs)

;;; Feature toggles
(defcustom my/enable-ai nil
  "Legacy compatibility toggle for enabling both AI integrations."
  :type 'boolean
  :group 'mymacs)

(defcustom my/ai-enable-aci nil
  "When non-nil, load AI Code Interface."
  :type 'boolean
  :group 'mymacs)

(defcustom my/ai-enable-eca nil
  "When non-nil, load Editor Code Assistant."
  :type 'boolean
  :group 'mymacs)

(defcustom my/ai-aci-backend 'codex
  "Backend used by AI Code Interface."
  :type '(choice (const :tag "OpenAI Codex" codex)
                 (const :tag "OpenCode" opencode)
                 (const :tag "ECA" eca))
  :group 'mymacs)

(defcustom my/ai-aci-enable-magit-integration nil
  "When non-nil, add AI Code commands to Magit transients."
  :type 'boolean
  :group 'mymacs)

(defcustom my/enable-writing t
  "When non-nil, load writing modules (spell-check, notes, org)."
  :type 'boolean
  :group 'mymacs)

(defcustom my/enable-gtd t
  "When non-nil, load GTD workflow (capture, agenda, review)."
  :type 'boolean
  :group 'mymacs)


(defcustom my/enable-dev-scala nil
  "When non-nil, load Scala language support."
  :type 'boolean
  :group 'mymacs)

(defcustom my/enable-dev-ruby t
  "When non-nil, load Ruby language support."
  :type 'boolean
  :group 'mymacs)

(defcustom my/enable-dev-go t
  "When non-nil, load Go language support."
  :type 'boolean
  :group 'mymacs)

(defcustom my/enable-dev-web t
  "When non-nil, load web development support."
  :type 'boolean
  :group 'mymacs)

(defcustom my/enable-dev-common-lisp t
  "When non-nil, load Common Lisp support (SBCL, sly)."
  :type 'boolean
  :group 'mymacs)

;;; Fonts
;; TODO: use complete font definitions instead of just font names
(defcustom my/font "Maple Mono NF"
  "Fixed-pitch font family."
  :type 'string
  :group 'mymacs)

(defcustom my/pitch-font "Maple Mono NF"
  "Variable-pitch font family."
  :type 'string
  :group 'mymacs)

(defcustom my/ui-font "Maple Mono NF"
  "Font used for interface elements like the mode line."
  :type 'string
  :group 'mymacs)

(defcustom my/font-size 105
  "Default font height in 1/10pt."
  :type 'integer
  :group 'mymacs)

(defcustom my/bigger-font-size 160
  "Larger font height for presentations or high-DPI."
  :type 'integer
  :group 'mymacs)

(defcustom my/presentation-font-size 210
  "Font height for presentations."
  :type 'integer
  :group 'mymacs)

;;; Paths
(defcustom my/repositories-path "~/code"
  "Base path for cloned repositories."
  :type 'string
  :group 'mymacs)

(defcustom my/org-path "~/Documents/Local/Org"
  "Path to org files."
  :type 'string
  :group 'mymacs)

(defcustom my/notes-path "~/Documents/Local/Notes"
  "Path to note files."
  :type 'string
  :group 'mymacs)

(defcustom my/notes-keywords nil
  "List of know keywords to use for denote"
  :type '(repeat string)
  :group 'mymacs)

(use-package emacs
  :init
  (setopt custom-file (expand-file-name "custom.el" user-emacs-directory))
  (when (file-exists-p custom-file)
    (load custom-file))
  (setopt user-full-name my/user-full-name
    user-mail-address my/user-mail-address))

;;; Minor mode for keybindings
(define-minor-mode mymacs-mode
  "Minor mode providing a home for custom keybindings."
  :global t
  :group 'mymacs
  :lighter " λ"
  :keymap (make-sparse-keymap))

(defun my/enable-mymacs-mode ()
  "Activate `mymacs-mode' after init."
  (mymacs-mode 1))

(my/enable-mymacs-mode)

(provide 'core-config)
;;; core-config.el ends here
