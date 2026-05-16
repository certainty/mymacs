---
name: verify-configuration 
description: use whenever you change or add lisp code in this configuration. use it also as part of the final hand-off after a change
---


## Workflow

* The [emacs-tools](../../../scripts/emacs-tools) script provides access to in-emacs configuration
* Invoke it with --help to learn what is available
* Use the following subcommands:
  - `debug` to start with `--debug-init`
  * `batch-load` to load a file in batch mode
  * `check-parens` to make sure the file has balanced parens
  * `native-compile` to make sure the file compiles
  * `byte-compile` to make sure all forms are correct and bound

* make sure you use the correct profile path via `EMACS_CONFIG_ROOT`

