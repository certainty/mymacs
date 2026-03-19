;;; citizen-science.el --- Tools and utilities for citizen science -*- lexical-binding: t -*-

;;; Commentary:
;; Field session workflow:
;;
;;  1. M-x +cs/new-field-session   create a denote field-log note + open inbox
;;  2. M-x +cs/import-images       copy photos/scans from camera/folder to inbox
;;  3. M-x +cs/review-inbox        browse thumbnails, press d/x to cull
;;  4. (in dired) mark files        C-c C-d C-k to bulk-rename with denote scheme
;;  5. M-x +cs/insert-inbox-image-links   insert links at point (pointing to inbox/)
;;  6. M-x +cs/finalize-session    move inbox → media/, rewrite links in current buffer
;;
;; Images end up in +cs/media-path, a single shared store across field logs,
;; species notes, articles, etc.
;;
;; Leader bindings (private context, via +citizen-science prefix bound to <leader>n):
;;   n s  new field session       n i  open inbox
;;   n I  import images           n r  review inbox (image-dired)
;;   n e  rename with EXIF dates  n f  link-and-finalize (primary close-out)
;;   n F  finalize only           n g  insert GPS link
;;   n l  insert inbox links      n c  insert link with caption
;;   n p  publish note            n P  publish and build
;;   n b  build website           n W  serve website
;;
;; Customize with M-x customize-group RET citizen-science RET

;;; Code:

;;;; Customization

(defgroup citizen-science nil
  "Citizen science field session tools."
  :group 'org
  :prefix "+cs/")

;;; Paths

(defcustom +cs/phone-import-path "~/Nextcloud/InstantUpload/"
  "Default source when importing photos from phone via Nextcloud sync.
Used as the initial directory suggestion in `+cs/import-images'."
  :type 'directory
  :group 'citizen-science)

(defcustom +cs/base-path "~/Documents/Cloud/CitizenScience/"
  "Root directory for citizen science notes and data (the denote silo)."
  :type 'directory
  :group 'citizen-science)

(defcustom +cs/inbox-path "~/Documents/Cloud/CitizenScience/inbox/"
  "Staging area for incoming field data (photos, scans, notes).
Files here are temporary: review, rename, then run `+cs/finalize-session'."
  :type 'directory
  :group 'citizen-science)

(defcustom +cs/media-path "~/Documents/Cloud/CitizenScience/media/"
  "Central image store shared across field logs, species notes, and articles.
Images are moved here from the inbox by `+cs/finalize-session'."
  :type 'directory
  :group 'citizen-science)

(defcustom +cs/website-path "~/Code/github.com/certainty/david.krentzlin.me/"
  "Root of the personal website repository.
Org notes are copied here by `+cs/publish-note' and built with `+cs/build-website'."
  :type 'directory
  :group 'citizen-science)

(defcustom +cs/publish-path "~/Code/github.com/certainty/citizenscience/public"
  "Output directory when publishing citizen science notes to HTML."
  :type 'directory
  :group 'citizen-science)

(defcustom +cs/publish-assets-path
  "~/Code/github.com/certainty/citizenscience/public/assets/images"
  "Output directory for static assets (images, PDFs) when publishing."
  :type 'directory
  :group 'citizen-science)

;;; File handling

(defcustom +cs/import-extensions
  '("jpg" "jpeg" "png" "heic" "cr2" "cr3" "nef" "raf" "arw" "dng" "pdf")
  "Extensions copied when importing from a camera or folder.
Includes PDF for scanned handwritten notes."
  :type '(repeat string)
  :group 'citizen-science)

(defcustom +cs/image-extensions
  '("jpg" "jpeg" "png" "heic" "cr2" "cr3" "nef" "raf" "arw" "dng")
  "Extensions treated as displayable images (subset of `+cs/import-extensions').
Used when inserting image links; PDFs are excluded."
  :type '(repeat string)
  :group 'citizen-science)

;;; Map links

(defcustom +cs/map-zoom 17
  "Default zoom level used when opening map links in the browser."
  :type 'integer
  :group 'citizen-science)

;;; Denote integration

(defcustom +cs/denote-keywords '("fieldlog" "observation" "wetland")
  "Keywords added to `denote-known-keywords' for citizen science notes."
  :type '(repeat string)
  :group 'citizen-science)

;;;; GPS link

(defun +cs/insert-image-gps-link (file)
  "Extract GPS coordinates from IMAGE FILE and insert an Org map link."
  (interactive "fSelect photo: ")
  (let* ((expanded (expand-file-name file))
          (cmd (format "exiftool -n -p '$GPSLatitude,$GPSLongitude' %s"
                 (shell-quote-argument expanded)))
          (output (string-trim (shell-command-to-string cmd))))
    ;; Validate output is two decimal numbers — guards against partial GPS data
    ;; (e.g. ",13.456" or "52.123,") and any exiftool error messages.
    (if (string-match
          "\\(-?[0-9]+\\(?:\\.[0-9]+\\)?\\),\\(-?[0-9]+\\(?:\\.[0-9]+\\)?\\)"
          output)
      (let ((coords (match-string 0 output)))
        (insert (format "[[map:%s][GPS: %s]]" coords (file-name-base file)))
        (message "Inserted GPS link."))
      (message "No valid GPS data found in %s" (file-name-nondirectory file)))))

;;;; Field session workflow

(defun +cs--importable-p (file)
  "Return t if FILE has an extension in `+cs/import-extensions'."
  (member (downcase (or (file-name-extension file) ""))
    +cs/import-extensions))

(defun +cs--inbox-images ()
  "Return displayable image files (see `+cs/image-extensions') in the inbox."
  (when (file-exists-p (expand-file-name +cs/inbox-path))
    (seq-filter (lambda (f)
                  (member (downcase (or (file-name-extension f) ""))
                    +cs/image-extensions))
      (directory-files (expand-file-name +cs/inbox-path) t nil t))))

(defun +cs--exif-datetime (file)
  "Return the EXIF DateTimeOriginal of FILE as an Emacs time value, or nil.
Returns nil when the file has no EXIF date or exiftool is unavailable."
  (let* ((cmd (format "exiftool -p '$DateTimeOriginal' -d '%%Y-%%m-%%d %%H:%%M:%%S' %s"
                (shell-quote-argument (expand-file-name file))))
          (raw (string-trim (shell-command-to-string cmd))))
    (when (string-match
            "\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\) \\([0-9]\\{2\\}\\):\\([0-9]\\{2\\}\\):\\([0-9]\\{2\\}\\)"
            raw)
      (encode-time
        (string-to-number (match-string 6 raw))
        (string-to-number (match-string 5 raw))
        (string-to-number (match-string 4 raw))
        (string-to-number (match-string 3 raw))
        (string-to-number (match-string 2 raw))
        (string-to-number (match-string 1 raw))))))

(defun +cs/dired-rename-marked-with-exif-dates ()
  "Rename marked dired files using the denote scheme with EXIF capture dates.
Prompts for keywords once (shared across all files) and title per file.
Falls back to the current time when a file has no EXIF date, with a warning."
  (interactive)
  (unless (derived-mode-p 'dired-mode)
    (user-error "This command must be run from a Dired buffer"))
  (let* ((files (dired-get-marked-files))
          (keywords (denote-keywords-prompt)))
    (dolist (file files)
      (let* ((exif-date (+cs--exif-datetime file))
              (date (or exif-date
                      (progn
                        (message "Warning: no EXIF date for %s, using current time"
                          (file-name-nondirectory file))
                        (current-time))))
              (title (denote-title-prompt
                       (file-name-base file)
                       (format "Title for %s" (file-name-nondirectory file)))))
        (denote-rename-file file title keywords nil date))))
  (revert-buffer))

(defun +cs/new-field-session ()
  "Create a denote field-log note in the CS silo and open the inbox alongside it.
Prompts for title and keywords; the fieldlog template is pre-selected."
  (interactive)
  (make-directory (expand-file-name +cs/inbox-path) t)
  (let ((denote-directory (expand-file-name +cs/base-path)))
    (denote
      (denote-title-prompt nil "Field session title")
      (denote-keywords-prompt)
      nil nil nil nil 'fieldlog))
  (dired-other-window (expand-file-name +cs/inbox-path)))

(defun +cs/open-inbox ()
  "Open the citizen science staging inbox in Dired."
  (interactive)
  (make-directory (expand-file-name +cs/inbox-path) t)
  (dired (expand-file-name +cs/inbox-path)))

(defun +cs/import-images (source-dir)
  "Copy importable files from SOURCE-DIR into the citizen science inbox.
Recognises extensions listed in `+cs/import-extensions'."
  (interactive
    (list (read-directory-name "Import from: "
            (expand-file-name +cs/phone-import-path))))
  (let* ((inbox (expand-file-name +cs/inbox-path))
          (files (seq-filter #'+cs--importable-p
                   (directory-files (expand-file-name source-dir) t nil t)))
          (count 0))
    (make-directory inbox t)
    (dolist (file files)
      (copy-file file inbox t)
      (cl-incf count))
    (message "Imported %d file(s) to inbox." count)
    (dired inbox)))

(defun +cs/review-inbox ()
  "Open the inbox in Dired with image thumbnails for culling.
Mark unwanted images with `d', then press `x' to delete them."
  (interactive)
  (let ((inbox (expand-file-name +cs/inbox-path)))
    (unless (file-exists-p inbox)
      (user-error "Inbox does not exist; run +cs/new-field-session first"))
    (dired inbox)
    (image-dired inbox)))

(defun +cs--caption-from-filename (file)
  "Derive a human-readable caption from a denote FILE name.
Extracts the title portion (between -- and __) and converts hyphens to spaces
with Title Case.  Falls back to the bare filename base for non-denote files."
  (let* ((base (file-name-base file))
          (title (if (string-match "--\\([^_]+\\)" base)
                   (match-string 1 base)
                   base)))
    (mapconcat #'capitalize (split-string title "-") " ")))

(defun +cs/insert-image-link-with-caption (file)
  "Insert a captioned Org image block for FILE.
The caption is derived from the denote title in the filename.  Inserts:

  #+caption: Title From Denote
  [[file:~/path/to/image.jpg]]"
  (interactive "fSelect image: ")
  (let* ((expanded (expand-file-name file))
          (caption (+cs--caption-from-filename expanded)))
    (insert (format "#+caption: %s\n[[file:%s]]\n"
               caption
               (abbreviate-file-name expanded)))))

(defun +cs/insert-inbox-image-links ()
  "Insert Org file links to all images currently in the inbox at point.
Run `+cs/finalize-session' afterwards to move images to the media store
and rewrite the links."
  (interactive)
  (let ((images (+cs--inbox-images)))
    (if (null images)
      (message "No images in inbox.")
      (dolist (img images)
        (insert (format "[[file:%s]]\n" img)))
      (message "Inserted %d image link(s)." (length images)))))

(defun +cs/finalize-session ()
  "Move all files from inbox to the central media store.
Rewrites any [[file:...]] links pointing into the inbox in the current buffer,
so you can insert links while reviewing and finalize in one step at the end."
  (interactive)
  (let* ((inbox (expand-file-name +cs/inbox-path))
          (media (expand-file-name +cs/media-path))
          (files (and (file-exists-p inbox)
                   (seq-remove #'file-directory-p
                     (directory-files inbox t directory-files-no-dot-files-regexp))))
          (moved '()))
    (unless files
      (user-error "Inbox is empty"))
    (make-directory media t)
    (dolist (file files)
      (let ((dest (expand-file-name (file-name-nondirectory file) media)))
        (rename-file file dest)
        (push (cons file dest) moved)))
    ;; Rewrite links in current buffer (handles both absolute and ~ forms)
    (when (and (buffer-file-name) moved)
      (save-excursion
        (dolist (pair moved)
          (dolist (old-form (list (car pair) (abbreviate-file-name (car pair))))
            (goto-char (point-min))
            (while (search-forward old-form nil t)
              (replace-match (abbreviate-file-name (cdr pair)) t t))))))
    (message "Moved %d file(s) to %s." (length moved) (abbreviate-file-name media))))

(defun +cs/link-and-finalize ()
  "Move all inbox files to the media store and insert captioned links at point.
Combines `+cs/insert-inbox-image-links' and `+cs/finalize-session' into one
atomic step: links are written directly to the final media path, so there is
nothing to rewrite afterwards."
  (interactive)
  (let* ((inbox (expand-file-name +cs/inbox-path))
          (media (expand-file-name +cs/media-path))
          (files (and (file-exists-p inbox)
                   (seq-remove #'file-directory-p
                     (directory-files inbox t directory-files-no-dot-files-regexp))))
          (linked 0))
    (unless files
      (user-error "Inbox is empty"))
    (make-directory media t)
    (dolist (file files)
      (let ((dest (expand-file-name (file-name-nondirectory file) media)))
        (rename-file file dest)
        (when (member (downcase (or (file-name-extension file) "")) +cs/image-extensions)
          (insert (format "#+caption: %s\n[[file:%s]]\n"
                    (+cs--caption-from-filename dest)
                    (abbreviate-file-name dest)))
          (cl-incf linked))))
    (message "Moved %d file(s), inserted %d image link(s)." (length files) linked)))

;;;; Website publishing

(defun +cs--website-content-dir (type)
  "Return the absolute content directory for TYPE (\\='fieldlog or \\='article)."
  (expand-file-name
    (if (eq type 'fieldlog) "content/fieldlogs" "content/writing")
    (expand-file-name +cs/website-path)))

(defun +cs/publish-note (type)
  "Copy the current org note into the website content directory for TYPE.
TYPE is prompted: fieldlog goes to content/fieldlogs/, article to content/writing/.

Note: images (file: links) and map: links require manual handling for now —
they will not resolve correctly in the published HTML until a copy+rewrite
step is added."
  (interactive
    (list (intern (completing-read "Publish as: " '("fieldlog" "article") nil t))))
  (let* ((file (or (buffer-file-name)
                 (user-error "Buffer is not visiting a file")))
          (_ (unless (string= (file-name-extension file) "org")
               (user-error "Only .org files can be published this way")))
          (dest-dir (+cs--website-content-dir type))
          (dest (expand-file-name (file-name-nondirectory file) dest-dir)))
    (make-directory dest-dir t)
    (copy-file file dest t)
    (message "Published to %s" (abbreviate-file-name dest))))

(defun +cs/build-website ()
  "Run make in the website repository to rebuild the site."
  (interactive)
  (let ((default-directory (expand-file-name +cs/website-path)))
    (compile "make")))

(defun +cs/serve-website ()
  "Run make serve in the website repository (Python HTTP server on port 8000)."
  (interactive)
  (let ((default-directory (expand-file-name +cs/website-path)))
    (compile "make serve")))

(defun +cs/publish-and-build (type)
  "Publish the current note to the website and trigger a full rebuild.
Combines `+cs/publish-note' and `+cs/build-website' in one step."
  (interactive
    (list (intern (completing-read "Publish as: " '("fieldlog" "article") nil t))))
  (+cs/publish-note type)
  (+cs/build-website))

;;;; Org link type: map (OpenStreetMap)

(defun +cs--map-url (lat lon)
  "Return an OpenStreetMap URL for LAT and LON at `+cs/map-zoom'."
  (format "https://www.openstreetmap.org/?mlat=%s&mlon=%s&zoom=%d"
    lat lon +cs/map-zoom))

(with-eval-after-load 'org
  (require 'ol)
  (org-link-set-parameters
    "map"
    :follow (lambda (coords)
              (let ((parts (split-string coords ",")))
                (browse-url (+cs--map-url (car parts) (cadr parts)))))
    :export (lambda (coords desc format)
              (let* ((parts (split-string coords ","))
                      (url (+cs--map-url (car parts) (cadr parts))))
                (pcase format
                  ('html (format "<a href=\"%s\">%s</a>" url (or desc coords)))
                  (_ coords)))))

  )

;;;; Publishing

(with-eval-after-load 'ox-publish
  (setq org-publish-project-alist
    `(("cs-notes"
        :base-directory ,+cs/base-path
        :base-extension "org"
        :publishing-directory ,+cs/publish-path
        :publishing-function org-html-publish-to-html
        :headline-levels 4
        :auto-preamble t
        :with-toc t
        :section-numbers nil)

       ("cs-static"
         :base-directory ,+cs/media-path
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|csv"
         :publishing-directory ,+cs/publish-assets-path
         :recursive t
         :publishing-function org-publish-attachment)

       ("cs" :components ("cs-notes" "cs-static")))))

;;;; Keybindings

(my/leader-bindings!
  (+citizen-science
    ("s" . (cons "New Session"          '+cs/new-field-session))
    ("i" . (cons "Open Inbox"           '+cs/open-inbox))
    ("I" . (cons "Import Images"        '+cs/import-images))
    ("r" . (cons "Review Inbox"         '+cs/review-inbox))
    ("e" . (cons "Rename EXIF Dates"    '+cs/dired-rename-marked-with-exif-dates))
    ("f" . (cons "Link and Finalize"    '+cs/link-and-finalize))
    ("F" . (cons "Finalize Only"        '+cs/finalize-session))
    ("g" . (cons "GPS Link"             '+cs/insert-image-gps-link))
    ("l" . (cons "Link Images"          '+cs/insert-inbox-image-links))
    ("c" . (cons "Link with Caption"    '+cs/insert-image-link-with-caption))
    ("p" . (cons "Publish Note"         '+cs/publish-note))
    ("P" . (cons "Publish and Build"    '+cs/publish-and-build))
    ("b" . (cons "Build Website"        '+cs/build-website))
    ("W" . (cons "Serve Website"        '+cs/serve-website))))

;;;; Denote integration

(with-eval-after-load 'denote
  (dolist (kw +cs/denote-keywords)
    (add-to-list 'denote-known-keywords kw)))

(provide 'citizen-science)
;;; citizen-science.el ends here
