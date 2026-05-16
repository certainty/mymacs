---
name: config-prune
description: use to simplify the configuration, remove duplicate concepts and superflous settings. Identify overlapping functionality and excess complexity. Reduce cognitive burden to understand configuration.
---


## Purpose

This skill is used to systematically reduce configuration complexity by:

* analyzing existing Emacs configuration files
* mapping behavior to actual workflows in use
* comparing implementation against desired architectural principles
* eliminating redundancy, over-engineering, and duplication
* replacing complex constructs with simpler core Emacs equivalents when possible

The goal is continuous convergence toward minimal, predictable configuration.

---

## Inputs

The agent operates on:

* full configuration file set
* `base-config.el` as authoritative intent source
* current workflow inventory (explicit or inferred)
* validation tools (`emacs-tools doctor`, byte-compile, batch-load)
* documentation commands (describe-function, find-library, manual)

---

## Core Method

### 1. Inventory Phase

For each file:

* list all packages used
* list all custom functions
* list all hooks and advices
* list all keybindings
* identify external dependencies
* identify overlapping functionality

Each element must be mapped to a user-facing workflow.

No element is allowed to remain unclassified.

---

### 2. Workflow Extraction

Derive a set of actual workflows from the configuration.

Examples:

* file navigation workflow
* project navigation workflow
* completion workflow
* search workflow
* LSP workflow
* debugging workflow
* terminal workflow
* remote workflow (TRAMP)
* org workflow

Each workflow must answer:

* what task does this enable?
* what packages implement it?
* what core Emacs features overlap with it?
* how is it triggered by the user?

If a configuration element does not contribute to a workflow, it is considered dead weight.

---

### 3. Redundancy Detection

Identify:

* multiple packages solving the same problem
* overlapping keybinding systems
* duplicated project abstractions
* redundant completion layers
* multiple popup/window managers
* competing LSP or navigation stacks

For each redundancy, determine:

* simplest available implementation
* whether Emacs core already solves the problem
* whether removal reduces cognitive load

---

### 4. Complexity Scoring

Each subsystem is scored:

* 0 = core Emacs functionality
* 1 = minimal package extension
* 2 = moderate abstraction layer
* 3 = heavy framework or multi-component system

Target state:

* average complexity ≤ 1.5 per workflow

Any subsystem above threshold must be simplified unless strongly justified.

---

### 5. Simplification Pass

For each identified complexity:

Replace with:

* built-in Emacs functionality if possible
* single-package solution instead of multi-package stack
* direct API usage instead of abstraction layers
* default configuration instead of custom logic

Rules:

* remove before adding
* prefer deletion over refactoring
* prefer default behavior over customization
* prefer composition over framework replacement

---

### 6. Validation Loop

After each modification:

Run:

```bash id="c1v9qa"
emacs-tools doctor
```

Then optionally:

* byte compilation checks
* parens checks
* startup validation

No change is considered complete without passing validation.

---

## Constraint Alignment

All changes must preserve:

* TRAMP compatibility
* eglot-based LSP workflows
* dape debugging workflows
* meow-based keybinding system
* use-package-based configuration structure
* base-config.el-driven conditional logic
* widescreen-friendly UI layout rules

If simplification breaks any of these, it is rejected.

---

## Preferred Simplification Strategies

### Replace frameworks with core Emacs

* project frameworks → project.el
* search frameworks → consult + ripgrep
* UI frameworks → display-buffer rules
* completion frameworks → built-in + consult stack

---

### Merge duplicate workflows

If two tools provide similar behavior:

* keep the simpler one
* remove the more configurable one
* preserve user-facing commands via aliases if needed

---

### Collapse abstraction layers

If a workflow uses:

* wrapper functions
* custom dispatch layers
* intermediate state systems

replace with:

* direct function calls
* hooks
* standard Emacs primitives

---

## Documentation Requirement

Every workflow must be explicitly documented.

A workflow entry must include:

* name
* purpose
* entry points (commands / keybindings)
* underlying implementation (packages or core features)
* remote compatibility status (TRAMP-safe or not)
* complexity score

---

## Workflow Registry Format

Maintain a single registry file:

```text id="w0k2c1"
workflow-registry.el
```

Example structure:

```elisp id="q9v1x2"
;; completion-workflow
;; entry: consult-completion, project-find-file
;; backend: consult + orderless + project.el
;; complexity: 1
;; tramp-safe: yes
```

This registry is the source of truth for pruning decisions.

---

## Anti-Patterns to Eliminate

* IDE-style monolithic frameworks
* duplicate project systems
* multiple completion engines
* custom caching layers over Emacs core
* unnecessary minor modes
* global advice chains
* hidden state machines
* UI systems that override Emacs layout logic

---

## Output Requirements

The agent must produce:

* list of removed components
* simplified replacements
* affected workflows
* updated workflow registry
* validation results

No silent changes are allowed.

---

## Success Criteria

A pruning operation is successful if:

* fewer packages are used
* workflows are preserved or simplified
* startup complexity is reduced
* TRAMP behavior remains stable
* no loss of core functionality
* configuration becomes more predictable

Long-term goal:

A configuration that can be understood entirely through:

* Emacs core documentation
* a small set of well-chosen packages
* explicit workflow descriptions

```
```

