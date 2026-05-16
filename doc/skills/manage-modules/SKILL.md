---
name: manage-modules
description: use when you need to add, update, delete modules in the emacs configuration
---

## Rules

* modules group related functionality into one place, that makes them easy to find for the user
* module names follow the convention of <namespace>-<aspect>.el. Example core-keys.el, core-config.el, dev-scala.el


## Code conventions

* Modules follow a consistent template:
    Example:
    ```elisp
    ;;; module-name.el --- description -*- lexical-binding: t; -*-
    ;;
    ;;; Commentary:
    ;;
    ;; Provide comments that describe the unit of configuration 
    ;;
    ;;; Code:

    ;; the code
    (provide 'module-name)
    ```

* modules use `use-package` consistently and utilize lazy loading facilities when appropriate
* modules are kept simple, and prefer builtin functionality over third party dependencies if appropriate
* modules configure only what needs to be configured, and otherwise use defaults
* modules are documented and sections within modules are preceded by documentation lines, that also serve as navigation in imenu mode
* custom utility functions follow a naming convention:
  * interactive commands are prefixed with `+` (e.g. `+format-buffer`, `+split-vertically`)
  * non-interactive user-defined functions are prefixed with `my/` (e.g. `my/reset-gc`, `my/enable-font-ligatures`)

## Creating functionality

* the agent must always consult the documentation for the configuration in question. it uses `emacs-tool` to interact with a local emacs instance. It can also use online documentation for cases where `emacs-tool` is not sufficient.
* the agent must decide the simplest but not naive way to provide the functionality.
* all code is optimized for agent and human understanding

## Loading and configuration

* all modules are loaded explicitly from `init.el`
* core-config.el provides all customizable variables and this is the only place where they are defined.
* all conditional activation of features happens based on the above mentions customizables. 
* custom.el will be used ultimately to set those customizables. the user will manage that file via chezmoi, and it must not be checked into the repository. however we provide a custom-example.el.

## Success criteria

* all checks pass most importantly `emacs-tool doctor`, `emacs-tool byte-compile`. additional checks are applied on a case by case basis
* the module has clear boundaries, is well documented and has a reason to be. There is no overlapping functionality with other modules.

## Output

When a module has been created or updated use the following template to report

Name: module-name
Changes:
  - change1
  - change2
Decisions made:
  * decision1
  * decision2
Check: <command to check for the user to execute>
