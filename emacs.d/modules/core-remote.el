;;; core-remote.el --- TRAMP and remote development tuning -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Tuning for TRAMP to ensure remote development (especially in VMs or isolated
;; containers) is fast, reliable, and convenient.
;;
;;; Code:

(use-package tramp
  :straight (:type built-in)
  :custom
  ;; Use the fastest available connection method
  (tramp-default-method "ssh")
  ;; Keep auto-saves local to avoid remote latency
  (tramp-auto-save-directory (expand-file-name "tramp-autosave/" user-emacs-directory))
  ;; Use ControlMaster for SSH connection sharing (huge performance boost)
  (tramp-use-ssh-controlmaster-options t)
  ;; Increase verbosity slightly for debugging if needed, but keep it quiet normally
  (tramp-verbose 1)

  ;; PERFORMANCE: Cache remote connection details
  (remote-file-name-inhibit-cache nil)

  :config
  ;; FIX: Respect the remote's own PATH (from .bashrc / .zshrc)
  ;; This addresses the issue where tramp-remote-path is ignored or limited.
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path)

  ;; Add common binary locations as fallbacks
  (add-to-list 'tramp-remote-path 'tramp-default-remote-path)
  (add-to-list 'tramp-remote-path "/usr/local/bin"))

(provide 'core-remote)
;;; core-remote.el ends here
