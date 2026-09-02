#!/usr/bin/env python3
"""
ingest.py — load verbatim Claude Code transcripts into the messages table.

Reads compatible session JSONL logs from the configured source directory.
and inserts each user/assistant turn as a row in `messages`. Idempotent: the
UNIQUE index on messages.uuid means re-running only adds new turns.

Usage:
    ingest.py <transcripts_db> <conversations_db> [path]
        transcripts_db   — target DB for the messages table
        conversations_db — summary ledger, attached read-only for best-effort linkage
        path             — defaults to WRAP_UP_TRANSCRIPT_DIR; may be a .jsonl file or a dir

Notes:
- Subagent / sidechain transcripts are skipped by default — the table holds the
  human-facing back-and-forth, not internal agent chatter.
- Only `user` and `assistant` records are ingested; bookkeeping record types
  (mode, system, file-history-snapshot, etc.) are ignored.
"""
import json
import os
import sqlite3
import sys

HOME = os.path.expanduser("~")
DEFAULT_SCAN = os.environ.get(
    "WRAP_UP_TRANSCRIPT_DIR",
    os.path.join(HOME, ".config", "agent-wrap-up", "transcripts"),
)


def flatten(content):
    """Turn a JSONL message `content` (str or list of blocks) into readable text."""
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    parts = []
    for b in content:
        if not isinstance(b, dict):
            parts.append(str(b))
            continue
        t = b.get("type")
        if t == "text":
            parts.append(b.get("text", ""))
        elif t == "thinking":
            parts.append("[thinking] " + b.get("thinking", ""))
        elif t == "tool_use":
            parts.append(
                "[tool_use: %s] %s"
                % (b.get("name", "?"), json.dumps(b.get("input", {}), ensure_ascii=False))
            )
        elif t == "tool_result":
            parts.append("[tool_result] " + flatten(b.get("content")))
        elif t == "image":
            parts.append("[image]")
        else:
            parts.append("[%s]" % t)
    return "\n".join(p for p in parts if p)


def project_from_cwd(cwd):
    if not cwd:
        return None
    return os.path.basename(cwd.rstrip("/")) or None


def iter_jsonl_files(path):
    if os.path.isfile(path):
        if path.endswith(".jsonl"):
            yield path
        return
    for root, _dirs, files in os.walk(path):
        for name in files:
            if name.endswith(".jsonl"):
                yield os.path.join(root, name)


def ingest_file(conn, fpath):
    inserted = 0
    seq = 0
    with open(fpath, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
            except json.JSONDecodeError:
                continue
            if o.get("type") not in ("user", "assistant"):
                continue
            if o.get("isSidechain"):
                continue
            msg = o.get("message") or {}
            role = msg.get("role") or o.get("type")
            content = flatten(msg.get("content"))
            seq += 1
            cur = conn.execute(
                """INSERT OR IGNORE INTO messages
                   (session_id, uuid, parent_uuid, project, role, content, raw_json, timestamp, seq)
                   VALUES (?,?,?,?,?,?,?,?,?)""",
                (
                    o.get("sessionId"),
                    o.get("uuid"),
                    o.get("parentUuid"),
                    project_from_cwd(o.get("cwd")),
                    role,
                    content,
                    line,
                    o.get("timestamp"),
                    seq,
                ),
            )
            inserted += cur.rowcount
    return inserted


def link_conversations(conn):
    """Best-effort: link a message to a same-day, same-project conversation
    summary when exactly one such summary exists. Leaves the rest NULL.
    Reads the summary ledger from the attached `cdb` database."""
    conn.execute(
        """
        UPDATE messages
        SET conversation_id = (
            SELECT c.id FROM cdb.conversations c
            WHERE c.date = substr(messages.timestamp, 1, 10)
              AND c.project IS messages.project
        )
        WHERE conversation_id IS NULL
          AND timestamp IS NOT NULL
          AND (
            SELECT count(*) FROM cdb.conversations c
            WHERE c.date = substr(messages.timestamp, 1, 10)
              AND c.project IS messages.project
          ) = 1
        """
    )


def main():
    if len(sys.argv) < 3:
        print("usage: ingest.py <transcripts_db> <conversations_db> [path]", file=sys.stderr)
        sys.exit(1)
    db = sys.argv[1]
    conv_db = sys.argv[2]
    scan = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_SCAN

    conn = sqlite3.connect(db)
    conn.execute("ATTACH DATABASE ? AS cdb", (conv_db,))
    try:
        total = 0
        files = 0
        for fpath in iter_jsonl_files(scan):
            n = ingest_file(conn, fpath)
            if n:
                files += 1
                total += n
        link_conversations(conn)
        conn.commit()
        print("Ingested %d new message(s) from %d file(s)" % (total, files))
    finally:
        conn.close()


if __name__ == "__main__":
    main()
