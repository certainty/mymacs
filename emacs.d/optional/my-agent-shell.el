;;; my-agent-shell.el --- Agent shell configuration helpers -*- lexical-binding: t; -*-

;;; Code:

(when my/agent-shell-enabled
  (require 'agent-shell)
  (require 'agent-shell-openai))
(require 'map)
(require 'seq)
(require 'subr-x)

(defgroup my-agent-shell nil
  "Local agent-shell configuration."
  :group 'mymacs)

(defcustom my-agent-shell-codex-model "gpt-5.4"
  "Default agent-shell Codex model."
  :type '(choice (const nil) string)
  :set (lambda (symbol value)
         (set-default symbol value)
         (when (boundp 'agent-shell-openai-default-model-id)
           (setopt agent-shell-openai-default-model-id value)))
  :group 'my-agent-shell)

(defcustom my-agent-shell-codex-session-mode "agent"
  "Default agent-shell Codex session mode."
  :type '(choice (const nil) string)
  :set (lambda (symbol value)
         (set-default symbol value)
         (when (boundp 'agent-shell-openai-default-session-mode-id)
           (setopt agent-shell-openai-default-session-mode-id value)))
  :group 'my-agent-shell)

(defcustom my-agent-shell-lima-instance "agent-vm"
  "Lima instance used for agent-shell Codex."
  :type 'string
  :group 'my-agent-shell)

(defcustom my-agent-shell-lima-global-flags '("--tty=false")
  "Global flags passed to `limactl' before the subcommand."
  :type '(repeat string)
  :group 'my-agent-shell)

(defcustom my-agent-shell-lima-flags '("--start")
  "Flags passed to `limactl shell' before the instance name."
  :type '(repeat string)
  :group 'my-agent-shell)

(defcustom my-agent-shell-path-map '(("~/code" . "/home/dev/code"))
  "Alist mapping local base paths to guest base paths."
  :type '(alist :key-type directory :value-type directory)
  :group 'my-agent-shell)

(defun my-agent-shell--directory-name (path)
  "Return normalized directory name for PATH."
  (directory-file-name (expand-file-name path)))

(defun my-agent-shell--translate-path-1 (path from to)
  "Translate PATH from FROM base to TO base."
  (let* ((path (expand-file-name path))
         (from-root (my-agent-shell--directory-name from))
         (to-root (my-agent-shell--directory-name to))
         (from-prefix (file-name-as-directory from-root)))
    (cond
     ((string= path from-root)
      to-root)
     ((string-prefix-p from-prefix path)
      (concat (file-name-as-directory to-root)
              (substring path (length from-prefix))))
     (t nil))))

(defun my-agent-shell-translate-path (path)
  "Translate PATH between bases in `my-agent-shell-path-map'."
  (or (seq-some (lambda (mapping)
                  (or (my-agent-shell--translate-path-1 path (car mapping) (cdr mapping))
                      (my-agent-shell--translate-path-1 path (cdr mapping) (car mapping))))
                my-agent-shell-path-map)
      path))

(defun my-agent-shell--codex-buffer-p (buffer)
  "Return non-nil when BUFFER belongs to Codex."
  (when-let* ((config (agent-shell-get-config buffer)))
    (eq (map-elt config :identifier) 'codex)))

(defun my-agent-shell--lima-command (guest-cwd command)
  "Return Lima command for running COMMAND in GUEST-CWD."
  (append
   (list "limactl")
   my-agent-shell-lima-global-flags
   (list "shell")
   my-agent-shell-lima-flags
   (list "--workdir" guest-cwd my-agent-shell-lima-instance)
   command))

(defun my-agent-shell--codex-command ()
  "Return command used to start Codex ACP in Lima."
  (my-agent-shell--lima-command
   (my-agent-shell-translate-path (agent-shell-cwd))
   agent-shell-openai-codex-acp-command))

(defun my-agent-shell--quote-shell-argument (argument)
  "Quote ARGUMENT for readable POSIX shell display."
  (if (string-match-p "\\`[[:alnum:]_./:@%+=,-]+\\'" argument)
      argument
    (concat "'"
            (string-replace "'" "'\\''" argument)
            "'")))

(defun my-agent-shell--command-string (command)
  "Return readable shell command string for COMMAND."
  (string-join (mapcar #'my-agent-shell--quote-shell-argument command) " "))

(defun my-agent-shell--command-prefix (buffer)
  "Return Lima command prefix for Codex BUFFER."
  (when (my-agent-shell--codex-buffer-p buffer)
    (butlast (my-agent-shell--codex-command)
             (length agent-shell-openai-codex-acp-command))))

;;;###autoload
(defun +vm-agent-shell-command ()
  "Show command used to start Codex agent-shell inside Lima."
  (interactive)
  (let ((command (my-agent-shell--command-string
                  (my-agent-shell--codex-command))))
    (kill-new command)
    (message "%s" command)))

;;;###autoload
(defun +vm-agent-shell-check ()
  "Check Lima cwd and Codex ACP executable."
  (interactive)
  (let* ((guest-cwd (my-agent-shell-translate-path (agent-shell-cwd)))
         (command (my-agent-shell--lima-command
                   guest-cwd
                   (list "bash"
                         "-lc"
                         "printf 'cwd=%s\n' \"$PWD\"; printf 'codex-acp='; command -v codex-acp"))))
    (message "%s" (my-agent-shell--command-string command))
    (apply #'call-process (car command) nil "*vm-agent-shell-check*" t (cdr command))
    (pop-to-buffer "*vm-agent-shell-check*")))

;;;###autoload
(defun +vm-agent-shell ()
  "Start Codex agent-shell inside Lima."
  (interactive)
  (+vm-agent-shell-command)
  (agent-shell-openai-start-codex))

(when my/agent-shell-enabled
  (setopt agent-shell-openai-default-model-id my-agent-shell-codex-model
          agent-shell-openai-default-session-mode-id my-agent-shell-codex-session-mode
          agent-shell-command-prefix #'my-agent-shell--command-prefix
          agent-shell-path-resolver-function #'my-agent-shell-translate-path))

(provide 'my-agent-shell)

;;; my-agent-shell.el ends here
