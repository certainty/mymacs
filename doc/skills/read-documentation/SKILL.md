---
name: read-documentation
description: use whenever you need to change or add functionality, to make sure you don't guess but make grounded decisions based on the available documentation.
---

## Purpose

It is vitally important, that you verify assumptions about how to configure a certain part of the systems.
To do that you use the available documentation. 


## Workflow

* The [emacs-tools](../../../scripts/emacs-tools) script provides access to in-emacs configuration
* Invoke it with --help to learn what is available
* The most important commands are:
  - describe-function
  * describe-variable
  * find-library
  * manual
* For more elaborate testing you can use `eval` to run arbitrary code in the emacs instance.
* If you don't find the required documentation, you use the online search to find out more, but you make sure that versions match what is used here.

