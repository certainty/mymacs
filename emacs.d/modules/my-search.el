;;; my-search.el --- Interactive search and Consult -*- lexical-binding: t; -*-

(defvar outline-minor-mode-map)

;;; Search
(use-package isearch
  :hook (occur-mode . hl-line-mode)
  :bind
  (:map isearch-mode-map
        ("C-g" . isearch-cancel))
  :custom
  (isearch-lax-whitespace t)
  (isearch-regexp-lax-whitespace nil)
  (search-highlight t)
  (isearch-lazy-highlight t)
  (isearch-lazy-highlight-initial-delay 0.5)
  (isearch-highlight-no-delay-length 4)
  (isearch-lazy-count t)
  (lazy-count-prefix-format "(%s/%s) ")
  (lazy-count-suffix-format nil)
  (isearch-wrap-pause t)
  (isearch-repeat-on-direction-change t))

(use-package consult
  :ensure t
  :bind
  (:map my/leader-map
        ("b" . consult-project-buffer)
        ("B" . consult-buffer)
        ("s" . consult-imenu)
        ("S" . consult-imenu-multi)
        ("/" . consult-ripgrep)
        ("d" . consult-flymake))
  (:map my/open-prefix-map
        ("o" . consult-recent-file))
  (:map goto-map
        ("b" . consult-project-buffer)
        ("o" . consult-recent-file)
        ("r" . consult-bookmark)
        ("i".  consult-imenu)
        ("M" . consult-mark)
        ("d" . consult-flymake))
  (:map search-map
        ("/" . consult-ripgrep)
        ("v" . consult-git-grep))
  :config
  (with-eval-after-load 'outline
    (keymap-set outline-minor-mode-map "C-c O" #'consult-outline)))

;; wgrep no longer needed, since emacs 31 has grep-edit-mode

(provide 'my-search)
;;; my-search.el ends here
