;; -*- lexical-binding: t; -*-

(setq load-prefer-newer t)

(push '(undecorated . t) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)

(with-no-warnings
    (setq native-comp-async-report-warnings-errors 'silent
          native-comp-jit-compilation (not noninteractive)
          native-comp-async-jobs-number (max 2 (1- (num-processors)))
          native-comp-speed 2
          native-comp-prune-cache t))

