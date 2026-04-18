#!/bin/bash
# claude-wrap-up installer
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CLAUDE_WORK="${CLAUDE_WORK:-$HOME/claude}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

echo "Installing claude-wrap-up…"
echo "  .claude dir:   $CLAUDE_HOME"
echo "  work dir:      $CLAUDE_WORK"
echo "  bin dir:       $BIN_DIR"
echo ""

# Requirements check
for cmd in bash sqlite3 git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found in PATH."
    exit 1
  fi
done

# 1. Commands
mkdir -p "$CLAUDE_HOME/commands"
cp "$REPO_DIR/commands/wrap-up.md" "$CLAUDE_HOME/commands/wrap-up.md"
cp "$REPO_DIR/commands/diary.md" "$CLAUDE_HOME/commands/diary.md"
echo "✓ commands installed"

# 2. Diary directories
mkdir -p "$CLAUDE_HOME/diary/entries" "$CLAUDE_HOME/diary/breadcrumbs"
echo "✓ diary directories created"

# 3. conv CLI
mkdir -p "$BIN_DIR"
cp "$REPO_DIR/bin/conv" "$BIN_DIR/conv"
chmod +x "$BIN_DIR/conv"
echo "✓ conv installed to $BIN_DIR"

if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  echo ""
  echo "⚠  $BIN_DIR is not in your PATH. Add this to your shell rc:"
  echo "     export PATH=\"$BIN_DIR:\$PATH\""
fi

# 4. Conversations DB (git-backed)
CONV_DIR="$CLAUDE_WORK/conversations"
if [ ! -d "$CONV_DIR" ]; then
  mkdir -p "$CONV_DIR"
  cp "$REPO_DIR/schema.sql" "$CONV_DIR/schema.sql"
  sqlite3 "$CONV_DIR/conversations.db" < "$CONV_DIR/schema.sql"
  cd "$CONV_DIR"
  git init -q
  echo "conversations.db-journal" > .gitignore
  git add -A
  git commit -q -m "init: conversations db"
  cd - >/dev/null
  echo "✓ conversations db initialized at $CONV_DIR"
else
  echo "• conversations dir exists — skipping init"
fi

# 5. Build logs (git-backed, empty)
BUILD_DIR="$CLAUDE_WORK/build-logs"
if [ ! -d "$BUILD_DIR" ]; then
  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"
  git init -q
  echo "# Build Logs" > README.md
  git add -A
  git commit -q -m "init: build logs"
  cd - >/dev/null
  echo "✓ build logs initialized at $BUILD_DIR"
else
  echo "• build-logs dir exists — skipping init"
fi

echo ""
echo "Done. Run /wrap-up at the end of a Claude Code session."
