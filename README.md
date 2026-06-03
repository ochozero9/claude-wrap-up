# claude-wrap-up

End-of-session capture for Claude Code. One command, `/wrap-up`, writes a structured diary entry, logs the session to a searchable SQLite DB, captures the verbatim transcript before Claude Code's logs expire, drops breadcrumbs for non-git work, and commits everything to git.

The point: ambient capture. Every session leaves a trace you can search, reflect on, or feed into case studies later — without you having to remember to log anything.

Two layers of capture: a hand-written **summary ledger** (one searchable row per session) and the **verbatim transcript** (the full back-and-forth, ingested from Claude Code's own JSONL logs). Claude Code deletes those logs after `cleanupPeriodDays` (default 30) — ingesting on every wrap-up means they're preserved before they age out.

## What it does

`/wrap-up` runs five steps:

1. **Diary entry** — `/diary` writes a structured markdown file to `~/.claude/diary/entries/YYYY-MM-DD-session-N.md` covering task summary, decisions, challenges, preferences observed, and files touched.
2. **Breadcrumbs** — appends 3-5 lines to `~/.claude/diary/breadcrumbs/YYYY-MM-DD.md` for work that won't show up in git (research, conversations, decisions, refined prompts).
3. **Conversation log** — `conv add` inserts a summary row into `~/claude/conversations/conversations.db` (SQLite + FTS5 full-text search) with summary, project, tags, decisions, outcomes. Then `conv ingest` pulls the verbatim transcript of the session into `transcripts.db`.
4. **Build log sync** — commits `~/claude/build-logs/` if passive `/build-log` entries landed during the session.
5. **One-line confirmation** of what was logged.

## Why you'd want this

After a week of sessions you have:

- A searchable database of every project decision (`conv search "auth"`).
- A dated trail of non-code work that otherwise evaporates.
- Raw material for retrospectives, case studies, and "what was I thinking in March" moments.
- Git history of your thinking, not just your code.

## Install

```bash
git clone https://github.com/ochozero9/claude-wrap-up.git
cd claude-wrap-up
./install.sh
```

The installer:

- Copies `commands/wrap-up.md` and `commands/diary.md` to `~/.claude/commands/`
- Installs `conv` (plus `ingest.py` and the schemas) into `~/claude/conversations/` and symlinks `~/bin/conv` to it (creates the dir and adds to PATH if needed)
- Creates `~/claude/conversations/` as a git repo with both DBs initialized — `conversations.db` (committed) and `transcripts.db` (gitignored)
- Creates `~/claude/build-logs/` as a git repo (empty, ready for `/build-log` entries)
- Creates `~/.claude/diary/{entries,breadcrumbs}/`

Requirements: `bash`, `sqlite3`, `git`, `python3`. macOS and Linux.

### Retain your transcripts

Verbatim ingest only works on Claude Code logs that still exist. Claude Code deletes session JSONL files older than `cleanupPeriodDays` (default **30**). To stop losing them, raise it in `~/.claude/settings.json`:

```json
{ "cleanupPeriodDays": 36500 }
```

Already-deleted sessions can't be recovered, but everything from that point forward is preserved on each `conv ingest`.

## Usage

At the end of a Claude Code session, type:

```
/wrap-up
```

That's it. It runs the whole pipeline and reports back in one line.

## `conv` CLI

The conversation database is useful on its own:

```bash
# Summary ledger (conversations.db)
conv list              # last 10 sessions
conv today             # today's sessions
conv search "auth"     # full-text search of summaries
conv project milo      # all sessions for a project
conv stats             # totals by project and month
conv gaps              # days with git activity but no log
conv backfill          # reconstruct unlogged sessions from git + breadcrumbs

# Verbatim transcripts (transcripts.db)
conv ingest            # pull new turns from Claude Code's JSONL logs (idempotent)
conv sessions          # list recently-ingested sessions
conv transcript <sid>  # show one session's turns in order
conv msearch "auth"    # full-text search across the verbatim back-and-forth
```

Schema (`conversations.db`):

| field | purpose |
|---|---|
| `date` | YYYY-MM-DD |
| `time_start` | HH:MM |
| `project` | project name (nullable) |
| `summary` | 1-3 sentence overview |
| `topics` | comma-separated tags |
| `decisions` | key decisions made |
| `outcomes` | what was accomplished |
| `context` | anything worth preserving |
| `duration_mins` | approximate session length |

FTS5 virtual table indexes summary/topics/decisions/outcomes/context for fast search.

Schema (`transcripts.db`, one row per user/assistant turn):

| field | purpose |
|---|---|
| `session_id` | Claude Code session UUID (the grouping key) |
| `uuid` | per-record UUID — dedup key for idempotent re-ingest |
| `conversation_id` | best-effort link to a `conversations.db` summary row (nullable) |
| `project` | derived from the session's working dir |
| `role` | `user` or `assistant` |
| `content` | flattened, human-readable transcript text |
| `raw_json` | the original JSONL line, for full fidelity |
| `timestamp` | ISO 8601 |
| `seq` | turn order within the session |

A separate FTS5 table indexes `content`. `transcripts.db` is kept out of git (it's bulky and rebuildable) — only the summary ledger is committed.

## Directory layout after install

```
~/.claude/
  commands/
    wrap-up.md
    diary.md
  diary/
    entries/           # full structured diary entries
    breadcrumbs/       # daily short-form notes

~/claude/
  conversations/       # git repo
    conv                 # CLI (symlink target)
    conversations.db     # summary ledger (committed)
    transcripts.db       # verbatim transcripts (gitignored)
    schema.sql
    schema-transcripts.sql
    ingest.py            # JSONL → transcripts.db
  build-logs/          # git repo, populated by /build-log
~/bin/
  conv                 # symlink → ~/claude/conversations/conv
```

## Customization

**Different paths?** Edit the paths at the top of `bin/conv` (`CLAUDE_DIR`, `DIARY_DIR`) and the directory references in `commands/wrap-up.md` and `commands/diary.md`. Everything is plain text.

**Don't want the conversation DB?** Delete step 3 from `commands/wrap-up.md`. Diary + breadcrumbs work standalone.

**Want summaries but not verbatim transcripts?** Drop the `conv ingest` line from step 3 of `commands/wrap-up.md`. The summary ledger keeps working on its own.

**Don't want build logs?** Delete step 4 from `commands/wrap-up.md`.

**Add your own step?** Just append to `commands/wrap-up.md` — it's a markdown skill, not code.

## Companion skills (not included)

`/wrap-up` pairs well with these, but they're separate:

- `/build-log` — passive build logging during sessions, writes to `~/claude/build-logs/{project}/{feature}.md`
- `/diary` — included here; can be invoked on its own
- `/reflect` — reads diary entries to surface patterns and propose instruction updates

## License

MIT.
