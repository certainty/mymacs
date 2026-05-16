---
name: manage-keys
description: use when you need to add or change keybindings in the emacs configuration. 
---

## Purpose

This skill is used to apply keybinding changes that are consistent and follow the rules of the configuration.

## Meta

The keymaps are the main interface for the user to the system. Making significant changes, can disrupt the users
productivity. The user has muscle memory of the bindings which the user aims to keep in tact where possible.

## Rules

* All keymaps are defined in a single place in core-keys.el
* Individual modules can bind keys into the predefined prefix-keymaps
* Keybindings for global actions use the meow leader key map
* Keybindings in the leader keymap follow the convention of <context> <action>
  - Examples are:
    - +Buffer find
    - +Window close
    * +Project find
    * +Project remote find
* High frequency keybindings are placed directly into the leader keymap without semantic prefix
* Keybindings try to be mnemonic
* To preserve Meow's Keypad mode (god-mode like functionality), the following keys are left unbound in the leader map:
   - x (C-x)
   - c (C-c)
   - h (C-h)
   - m (M-)
   - g (C-M-)
* Leader keys are used for global actions primarily, while buffer local or even point local actions are dispatched to embark or other bindings.

## Workflow

* Pick the correct context for the binding. If no context exists yet, propose a new context and ask the user for confirmation.
* Chose a fitting mnemonic and place it in the map
* If an action exists for different scopes, like buffer and project scope we follow the convention, that they tend to get the same key, but differ in casing. Uppercase letters are for the wider scope while lower case letters are for the smaller scope.
  Example:
   - l s => buffer symbols
   * l S => project symbols
