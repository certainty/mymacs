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


## Repository layout

- [doc](./doc) *in depth documentation for some aspects of the config, including package workflows*
* [scripts](./scripts/) *contains `emacs-tools`, which tests config and interacts with Emacs. It uses `emacs.d` by default here, but still supports other config roots via `EMACS_CONFIG_ROOT`.*
* [emacs.d](./emacs.d/) *live config. Link this into `~/.emacs.d` to activate.*

yWithin `emacs.d`, `early-init.el` handles early startup. `init.el` declares custom settings, loads the untracked `custom.el`, sets package policy, and requires feature modules in order. `modules/` contains feature configuration; `init.el` adds it to `load-path` and explicitly requires each module. Modules provide their named feature and are not loaded automatically by directory name. `user-lisp/` contains self-contained packages such as PMD and the `user-lisp/taskwarrior/` package (UI entry point plus core); language-specific commands live in their language modules, while helpers shared across modules may live in `user-lisp/`. Emacs 31 byte-compiles `user-lisp` sources when needed and generates autoloads, but does not evaluate every file at startup. `user-lisp/taskwarrior/taskwarrior.el` is the lazy-loaded UI entry point and requires `taskwarrior-core.el` when first loaded; `use-package taskwarrior` and `use-package consult-pmd` configure the corresponding libraries without installing them from an archive. `vendor/` contains copied third-party source.

The order of `require` calls in `init.el` is intentional: `my-windows` provides layout helpers used by `my-terminal`, `my-files` loads alternate-file mappings used by the Ruby and Scala modules, and `my-programming` requires the language modules at their respective language sections.

## Keybindings

Editing uses Emacs's standard non-modal point-and-region model. `C-j` is the global command leader; it is not duplicated on `SPC`.

### Editing and selection

- `C-s` / `C-r` - incremental search forward / backward
- `C-M-f` / `C-M-b` - move forward / backward across sexps
- `C-M-SPC` and `M-j` - `easy-mark` selection (remapped from `mark-sexp`)
- `M-w` - `easy-kill` (remapped from `kill-ring-save`)
- `C-=` / `C--` - expand / contract the active region with `expreg`
- `M-^` - join the current line with the previous line using `delete-indentation`
- `M-x my/match-pair` - jump to a matching delimiter or string boundary
- `M-x embrace-add`, `M-x embrace-change`, `M-x embrace-delete` - add, change, or remove surrounding pairs; `embrace-add` uses an active region when one is set
- `C-c e` - Embrace dispatcher: `a` adds, `c` changes, and `d` deletes surrounding pairs (for `(foo)` to `[foo]`, press `C-c e c ( [` with point inside)

### Navigation and windows

- `C-v` / `M-v` - scroll forward / backward by a screen
- `C-j w n` / `C-j w p` - scroll forward / backward by half a window
- `C-l` - cycle the current line between center, top, and bottom of the window
- `M-r` - move point between center, top, and bottom of the window
- `M-<` / `M->` - beginning / end of buffer; `C-a` / `C-e` - beginning / end of line; `M-m` - first non-whitespace character
- `C-c [` - undo the last window configuration change with Winner; `C-c <right>` - redo it
- `C-x {` / `C-x }` - shrink / enlarge the selected window by five columns or lines, following its immediate split; a numeric prefix overrides five. With Repeat mode, repeat using `{` / `}`.
- `M-g n b` / `M-g p b` - next / previous buffer

Winner restores window configurations, not a linear history of buffer switches.

### Embark

- `C-.` - `embark-act`
- `C-,` - `embark-dwim`
- `C-c .` / `C-c ,` - the same commands, respectively

### Leader

Common leader bindings:

- `C-j f` - `project-find-file`; `C-j F` - `find-file`
- `C-j e` - `project-dired`; `C-j b` - `consult-project-buffer`; `C-j B` - `consult-buffer`
- `C-j o` - `consult-recent-file`; `C-j /` - `consult-ripgrep`
- `C-j s` / `C-j S` - `consult-imenu` / `consult-imenu-multi`
- `C-j d` / `C-j D` - `consult-flymake` / `flymake-show-project-diagnostics`
- `C-j v` - `magit-status`; `C-j ;` - `project-compile`
- `C-j p p` - `project-switch-project`
- `C-j t` - Taskwarrior prefix; `C-j T` - toggle the dedicated Taskwarrior TUI
- `C-j $` - toggle the project terminal; `C-j .` - open Dired at the current file
- `C-j w` - window commands; `C-j j` - notebook commands; `C-j ,` - PMD commands

The Emacs `M-g` map remains available for goto/navigation commands. It includes Consult's project buffers, recent files, bookmarks, Imenu, marks, and Flymake diagnostics, plus project file-finding and error/buffer navigation. Standard Emacs bindings such as `M-.` for definitions and `M-?` for references remain in place. In Eglot-managed buffers, `C-c l` offers `a` for code actions, `r` for rename, `f` for formatting the buffer, and `F` for formatting the active region (or the buffer if no region is active).


## System Requirements

To fully utilize the core features of this configuration, ensure the following command-line tools are installed on your system:

* **Emacs 31+**: Required by the active configuration in `emacs.d`.
* **git**: Required for version control and Magit.
* **ripgrep (`rg`)**: Required for fast project-wide searching (Consult/project.el).
* **git-delta (`delta`)**: Required for advanced syntax highlighting in Magit diffs (`magit-delta`).
* **difftastic (`difft`)**: Required for structural diffs within Magit (`difftastic`).
