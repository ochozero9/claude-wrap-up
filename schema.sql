CREATE TABLE IF NOT EXISTS conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,                    -- ISO 8601 date (YYYY-MM-DD)
  time_start TEXT,                       -- HH:MM when session started
  project TEXT,                          -- which project was worked on (nullable for general)
  summary TEXT NOT NULL,                 -- 1-3 sentence summary of what we discussed/did
  topics TEXT,                           -- comma-separated topic tags
  decisions TEXT,                        -- key decisions made (newline-separated)
  outcomes TEXT,                         -- what was accomplished
  context TEXT,                          -- any important context for future reference
  duration_mins INTEGER,                 -- approximate session length
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_conversations_date ON conversations(date);
CREATE INDEX IF NOT EXISTS idx_conversations_project ON conversations(project);

CREATE VIRTUAL TABLE IF NOT EXISTS conversations_fts USING fts5(
  summary, topics, decisions, outcomes, context,
  content='conversations',
  content_rowid='id'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS conversations_ai AFTER INSERT ON conversations BEGIN
  INSERT INTO conversations_fts(rowid, summary, topics, decisions, outcomes, context)
  VALUES (new.id, new.summary, new.topics, new.decisions, new.outcomes, new.context);
END;

CREATE TRIGGER IF NOT EXISTS conversations_ad AFTER DELETE ON conversations BEGIN
  INSERT INTO conversations_fts(conversations_fts, rowid, summary, topics, decisions, outcomes, context)
  VALUES ('delete', old.id, old.summary, old.topics, old.decisions, old.outcomes, old.context);
END;

CREATE TRIGGER IF NOT EXISTS conversations_au AFTER UPDATE ON conversations BEGIN
  INSERT INTO conversations_fts(conversations_fts, rowid, summary, topics, decisions, outcomes, context)
  VALUES ('delete', old.id, old.summary, old.topics, old.decisions, old.outcomes, old.context);
  INSERT INTO conversations_fts(rowid, summary, topics, decisions, outcomes, context)
  VALUES (new.id, new.summary, new.topics, new.decisions, new.outcomes, new.context);
END;
