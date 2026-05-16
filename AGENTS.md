# Agents heed my command


## Core Principles

This configuration aims to be:

* predictable
* stable
* inspectable
* debuggable
* composable
* minimal but not naive

You achieve that by:

* keeping close count of dependencies and only use the dependencies for workflows that are actually used
* you make use of default behaviour and functionality when appropriate
* you have one way to place the configuration (custom.el which is not checked-in), and all modules act on the settings defined there.

---

## Documentation-First Requirement

Never guess how Emacs or a package works. Use the documentation that comes with emacs. 
./scripts/emacs-tools can be used to interact with emacs with support for different configuration roots.

Use:

* `emacs-tools describe-function <symbol>` -- pass `EMACS_CONFIG_ROOT` to load the profile's packages for third-party symbol inspection
* `emacs-tools describe-variable <symbol>` -- pass `EMACS_CONFIG_ROOT` to load the profile's packages for third-party variable inspection
* `emacs-tools find-library <name>` -- pass `EMACS_CONFIG_ROOT` to locate packages installed by the profile
* `emacs-tools manual emacs`
* `emacs-tools manual elisp`
* `emacs-tools eval "<elisp>"` -- for checking values or behavior at runtime

When inspecting third-party packages (straight.el packages, modules not in base Emacs), always set `EMACS_CONFIG_ROOT` to the profile directory so the package is loaded before inspection. Without it, only built-in symbols are available.

Example:
```bash
EMACS_CONFIG_ROOT=emacs.d emacs-tools describe-variable corfu-auto
EMACS_CONFIG_ROOT=emacs.d emacs-tools describe-function vertico-mode
EMACS_CONFIG_ROOT=emacs.d emacs-tools find-library mood-line
```

For built-in Emacs symbols, omit `EMACS_CONFIG_ROOT` (uses `-Q`).

Configuration **MUST** be grounded in:

* official documentation
* package documentation
* actual source behavior

**Do not** invent APIs.
**Do not** cargo-cult configuration snippets.

---

## Validation Requirements

After every meaningful change, run validation commands.

Required checks:

```bash id="jlwmm1"
EMACS_CONFIG_ROOT=emacs.d ./script/emacs-tools  doctor
```

For targeted checks:

```bash id="o67z1k"
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools check-parens path/to/file.el
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools byte-compile path/to/file.el
```

---

## Modules

### File Naming

Modules follow:

```text id="iwh0qt"
<namespace>-<module>.el
```

Examples:

```text id="2ffjxs"
core-editing.el
core-keys.el
dev-scala.el
dev-ruby.el
```

Avoid:

* giant monolithic files
* deeply nested module hierarchies
* framework-style conventions

### Module conventions

* use lexical scope for all modules
* use consistent headers and footers
* modules are loaded explicitly via init.el

---

## Configuration Topology

`core-config.el` is authoritative.

It defines:

* user-facing configuration values
* feature toggles
* environment assumptions
* platform assumptions

Conditional logic depends on values defined there.

Avoid:

* scattered global defcustoms
* implicit feature detection everywhere
* duplicated condition checks

---

## Package Management

All packages are configured via:

[use-package](https://github.com/jwiegley/use-package?utm_source=chatgpt.com)

Requirements:

* lazy load whenever possible
* defer loading aggressively
* avoid eager startup work
* avoid global mode activation unless necessary

Use:

* `:hook`
* `:commands`
* `:bind`
* `:mode`
* `:init`
* `:config`

appropriately.


Avoid:

* unconditional `require`
* startup-time package initialization
* global side effects

---

## Keybinding Philosophy

Keybindings are the primary interface for the user and any change to keybindings **MUST** be approved by the user.
Keymaps are defined centrally, while bindings in the maps might be done in modules.
The config uses meow and a leader bases system that uses mnemonic semantic grouping.

Pattern:

```text id="djlwmm"
core-keymaps.el
```

Named maps are then referenced from `use-package`.

Avoid:

* inline anonymous binding definitions everywhere
* duplicated binding logic
* scattered leader configuration

---

## UI / Layout Philosophy

Primary target:

* widescreen displays
* stable spatial layouts
* predictable buffer placement

Requirements:

* popup behavior must be deterministic
* windows should appear consistently
* transient buffers should reuse known locations
* avoid disruptive window splitting

Prefer:

* side windows
* reusable window slots
* explicit display-buffer rules

Avoid:

* uncontrolled popup behavior
* random vertical splits
* layout instability

The UI should support:

* persistent coding sessions
* debugger workflows
* terminal workflows
* remote development via TRAMP

---

## Remote / TRAMP Requirements

Packages must be evaluated for TRAMP compatibility.

Prefer packages that:

* use standard Emacs file APIs
* support remote subprocess execution
* avoid excessive filesystem polling
* avoid local-only assumptions

Avoid packages that:

* recursively scan large trees unnecessarily
* depend heavily on file watchers
* assume local POSIX semantics

Remote workflows are first-class.

Expected workflows:

* remote LSP
* remote debugging
* remote terminals
* remote AI agents
* remote git
* remote project navigation

---

## Language Support Priorities

Primary languages:

* Scala
* Ruby
* Go

Required:

* Eglot integration
* Dape integration
* formatting
* project-aware workflows
* debugger support

Preferred tools:

* [Eglot](https://elpa.gnu.org/packages/eglot.html?utm_source=chatgpt.com)
* [Dape](https://github.com/svaante/dape?utm_source=chatgpt.com)

---

## Duplication Elimination

Actively identify duplicated workflows.

If functionality already exists through:

* built-in Emacs
* project.el
* xref
* consult
* embark
* dired
* eglot

prefer extending the existing workflow instead of introducing a new package.

Examples:

* avoid separate search frameworks
* avoid separate project frameworks
* avoid separate action systems
* avoid duplicate popup systems

The configuration should converge toward fewer concepts over time.

