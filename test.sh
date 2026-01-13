#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing Emacs configuration from: $SCRIPT_DIR"
echo "This will not affect your existing Emacs configuration."
echo ""

# First, run a batch sanity check to ensure init/early-init load cleanly.
emacs --batch --init-directory="$SCRIPT_DIR" \
  --eval "(message \"MYMACS init sanity check: OK\")"

# Use --init-directory to load config from this repo without affecting ~/.emacs.d
exec emacs --debug-init --init-directory="$SCRIPT_DIR" "$@"
