;;; writing-notes.el --- Note-taking with Denote -*- lexical-binding: t -*-

;;; Commentary:
;; Denote for note-taking with p-search and consult-notes integration

;;; Code:

(use-package tmr
  :bind
  (:map +do
    ("c" . tmr)
    ("C" . tmr-prefix-map))

  :custom
  (tmr-sound-file "/usr/share/sounds/freedesktop/streo/alarm-clock-elapsed.oga")
  (tmr-notification-urgency 'normal)
  (tmr-descriptions-list 'tmr-description-history))

(provide 'tools-tmr)
