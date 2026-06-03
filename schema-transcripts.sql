-- =====================================================================
-- transcripts.db — verbatim Claude Code message transcripts
-- =====================================================================
-- Kept in a SEPARATE, gitignored database from conversations.db so the
-- human-curated summary ledger stays small and git-friendly while the
-- bulky raw back-and-forth (raw_json per turn) lives here. Populated by
-- `conv ingest`. session_id is the grouping key; conversation_id is a
-- best-effort match into conversations.db (often NULL).
CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,              -- Claude Code session UUID (JSONL filename)
  uuid TEXT,                             -- per-record UUID — dedup key for idempotent re-ingest
  parent_uuid TEXT,                      -- threading pointer from the JSONL record
  conversation_id INTEGER,               -- best-effort link to conversations.id (nullable, cross-db)
  project TEXT,                          -- derived from the record's cwd
  role TEXT NOT NULL,                    -- user | assistant
  content TEXT,                          -- flattened, human-readable transcript text
  raw_json TEXT,                         -- original JSONL line, for full fidelity / reprocessing
  timestamp TEXT,                        -- ISO 8601 timestamp from the record
  seq INTEGER,                           -- order of the turn within its session
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_uuid ON messages(uuid);
CREATE INDEX IF NOT EXISTS idx_messages_session ON messages(session_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);

CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
  content,
  content='messages',
  content_rowid='id'
);

CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages BEGIN
  INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
END;

CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages BEGIN
  INSERT INTO messages_fts(messages_fts, rowid, content) VALUES ('delete', old.id, old.content);
END;

CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages BEGIN
  INSERT INTO messages_fts(messages_fts, rowid, content) VALUES ('delete', old.id, old.content);
  INSERT INTO messages_fts(rowid, content) VALUES (new.id, new.content);
END;
