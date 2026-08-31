;;; links.el --- Frequently used web links -*- lexical-binding: t; -*-
;;
;; Package-Requires: ((emacs "31.0"))
;;; Commentary:
;; Select and open frequently used web links with Consult.
;;
;;; Code:

(require 'browse-url)
(require 'consult)

(defvar links/quick-links-history nil
  "History of selections made by `+links-bookmarks'.")

(defun my--open-url (url)
  "Open URL with the platform URL handler."
  (let ((browse-url-generic-program
         (pcase system-type
           ('gnu/linux "xdg-open")
           ('darwin "open"))))
    (if browse-url-generic-program
        (let ((browse-url-browser-function #'browse-url-generic))
          (browse-url url))
      (browse-url url))))

;;;###autoload
(defun +links-bookmarks ()
  "Select a frequently used web bookmark and open it."
  (interactive)
  (when-let* ((description
               (consult--read
                (mapcar #'car my/quick-links)
                :prompt "Web bookmark: "
                :category 'links-bookmark
                :history 'links/quick-links-history
                :require-match t
                :sort nil))
              (url (alist-get description my/quick-links nil nil #'string=)))
    (my--open-url url)))

(provide 'links)
;;; links.el ends here
