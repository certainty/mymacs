# Mymacs is my personal emacs configuration

This is my personal emacs configuration, that is optimized for my workflows.
It is configured as a modern IDE, that has first class support to run toolchains in a remote machine, which
is pretty much a requirement these days, if you want to keep your development environment isolated from the host.
Supply chain risk is crazy nowadays.

## Main decisions

Emacs is a beast to configure the options are endless. That's why it's important to lock down some basal decisions, that keep me on track.
These basic rules have to be applied consistently.

- the config is kept in plain emacs lisp 
- the config is separated into modules, each bundling up functionality that is coherent within that module
- each module uses lexical scoping and uses `use-package` consistently
* the configuration aims to provide top-notch coding support + tools required to manage my work including writing docs, managing tasks, interacting with SaaS
  (this is not an e-mail client, this is not a multimedia system, this is not a game environment)
- dependencies are managed via straight, and we make use of version pins
* keybindings are the main interface to the system, and they have to be consistent and mnemonic
* stability, simplicity and minimalism are driving most decisions. we only configure what we actually use.


## Repository layout

- [doc](./doc) *in depth documentation for some aspects of the config*
* [scripts](./scripts/) *contains emacs-tool which provides common functionality to test the config and interact with an emacs configured for a certain profile* 
* [emacs.d](./emacs.d/) *current active profile. link this into `~/.emacs.d` to activate*


## System Requirements

To fully utilize the core features of this configuration, ensure the following command-line tools are installed on your system:

* **git**: Required for package management (straight.el) and version control (Magit).
* **ripgrep (`rg`)**: Required for fast project-wide searching (Consult/project.el).
* **git-delta (`delta`)**: Required for advanced syntax highlighting in Magit diffs (`magit-delta`).
* **difftastic (`difft`)**: Required for structural diffs within Magit (`difftastic`).
