# Mymacs is my personal emacs configuration

This is my personal emacs configuration, that is optimized for my workflows.
It is configured as a modern IDE, that has first class support to run toolchains in a remote machine, which
is pretty much a requirement these days, if you want to keep your development environment isolated from the host.
Supply chain risk is crazy nowadays.

## Main decisions

Emacs is a beast to configure the options are endless. That's why it's important to lock down some basal decisions, that keep me on track.
These basic rules have to be applied consistently.

- the config is kept in plain Emacs Lisp
- `init.el` requires coherent configuration modules explicitly, in dependency order
- each module uses lexical scoping and uses `use-package` consistently
* the configuration aims to provide top-notch coding support + tools required to manage my work including writing docs, managing tasks, interacting with SaaS
(this is not an e-mail client, this is not a multimedia system, this is not a game environment)
- dependencies are managed through `package.el` for ELPA packages; self-contained in-repo packages live under `emacs.d/user-lisp/`
- the appearance uses Emacs 31's built-in `modus-vivendi` theme, with local palette overrides
* keybindings are the main interface to the system, and they have to be consistent and mnemonic
* stability, simplicity and minimalism are driving most decisions. we only configure what we actually use.
