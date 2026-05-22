# Package Workflow

## Policy

- Prefer GNU ELPA.
- Use NonGNU ELPA only when GNU ELPA does not provide the package.
- Keep built-ins unadorned: no `:ensure`.
- Vendored packages live in `user-lisp/<name>` as git submodules and are loaded from `load-path` automatically by `early-init.el`.

## Upgrading Vendored Packages

1. Update the submodule to the desired upstream commit.
2. Review the submodule diff before committing.
3. Re-run the Emacs validation commands.

Example:

```sh
git submodule update --remote user-lisp/nerd-icons
git diff --submodule=log
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools doctor
EMACS_CONFIG_ROOT=emacs.d ./scripts/emacs-tools byte-compile emacs.d/init.el
```

## ELPA Packages

- Leave the package declaration as `:ensure t`.
- GNU ELPA is the default choice when a package exists in both archives.
- NonGNU ELPA is the fallback when GNU ELPA does not provide the package.

If we decide to add a review step for ELPA upgrades later, it can sit on top of this model without changing the vendoring layout.
