;;; my-task.el --- Task management -*- lexical-binding: t; -*-

;;;; Taskwarrior
(use-package taskwarrior
  :commands (+taskwarrior-list +taskwarrior-report
                               +taskwarrior-list-select-report taskwarrior-list-add
                               taskwarrior-list-dispatch)
  :bind
  (:map my/taskwarrior-prefix-map
        ("t" . +taskwarrior-list)
        ("R" . +taskwarrior-list-select-report)
        ("a" . taskwarrior-list-add))
  :load-path "user-lisp/taskwarrior")

(provide 'my-tasks)
