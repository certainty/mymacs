#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="${SCRIPT_DIR}/../../scripts/emacs-tools"

echo "Testing Emacs configuration from: $SCRIPT_DIR"
echo ""

echo "==> Checking parens"
EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" check-parens "$SCRIPT_DIR/early-init.el"
EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" check-parens "$SCRIPT_DIR/init.el"
for f in "$SCRIPT_DIR/modules/"*.el; do
  EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" check-parens "$f"
done

echo ""
echo "==> Byte compiling"
EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" byte-compile "$SCRIPT_DIR/early-init.el"
EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" byte-compile "$SCRIPT_DIR/init.el"
for f in "$SCRIPT_DIR/modules/"*.el; do
  EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" byte-compile "$f"
done

echo ""
echo "==> Loading init.el in batch"
EMACS_CONFIG_ROOT="$SCRIPT_DIR" "$TOOLS" batch-check

echo ""
echo "==> Cleaning up .elc files"
rm -f "$SCRIPT_DIR/early-init.elc" "$SCRIPT_DIR/init.elc"
rm -f "$SCRIPT_DIR/modules/"*.elc

echo ""
echo "==> All automated checks passed."
echo "    To start Emacs with this profile:"
echo "      emacs --init-directory=$SCRIPT_DIR"