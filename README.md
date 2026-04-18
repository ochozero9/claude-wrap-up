# claude-wrap-up

End-of-session capture for Claude Code. One command, `/wrap-up`, writes a structured diary entry, logs the session to a searchable SQLite DB, drops breadcrumbs for non-git work, and commits everything to git.

The point: ambient capture. Every session leaves a trace you can search, reflect on, or feed into case studies later — without you having to remember to log anything.

## What it does

`/wrap-up` runs five steps:

1. **Diary entry** — `/diary` writes a structured markdown file to `~/.claude/diary/entries/YYYY-MM-DD-session-N.md` covering task summary, decisions, challenges, preferences observed, and files touched.
2. **Breadcrumbs** — appends 3-5 lines to `~/.claude/diary/breadcrumbs/YYYY-MM-DD.md` for work that won't show up in git (research, conversations, decisions, refined prompts).
3. **Conversation log** — `conv add` inserts a row into `~/claude/conversations/conversations.db` (SQLite + FTS5 full-text search) with summary, project, tags, decisions, outcomes.
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
git clone https://github.com/YOUR_USERNAME/claude-wrap-up.git
cd claude-wrap-up
./install.sh
```

The installer:

- Copies `commands/wrap-up.md` and `commands/diary.md` to `~/.claude/commands/`
- Copies `bin/conv` to `~/bin/` (creates the dir and adds to PATH if needed)
- Creates `~/claude/conversations/` as a git repo with the SQLite schema initialized
- Creates `~/claude/build-logs/` as a git repo (empty, ready for `/build-log` entries)
- Creates `~/.claude/diary/{entries,breadcrumbs}/`

Requirements: `bash`, `sqlite3`, `git`. macOS and Linux.

## Usage

At the end of a Claude Code session, type:

```
/wrap-up
```

That's it. It runs the whole pipeline and reports back in one line.

## `conv` CLI

The conversation database is useful on its own:

```bash
conv list              # last 10 sessions
conv today             # today's sessions
conv search "auth"     # full-text search
conv project milo      # all sessions for a project
conv stats             # totals by project and month
conv gaps              # days with git activity but no log
conv backfill          # reconstruct unlogged sessions from git + breadcrumbs
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
    conversations.db
    schema.sql
  build-logs/          # git repo, populated by /build-log
~/bin/
  conv                 # CLI
```

## Customization

**Different paths?** Edit the paths at the top of `bin/conv` (`CLAUDE_DIR`, `DIARY_DIR`) and the directory references in `commands/wrap-up.md` and `commands/diary.md`. Everything is plain text.

**Don't want the conversation DB?** Delete step 3 from `commands/wrap-up.md`. Diary + breadcrumbs work standalone.

**Don't want build logs?** Delete step 4 from `commands/wrap-up.md`.

**Add your own step?** Just append to `commands/wrap-up.md` — it's a markdown skill, not code.

## Companion skills (not included)

`/wrap-up` pairs well with these, but they're separate:

- `/build-log` — passive build logging during sessions, writes to `~/claude/build-logs/{project}/{feature}.md`
- `/diary` — included here; can be invoked on its own
- `/reflect` — reads diary entries to surface patterns and propose instruction updates

## License

MIT.
