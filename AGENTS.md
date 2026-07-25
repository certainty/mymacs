# Agents heed my command

## Core Principles

This configuration aims to be:

- predictable
- stable
- inspectable
- debuggable
- composable
- minimal but not naive

You achieve that by:

- keeping close count of dependencies and only use the dependencies for workflows that are actually used
- you make use of default behaviour and functionality when appropriate
- you have one way to place the configuration (custom.el which is not checked-in), and all modules act on the settings defined there.

---

## Config files

You must keep all configuration in `init.el` and `early-init.el`.
We do this intentionaly to create friction when the file gets too large.
Custom code, that is not configuration goes into `user-lisp` directory.
This is autoloaded with emacs-31.

Use outline headers to separate functionality.

## Packages

IMPORTANT: use only GNU Elpa and NONGNU Elpa and MELPA for additional packages by default.
Prefer GNU ELPA when a package exists in both archives. NonGNU ELPA is the secondary choice.

Only add ensure, when you need to pull the source from a package archive.

All packages are pinned to GNU by default.
If you need a package from a different archive add an exlicit pin.

### use-package use of keywords

Use of use-package

All uses of use-package put the options into the same order which is defined melow.
If an option doesn't apply the order resumes with the next one.

- :if / :unless
- :ensure
- :demand
- :pin
- :mode
- :hook
- :commands
- :bind
- :custom
- :preface
- :init
- :config

---

## Documentation-First Requirement

Never guess how Emacs or a package works. Use the documentation that comes with emacs.
./scripts/emacs-tools can be used to interact with Emacs. `emacs.d` is live config in this repo. `EMACS_CONFIG_ROOT` exists so scripts can also target other config roots when needed.

Use:

- `emacs-tools describe-function <symbol>` -- pass `EMACS_CONFIG_ROOT` to load packages from that config root for third-party symbol inspection
- `emacs-tools describe-variable <symbol>` -- pass `EMACS_CONFIG_ROOT` to load packages from that config root for third-party variable inspection
- `emacs-tools find-library <name>` -- pass `EMACS_CONFIG_ROOT` to locate packages installed for that config root
- `emacs-tools manual emacs`
- `emacs-tools manual elisp`
- `emacs-tools eval "<elisp>"` -- for checking values or behavior at runtime

When inspecting third-party packages, always set `EMACS_CONFIG_ROOT` to config root so package is loaded before inspection. In this repo that is usually `emacs.d`. Without it, only built-in symbols are available.

Example:

```bash
EMACS_CONFIG_ROOT=emacs.d emacs-tools describe-variable corfu-auto
EMACS_CONFIG_ROOT=emacs.d emacs-tools describe-function vertico-mode
EMACS_CONFIG_ROOT=emacs.d emacs-tools find-library mood-line
```

For built-in Emacs symbols, omit `EMACS_CONFIG_ROOT` (uses `-Q`).

Configuration **MUST** be grounded in:

- official documentation
- package documentation
- actual source behavior

**Do not** invent APIs.
**Do not** cargo-cult configuration snippets.

---

## Validation Requirements

After every meaningful change, run validation commands.

Required checks:

```bash id="jlwmm1"
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools doctor
```

For targeted checks:

```bash id="o67z1k"
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools check-parens path/to/file.el
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools byte-compile path/to/file.el
```

After byte-compilation or `doctor`, delete generated `.elc` files such as
`emacs.d/init.elc`. Stale bytecode can hide source changes and cause load-order bugs.

---

## Keybinding Philosophy

Keybindings are the primary interface for the user and any change to keybindings **MUST** be approved by the user.
We only bind what we actually need.
We make use of semantic maps like search-map and goto-map.
For custom bindings we use the C-c prefix in the appropriate mode-map or mymacs-mode-map if it should be global.

Avoid:

- inline anonymous binding definitions everywhere
- duplicated binding logic
- scattered leader configuration

---

## UI / Layout Philosophy

Primary target:

- widescreen displays
- stable spatial layouts
- predictable buffer placement

Requirements:

- popup behavior must be deterministic
- windows should appear consistently
- transient buffers should reuse known locations
- avoid disruptive window splitting

Prefer:

- side windows
- reusable window slots
- explicit display-buffer rules

Avoid:

- uncontrolled popup behavior
- random vertical splits
- layout instability

---

## Language Support Priorities

Primary languages:

- Scala
- Ruby
- Go

Required:

- Eglot integration
- formatting
- project-aware workflows
- debugger support where appropriate

Preferred tools:

- [Eglot](https://elpa.gnu.org/packages/eglot.html?utm_source=chatgpt.com)
- [Dape](https://github.com/svaante/dape?utm_source=chatgpt.com)
