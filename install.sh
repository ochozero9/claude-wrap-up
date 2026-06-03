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
for cmd in bash sqlite3 git python3; do
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

# 3. conv CLI + its support files
# conv lives alongside its database so it can find the schema files and the
# transcripts DB ($DB_DIR resolves to the script's own dir). bin/conv is a
# symlink into the conversations dir.
CONV_DIR="$CLAUDE_WORK/conversations"
mkdir -p "$CONV_DIR"
cp "$REPO_DIR/bin/conv"               "$CONV_DIR/conv"
cp "$REPO_DIR/schema.sql"             "$CONV_DIR/schema.sql"
cp "$REPO_DIR/schema-transcripts.sql" "$CONV_DIR/schema-transcripts.sql"
cp "$REPO_DIR/ingest.py"              "$CONV_DIR/ingest.py"
chmod +x "$CONV_DIR/conv"

mkdir -p "$BIN_DIR"
ln -sf "$CONV_DIR/conv" "$BIN_DIR/conv"
echo "✓ conv installed (symlinked $BIN_DIR/conv → $CONV_DIR/conv)"

if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  echo ""
  echo "⚠  $BIN_DIR is not in your PATH. Add this to your shell rc:"
  echo "     export PATH=\"$BIN_DIR:\$PATH\""
fi

# 4. Databases — git-backed summary ledger + gitignored verbatim transcripts
if [ ! -f "$CONV_DIR/conversations.db" ]; then
  sqlite3 "$CONV_DIR/conversations.db" < "$CONV_DIR/schema.sql"
  sqlite3 "$CONV_DIR/transcripts.db"   < "$CONV_DIR/schema-transcripts.sql"
  cd "$CONV_DIR"
  git init -q
  cat > .gitignore <<'GI'
conversations.db-journal
conversations.db-wal
conversations.db-shm
# Verbatim transcripts are bulky — rebuildable anytime via `conv ingest`.
transcripts.db
transcripts.db-wal
transcripts.db-shm
GI
  git add -A
  git commit -q -m "init: conversations db"
  cd - >/dev/null
  echo "✓ conversations + transcripts dbs initialized at $CONV_DIR"
else
  echo "• conversations dir exists — refreshed conv/schema/ingest, skipped db init"
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
