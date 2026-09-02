#!/bin/bash
# Agent Wrap-Up installer for macOS, Linux, and WSL.
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAP_UP_HOME="${WRAP_UP_HOME:-$HOME/.agent-wrap-up}"
BIN_DIR="${WRAP_UP_BIN_DIR:-$HOME/.local/bin}"
DIARY_DIR="${WRAP_UP_DIARY_DIR:-$HOME/.local/share/agent-wrap-up/diary}"
TRANSCRIPT_DIR="${WRAP_UP_TRANSCRIPT_DIR:-$HOME/.config/agent-wrap-up/transcripts}"
COMMANDS_DIR="${WRAP_UP_COMMANDS_DIR:-}"

echo "Installing Agent Wrap-Up…"
echo "  support dir: $WRAP_UP_HOME"
echo "  diary dir:   $DIARY_DIR"
echo "  bin dir:     $BIN_DIR"

for cmd in bash sqlite3 git python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found in PATH."
    exit 1
  fi
done

if [ -n "$COMMANDS_DIR" ]; then
  mkdir -p "$COMMANDS_DIR"
  cp "$REPO_DIR/commands/wrap-up.md" "$COMMANDS_DIR/wrap-up.md"
  cp "$REPO_DIR/commands/diary.md" "$COMMANDS_DIR/diary.md"
  echo "✓ harness commands installed"
else
  echo "• harness commands not copied (set WRAP_UP_COMMANDS_DIR to enable)"
fi

mkdir -p "$DIARY_DIR/entries" "$DIARY_DIR/breadcrumbs" "$TRANSCRIPT_DIR"

CONV_DIR="$WRAP_UP_HOME/conversations"
mkdir -p "$CONV_DIR" "$BIN_DIR"
cp "$REPO_DIR/bin/conv" "$CONV_DIR/conv"
cp "$REPO_DIR/schema.sql" "$CONV_DIR/schema.sql"
cp "$REPO_DIR/schema-transcripts.sql" "$CONV_DIR/schema-transcripts.sql"
cp "$REPO_DIR/ingest.py" "$CONV_DIR/ingest.py"
chmod +x "$CONV_DIR/conv"
ln -sf "$CONV_DIR/conv" "$BIN_DIR/conv"

if [ ! -f "$CONV_DIR/conversations.db" ]; then
  sqlite3 "$CONV_DIR/conversations.db" < "$CONV_DIR/schema.sql"
  sqlite3 "$CONV_DIR/transcripts.db" < "$CONV_DIR/schema-transcripts.sql"
  cd "$CONV_DIR"
  git init -q
  cp "$REPO_DIR/.gitignore" .gitignore
  git add -A
  git add -f conversations.db
  git commit -q -m "init: conversation ledger"
  cd - >/dev/null
  echo "✓ conversation databases initialized"
else
  echo "• conversation databases already exist"
fi

if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  echo "⚠ $BIN_DIR is not in PATH; add: export PATH=\"$BIN_DIR:\$PATH\""
fi

echo "Done. Connect the installed instructions to your harness."
