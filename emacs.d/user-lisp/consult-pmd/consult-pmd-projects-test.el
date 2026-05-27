;;; consult-pmd-projects-test.el --- Tests for project clone actions -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)

(unless (require 'consult nil t)
  (provide 'consult))

(defvar embark-target-finders nil)
(defvar embark-keymap-alist nil)
(provide 'embark)
(require 'consult-pmd-projects)

(defun pmd-test--project-data (account repo server-url)
  "Build project test data using ACCOUNT REPO and SERVER-URL."
  (let* ((git-info (make-hash-table :test 'equal))
          (data (make-hash-table :test 'equal)))
    (puthash "account" account git-info)
    (puthash "repo" repo git-info)
    (puthash "server_url" server-url git-info)
    (puthash "git" git-info data)
    data))

(defun pmd-test--store-project (project-id data)
  "Store DATA as PROJECT-ID in PMD entity cache."
  (let ((projects (make-hash-table :test 'equal)))
    (puthash project-id data projects)
    (puthash pmd--project-type
      `((data . ,projects)
         (timestamp . ,(current-time)))
      pmd--entities-data)))

(ert-deftest pmd-projects-preferred-clone-url-converts-https-to-ssh ()
  (should (equal (pmd--projects-preferred-clone-url "https://github.com/acme/widgets")
            "git@github.com:acme/widgets")))

(ert-deftest pmd-projects-preferred-clone-url-keeps-non-https ()
  (should (equal (pmd--projects-preferred-clone-url "git@github.com:acme/widgets")
            "git@github.com:acme/widgets")))

(ert-deftest pmd-projects-forge-name-maps-known-hosts ()
  (should (equal (pmd--projects-forge-name "https://github.com/acme/widgets")
            "github"))
  (should (equal (pmd--projects-forge-name "https://codeberg.org/acme/widgets")
            "codeberg"))
  (should (equal (pmd--projects-forge-name "https://gitlab.com/acme/widgets")
            "gitlab")))

(ert-deftest pmd-projects-clone-permanent-clones-into-code-path ()
  (let* ((tmp-root (make-temp-file "pmd-code-" t))
          (pmd--entities-data (make-hash-table :test 'equal))
          (pmd-code-path tmp-root)
          (cloned-args nil)
          (created-dir nil)
          (bookmark-args nil))
    (pmd-test--store-project "p1" (pmd-test--project-data "acme" "widgets" "https://github.com"))
    (cl-letf (((symbol-function 'make-directory)
                (lambda (dir _parents)
                  (setq created-dir dir)))
               ((symbol-function 'bookmark-store)
                 (lambda (name alist no-overwrite)
                   (setq bookmark-args (list name alist no-overwrite))))
               ((symbol-function 'call-process)
                 (lambda (program _in destination _display &rest args)
                   (setq cloned-args (cons program args))
                   (with-current-buffer destination
                     (erase-buffer)
                     (insert "ok"))
                   0)))
      (+pmd-clone-repository-permanent "p1")
      (should (equal (directory-file-name created-dir) (expand-file-name "github/acme" tmp-root)))
      (should (equal cloned-args
                (list "git" "clone" "git@github.com:acme/widgets" (expand-file-name "github/acme/widgets" tmp-root))))
      (should (equal bookmark-args
                (list "acme/widgets"
                  `((filename . ,(expand-file-name "github/acme/widgets" tmp-root)))
                  nil))))))

(ert-deftest pmd-projects-clone-permanent-skips-existing-directory ()
  (let* ((tmp-root (make-temp-file "pmd-code-" t))
          (pmd--entities-data (make-hash-table :test 'equal))
          (pmd-code-temp-path tmp-root)
          (clone-called nil))
    (pmd-test--store-project "p1" (pmd-test--project-data "acme" "widgets" "https://github.com"))
    (make-directory (expand-file-name "github/acme/widgets" tmp-root) t)
    (cl-letf (((symbol-function 'call-process)
                (lambda (&rest _args)
                  (setq clone-called t)
                  0))
               ((symbol-function 'bookmark-store)
                 (lambda (&rest _args) nil)))
      (+pmd-clone-repository-permanent "p1")
      (should-not clone-called))))

(ert-deftest pmd-projects-clone-temp-clones-into-temp-code-path ()
  (let* ((tmp-root (make-temp-file "pmd-temp-code-" t))
          (pmd--entities-data (make-hash-table :test 'equal))
          (pmd-code-temp-path tmp-root)
          (cloned-args nil))
    (pmd-test--store-project "p1" (pmd-test--project-data "acme" "widgets" "https://github.com"))
    (cl-letf (((symbol-function 'make-directory)
                (lambda (&rest _args) t))
               ((symbol-function 'bookmark-store)
                 (lambda (&rest _args) nil))
               ((symbol-function 'call-process)
                 (lambda (program _in destination _display &rest args)
                   (setq cloned-args (cons program args))
                   (with-current-buffer destination
                     (erase-buffer)
                     (insert "ok"))
                   0)))
      (+pmd-clone-repository-temporary "p1")
      (should (equal cloned-args
                (list "git" "clone" "git@github.com:acme/widgets" (expand-file-name "acme/widgets" tmp-root)))))))

(ert-deftest pmd-projects-embark-map-includes-clone-actions ()
  (should (eq (lookup-key pmd-projects-embark-map (kbd "c")) #'+pmd-clone-repository-permanent))
  (should (eq (lookup-key pmd-projects-embark-map (kbd "C")) #'+pmd-clone-repository-temporary)))

;;; consult-pmd-projects-test.el ends here
