.PHONY: tangle bootstrap dependencies emacs

TANGLE_SRC := config.org
SCOPE := private # the scope of this config which can be either private or work
PLATFORM := (shell uname)

tangle: clean
	@echo "Tangling configuration file $(TANGLE_SRC)"
	@emacs --batch --eval "(require 'org)" --eval "(org-babel-tangle-file \"$(TANGLE_SRC)\")"

bootstrap: emacs dependencies

emacs:
	ifeq ($(PLATFORM),Darwin)
		@brew install emacs-plus --with-imagemagick --with-modern-sexy-v2-icon
	endif

dependencies:
	ifeq (($PLATFORM),Darwin)
		@brew install direnv ripgrep fzf fs fd pandoc graphviz font-iosevka-aile font-iosevka-nerd-font
	endif

clean:
	rm -rf ./modules/*
	rm -rf ./lisp/*
