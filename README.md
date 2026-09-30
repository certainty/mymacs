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
* keybindings are the main interface to the system, and they have to be consistent and mnemonic
* stability, simplicity and minimalism are driving most decisions. we only configure what we actually use.


## Repository layout

- [doc](./doc) *in depth documentation for some aspects of the config, including package workflows*
* [scripts](./scripts/) *contains `emacs-tools`, which tests config and interacts with Emacs. It uses `emacs.d` by default here, but still supports other config roots via `EMACS_CONFIG_ROOT`.*
* [emacs.d](./emacs.d/) *live config. Link this into `~/.emacs.d` to activate.*

Within `emacs.d`, `early-init.el` handles early startup. `init.el` declares custom settings, loads the untracked `custom.el`, sets package policy, and requires feature modules in order. `modules/` contains all feature configuration (including Meow and its Helix-style helpers); `init.el` adds it to `load-path` and explicitly requires each module. Modules provide their named feature and are not loaded automatically by directory name. `user-lisp/` contains self-contained packages such as PMD and the `user-lisp/taskwarrior/` package (UI entry point plus core); language-specific commands live in their language modules, while helpers shared across modules may live in `user-lisp/`. Emacs 31 byte-compiles `user-lisp` sources when needed and generates autoloads, but does not evaluate every file at startup. `user-lisp/taskwarrior/taskwarrior.el` is the lazy-loaded UI entry point and requires `taskwarrior-core.el` when first loaded; `use-package taskwarrior` and `use-package consult-pmd` configure the corresponding libraries without installing them from an archive. `vendor/` contains copied third-party source.

The order of `require` calls in `init.el` is intentional: `my-windows` provides layout helpers used by `my-terminal`, `my-files` loads alternate-file mappings used by the Ruby and Scala modules, and `my-modal-editing` runs last so its Meow setup can use commands and keymaps configured earlier. `my-programming` requires the language modules at their respective language sections.

## Keybindings

The configuration uses Meow as the main modal editing layer. Normal text buffers start in Meow normal state.

### Leader

The global leader is `C-j`.
Inside Meow keypad mode the same leader map is available on `SPC`.

Common leader bindings:

- `C-j f` / `SPC f` - `project-find-file`
- `C-j F` / `SPC F` - `find-file`
- `C-j e` / `SPC e` - `project-dired`
- `C-j b` / `SPC b` - `consult-project-buffer`
- `C-j B` / `SPC B` - `consult-buffer`
- `C-j o` / `SPC o` - `consult-recent-file`
- `C-j /` / `SPC /` - `consult-ripgrep`
- `C-j s` / `SPC s` - `consult-imenu`
- `C-j S` / `SPC S` - `consult-imenu-multi`
- `C-j d` / `SPC d` - `consult-flymake`
- `C-j D` / `SPC D` - `flymake-show-project-diagnostics`
- `C-j a` / `SPC a` - `eglot-code-actions`
- `C-j r` / `SPC r` - `eglot-rename`
- `C-j h` / `SPC h` - `xref-find-references`
- `C-j k` / `SPC k` - `eldoc`
- `C-j p` - `project-switch-project`
- `C-j v` - `project-vc-dir`
- `C-j c` - `project-compile`
- `C-j t` - toggle the dedicated Taskwarrior TUI
- `C-j $` - `eat`
- `C-j w a` - select any visible window, including transient side windows
- `C-j j j` - open the zk notebook scratch note
- `C-j j e` - open the zk notebook in Dired
- `C-j j f` - find a file in the zk notebook with Consult
- `C-j j /` - search the zk notebook with Consult ripgrep

### Meow normal state

The Meow layer is intentionally close to Helix in a few high-value places.

Core movement and editing:

- `h j k l` - left, down, up, right
- `w` - mark word
- `W` - mark symbol
- `b` / `B` - back word / back symbol
- `e` / `E` - next word / next symbol
- `i` / `I` - insert / insert at indentation
- `a` / `A` - append / append at end of line
- `c d y p u` - change, kill, save, yank, undo
- `x` / `X` - line, delete
- `o` / `O` - open below, open above
- `v` / `V` - expand-region expand / contract

Search and local navigation:

- `/` / `?` - search forward / backward
- `n` / `N` - repeat search forward / backward
- `f` / `F` - find forward / backward
- `t` / `T` - till forward / backward
- `(` / `)` - backward sexp / forward sexp

Prefix maps:

- `g` - goto map
- `m` - match map

`g` map:

- `g` / `e` - beginning / end of buffer
- `h` / `l` - beginning / end of line
- `s` - first non-whitespace on line
- `t` / `c` / `b` - top / center / bottom of window
- `d` / `D` - definition / declaration
- `y` / `r` / `i` - type definition / references / implementation
- `a` - alternate file
- `n` / `p` - next / previous buffer

`m` map:

- `m` - jump to matching delimiter
- `a` - bounds of thing
- `i` - inner of thing
- `s` - wrap selection with a typed delimiter

### Mode exceptions

Meow is intentionally disabled in:

- `vc-dir-mode`

Those modes already use unmodified keys for their own modal interfaces and should not be shadowed.


## System Requirements

To fully utilize the core features of this configuration, ensure the following command-line tools are installed on your system:

* **Emacs 31+**: Required by the active configuration in `emacs.d`.
* **git**: Required for version control and Magit.
* **ripgrep (`rg`)**: Required for fast project-wide searching (Consult/project.el).
* **git-delta (`delta`)**: Required for advanced syntax highlighting in Magit diffs (`magit-delta`).
* **difftastic (`difft`)**: Required for structural diffs within Magit (`difftastic`).
