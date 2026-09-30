# vendor

This directory holds vendored dependencies that are kept in-repo on purpose.

Tracked vendored components:

- `kanagawa-dragon-theme.el`: a local theme entry that adds the missing
  lexical-binding cookie.  The maintained implementation remains supplied by
  the MELPA `kanagawa-themes` package.
- `paredit.el`: an in-repo copy of Paredit version 26 by Taylor R. Campbell;
  `init.el` loads it from `vendor/` without installing a package.
