#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing Emacs configuration from: $SCRIPT_DIR"
echo "This will not affect your existing Emacs configuration."
echo ""

# Use --init-directory to load config from evil-fresh without affecting ~/.emacs.d
exec emacs --debug-init --init-directory="$SCRIPT_DIR" "$@"
