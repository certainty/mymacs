;; -*- lexical-binding: t; -*-

(declare-function project-root "project")
(declare-function project-current "project")

(defun my/scala--project-root ()
  "Return the current project root for Scala commands."
  (when-let* ((project (project-current nil)))
    (project-root project)))

(defun my/scala--top-level-name ()
  "Return the current Scala spec class name in the buffer."
  (save-excursion
    (goto-char (point-min))
    (or (when (re-search-forward
                "^\\s-*\\(?:case\\s-+\\)?\\(?:class\\|object\\|trait\\)\\s-+\\([[:word:]_][[:word:]_0-9]*\\)\\s-+extends\\s-+.*\\<Specification\\>"
                nil t)
          (match-string-no-properties 1))
      (when (re-search-forward
              "^\\s-*\\(?:case\\s-+\\)?\\(?:class\\|object\\|trait\\)\\s-+\\([[:word:]_][[:word:]_0-9]*\\)"
              nil t)
        (match-string-no-properties 1)))))

(defun my/scala--package-from-path (&optional file)
  "Infer a Scala package from FILE relative to the project root."
  (let* ((path (or file buffer-file-name))
          (root (and path (my/scala--project-root)))
          (rel (and root (file-relative-name path root))))
    (when (and rel
            (string-match
              "\\`src/\\(?:test\\|it\\)/scala/\\(.+\\)/[^/]+\\.scala\\'" rel))
      (replace-regexp-in-string "/" "." (match-string 1 rel)))))

(defun my/scala--spec-target ()
  "Return the fully qualified test target for the current Scala file."
  (let* ((package (or (my/scala--package-from-path)
                    (save-excursion
                      (goto-char (point-min))
                      (when (re-search-forward
                              "^\\s-*package\\s-+\\([[:word:]_.]+\\)"
                              nil t)
                        (match-string-no-properties 1)))))
          (name (or (my/scala--top-level-name)
                  (and buffer-file-name (file-name-base buffer-file-name)))))
    (if package
      (format "%s.%s" package name)
      name)))

(defun my/scala--run-test-target (target)
  "Run sbt testOnly for TARGET through `compile'."
  (let ((default-directory (or (my/scala--project-root) default-directory)))
    (compile (format "sbt %s"
                     (shell-quote-argument (format "testOnly %s" target) t)))))


;;;###autoload
(defun +scala-test-only ()
  "Run the current Scala test or prompt for a class name."
  (interactive)
  (let ((test-class (or (and buffer-file-name (my/scala--spec-target))
                      (read-string "Test class: "))))
    (my/scala--run-test-target test-class)))


(provide 'dev-scala)
