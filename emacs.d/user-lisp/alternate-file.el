;; -*- lexical-binding: t; -*-

(declare-function project-current "project")
(declare-function project-root "project")

(defun my/alternate-file--string-list-p (value)
  "Return non-nil when VALUE is a list of strings."
  (and (listp value)
       (seq-every-p #'stringp value)))

(defun my/alternate-file--mapping-group-p (value)
  "Return non-nil when VALUE is one alternate file mapping group."
  (and (listp value)
       (my/alternate-file--string-list-p
        (my/alternate-file--normalize-roots (plist-get value :source)))
       (my/alternate-file--string-list-p
        (my/alternate-file--normalize-roots (plist-get value :test)))
       (my/alternate-file--string-list-p
        (my/alternate-file--normalize-roots (plist-get value :suffixes)))))

(defun my/alternate-file--mapping-entry-p (value)
  "Return non-nil when VALUE is one mode mapping value."
  (cond
   ((null value) t)
   ((keywordp (car-safe value))
    (my/alternate-file--mapping-group-p value))
   ((listp value)
    (seq-every-p #'my/alternate-file--mapping-group-p value))
   (t nil)))

(defun my/alternate-file--mappings-safe-p (value)
  "Return non-nil when VALUE is safe for `my/alternate-file-mappings'."
  (and (listp value)
       (seq-every-p
        (lambda (entry)
          (and (consp entry)
               (symbolp (car entry))
               (my/alternate-file--mapping-entry-p (cdr entry))))
        value)))

(defcustom my/alternate-file-mappings nil
  "Alist mapping major modes to alternate file rules.

Each entry has form:

  (MODE
   (:source (SOURCE-ROOT ...)
    :test (TEST-ROOT ...)
    :suffixes (SUFFIX ...))
   ...)

SOURCE-ROOT and TEST-ROOT are paths relative to project root.
SUFFIX is appended for source to test lookups and stripped for
test to source lookups."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'mymacs)

(put 'my/alternate-file-mappings 'safe-local-variable
     #'my/alternate-file--mappings-safe-p)

(defun my/alternate-file--project-root (&optional file)
  "Return project root for FILE or current buffer."
  (let ((path (or file buffer-file-name)))
    (or (when-let* ((project (project-current nil (and path (file-name-directory path)))))
          (project-root project))
        (and path (locate-dominating-file path ".git"))
        (and path (file-name-directory path))
        default-directory)))

(defun my/alternate-file--relative-path (file)
  "Return FILE relative to its project root."
  (file-relative-name file (my/alternate-file--project-root file)))

(defun my/alternate-file--plist (mode)
  "Return alternate file mapping value for MODE."
  (or (cdr (assq mode my/alternate-file-mappings))
      (let (plist)
        (dolist (entry my/alternate-file-mappings plist)
          (when (derived-mode-p (car entry))
            (setq plist (cdr entry)))))))

(defun my/alternate-file--normalize-roots (value)
  "Return VALUE as list of path roots."
  (cond
   ((null value) nil)
   ((stringp value) (list value))
   (t value)))

(defun my/alternate-file--mapping-groups (mode)
  "Return mapping groups for MODE."
  (let ((value (my/alternate-file--plist mode)))
    (cond
     ((null value) nil)
     ((keywordp (car value)) (list value))
     (t value))))

(defun my/alternate-file--rules-for (&optional mode)
  "Return alternate file rules for MODE."
  (let (rules)
    (dolist (plist (my/alternate-file--mapping-groups (or mode major-mode)))
      (let ((source-roots (my/alternate-file--normalize-roots
                           (plist-get plist :source)))
            (test-roots (my/alternate-file--normalize-roots
                         (plist-get plist :test)))
            (suffixes (my/alternate-file--normalize-roots
                       (plist-get plist :suffixes))))
        (dolist (source-root source-roots)
          (push (list source-root test-roots suffixes 'add) rules))
        (dolist (test-root test-roots)
          (push (list test-root source-roots suffixes 'strip) rules))))
    (nreverse rules)))

(defun my/alternate-file--rule-prefix (rule)
  "Return source prefix from RULE."
  (car rule))

(defun my/alternate-file--match-prefix-p (path prefix)
  "Return non-nil when PATH is inside PREFIX."
  (or (string= prefix "")
      (string= path prefix)
      (string-prefix-p (concat prefix "/") path)))

(defun my/alternate-file--best-rules (path rules)
  "Return most specific matching RULES for PATH."
  (let ((matches nil)
        (best-length -1))
    (dolist (rule rules matches)
      (let ((prefix (my/alternate-file--rule-prefix rule)))
        (when (my/alternate-file--match-prefix-p path prefix)
          (let ((length (length prefix)))
            (cond
             ((> length best-length)
              (setq matches (list rule)
                    best-length length))
             ((= length best-length)
              (push rule matches)))))))))

(defun my/alternate-file--strip-prefix (path prefix)
  "Return PATH without PREFIX."
  (if (string= prefix "")
      path
    (string-remove-prefix (concat prefix "/") path)))

(defun my/alternate-file--apply-suffixes (stem suffixes mode)
  "Return alternate STEM names using SUFFIXES for MODE."
  (let (names)
    (pcase mode
      ('add
       (dolist (suffix suffixes (nreverse names))
         (push (concat stem suffix) names)))
      ('strip
       (dolist (suffix suffixes (nreverse names))
         (when (string-suffix-p suffix stem)
           (push (string-remove-suffix suffix stem) names)))))))

(defun my/alternate-file--build-candidates (file &optional mode)
  "Return candidate alternate files for FILE using MODE."
  (let* ((rules (my/alternate-file--rules-for mode))
         (root (my/alternate-file--project-root file))
         (relative-path (my/alternate-file--relative-path file))
         (matching-rules (my/alternate-file--best-rules relative-path rules))
         (extension (file-name-extension relative-path))
         candidates)
    (dolist (rule matching-rules (delete-dups (nreverse candidates)))
      (pcase-let* ((`(,prefix ,target-roots ,suffixes ,action) rule)
                   (tail (my/alternate-file--strip-prefix relative-path prefix))
                   (directory (file-name-directory tail))
                   (stem (file-name-base tail))
                   (names (my/alternate-file--apply-suffixes stem suffixes action)))
        (dolist (target-root target-roots)
          (dolist (name names)
            (push
             (expand-file-name
              (concat
               (if (string-empty-p target-root) "" (concat target-root "/"))
               (or directory "")
               name
               "."
               extension)
              root)
             candidates)))))))

(defun my/alternate-file--existing-candidates (file &optional mode)
  "Return existing alternate files for FILE using MODE."
  (let (existing)
    (dolist (candidate (my/alternate-file--build-candidates file mode)
                        (nreverse existing))
      (when (file-exists-p candidate)
        (push candidate existing)))))

;;;###autoload
(defun +find-alternate-file ()
  "Find source or test file matching current buffer."
  (interactive)
  (let* ((file (or buffer-file-name
                   (user-error "Current buffer not visiting file")))
         (rules (my/alternate-file--rules-for))
         (candidates (my/alternate-file--existing-candidates file)))
    (unless rules
      (user-error "No alternate file mapping for %s" major-mode))
    (cond
     ((null candidates)
      (user-error "No alternate file found for %s"
                  (file-relative-name file (my/alternate-file--project-root file))))
     ((= (length candidates) 1)
      (find-file (car candidates)))
     (t
      (find-file
       (completing-read "Alternate file: " candidates nil t))))))

(provide 'alternate-file)
