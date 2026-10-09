;;; my-search.el --- Interactive search and Consult -*- lexical-binding: t; -*-


;;; Search
(defun my/consult-ripgrep ()
  "Search with ripgrep, using the active region as the initial query."
  (interactive)
  (consult-ripgrep nil
                   (when (use-region-p)
                     (buffer-substring-no-properties
                      (region-beginning) (region-end)))))

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

(use-package avy
  :ensure t
  :commands (avy-goto-word-0)
  :bind
  (:map goto-map
        ("c" . avy-goto-char)
        ("w" . avy-goto-word-1))
  :custom
  (avy-all-windows nil))

(use-package consult
  :ensure t
  :bind
  (:map my/leader-map
        ("b" . consult-project-buffer)
        ("B" . consult-buffer)
        ("s" . consult-imenu)
        ("S" . consult-imenu-multi)
        ("/" . my/consult-ripgrep)
        ("d" . consult-flymake))
  (:map my/open-prefix-map
        ("o" . consult-recent-file))
  (:map goto-map
        ("b" . consult-project-buffer)
        ("o" . consult-recent-file)
        ("r" . consult-bookmark)
        ("i".  consult-imenu)
        ("m" . consult-mark)
        ("d" . consult-flymake))
  (:map search-map
        ("/" . my/consult-ripgrep)
        ("v" . consult-git-grep))
  :config
  (with-eval-after-load 'outline
    (keymap-set outline-minor-mode-map "C-c O" #'consult-outline)))

(use-package avy
  :ensure t
  :commands (avy-goto-word-0)
  :bind
  (:map search-map
        ("w" . avy-goto-word)
        ("C" . avy-goto-char-timer))
  :custom
  (avy-all-windows nil))


(provide 'my-search)
;;; my-search.el ends here
