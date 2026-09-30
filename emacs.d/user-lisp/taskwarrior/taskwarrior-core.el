;;; taskwarrior-core.el --- Taskwarrior process and data access -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0"))
;;; Commentary:
;; Shared, shell-free access to the Taskwarrior command line and JSON export.
;;; Code:

(require 'json)
(require 'subr-x)

(defgroup taskwarrior nil
  "Taskwarrior integration."
  :group 'tools)

(defcustom taskwarrior-executable "task"
  "Taskwarrior executable."
  :type 'string
  :group 'taskwarrior)

(defun taskwarrior-run (&rest arguments)
  "Run Taskwarrior with ARGUMENTS and return its output.
Signal a user error when Taskwarrior cannot be run or exits unsuccessfully."
  (unless (executable-find taskwarrior-executable)
    (user-error "Taskwarrior executable `%s' is not on PATH"
                taskwarrior-executable))
  (with-temp-buffer
    (let ((status (apply #'process-file taskwarrior-executable nil
                         (list (current-buffer) t) nil arguments)))
      (unless (and (integerp status) (zerop status))
        (user-error "Taskwarrior failed: %s"
                    (string-trim (buffer-string))))
      (buffer-string))))

(defun taskwarrior-parse-arguments (input &optional allow-empty)
  "Parse INPUT into command arguments without invoking a shell.
Unless ALLOW-EMPTY is non-nil, reject empty input."
  (let ((arguments (split-string-shell-command input)))
    (unless (or arguments allow-empty)
      (user-error "Enter at least one Taskwarrior argument"))
    arguments))

(defun taskwarrior-reports ()
  "Return the names of configured Taskwarrior reports."
  (let (reports)
    (dolist (line (split-string (taskwarrior-run "reports") "\n" t))
      (when (string-match "^\\([[:alnum:]_.-]+\\)[[:space:]]\\{2,\\}" line)
        (unless (equal (match-string 1 line) "Report")
          (push (match-string 1 line) reports))))
    (nreverse reports)))

(defun taskwarrior-contexts ()
  "Return the names of configured Taskwarrior contexts."
  (split-string (taskwarrior-run "_context") "\n" t "[[:space:]]+"))

(defun taskwarrior-current-context ()
  "Return the active Taskwarrior context name, or nil."
  (let ((context (string-trim (taskwarrior-run "_get" "rc.context"))))
    (unless (string-empty-p context) context)))

(defun taskwarrior-commands ()
  "Return Taskwarrior command names suitable for completion."
  (split-string (taskwarrior-run "_commands") "[[:space:]]+" t))

(defun taskwarrior-tasks (report filters)
  "Return tasks from REPORT restricted by FILTERS as hash tables."
  (let ((output (apply #'taskwarrior-run
                       (append filters (list "export" report)))))
    (condition-case err
        (let ((tasks (json-parse-string output :array-type 'list
                                        :object-type 'hash-table
                                        :null-object nil)))
          (unless (listp tasks)
            (user-error "Report %s did not export a task list" report))
          tasks)
      (json-parse-error
       (user-error "Taskwarrior did not export JSON for %s: %s"
                   report (error-message-string err))))))

(defun taskwarrior-task-information (uuid)
  "Return Taskwarrior's detailed information for UUID."
  (taskwarrior-run uuid "information"))

(defun taskwarrior-add (arguments)
  "Add a task using Taskwarrior ARGUMENTS and return command output."
  (apply #'taskwarrior-run "add" arguments))

(defun taskwarrior-run-on (uuids command &rest arguments)
  "Run COMMAND with ARGUMENTS on task UUIDS and return command output.
Taskwarrior's confirmation is disabled because callers are responsible for
confirming mutations before invoking this function."
  (unless uuids
    (user-error "Select at least one task"))
  (apply #'taskwarrior-run
         (append (list "rc.confirmation=no") uuids (list command) arguments)))

(defun taskwarrior-set-context (context)
  "Activate Taskwarrior CONTEXT, or clear it when CONTEXT is nil."
  (taskwarrior-run "context" (or context "none")))

(defun taskwarrior-undo ()
  "Undo the most recent Taskwarrior change and return command output."
  (taskwarrior-run "rc.confirmation=no" "undo"))

(provide 'taskwarrior-core)
;;; taskwarrior-core.el ends here
