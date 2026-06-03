---
description: End-of-session wrap up — diary, breadcrumbs, conversation log, and cleanup
model: claude-sonnet-4-6
---

# Wrap Up Session

Perform all end-of-session tasks. Be quick and concise — the user is done working.

## 1. Diary Entry

Run /diary to create a structured diary entry for this session. Save to `~/.claude/diary/entries/YYYY-MM-DD-session-N.md`.

## 2. Breadcrumbs

Append 3-5 lines to `~/.claude/diary/breadcrumbs/YYYY-MM-DD.md` (today's date) summarizing non-git work from this session. Include: research done, decisions made, conversations had, skills refined, anything not captured in commits. Skip if the session was trivial or everything is in git.

Create the file if it doesn't exist. Append if it does.

## 3. Log Conversation

Run:
```bash
conv add \
  -s "SUMMARY" \
  -p "PROJECT" \
  -t "TAGS" \
  -d "DECISIONS" \
  -o "OUTCOMES"
```

Fill in from session context:
- `-s` — 1-2 sentence summary of what was discussed/built
- `-p` — project name if session focused on one (omit flag if general)
- `-t` — comma-separated topic tags
- `-d` — key decisions made (omit if none)
- `-o` — what was accomplished

Then ingest verbatim transcripts (idempotent — pulls this session and any
stragglers into the gitignored transcripts.db before they could age out):
```bash
conv ingest
```

Then commit (summary ledger only — transcripts.db is gitignored, so this is safe):
```bash
cd ~/claude/conversations && git add -A && git commit -m "log: $(date +%Y-%m-%d) session"
```

## 4. Build Log Sync

If build log entries were created this session:
```bash
cd ~/claude/build-logs && git add -A && git diff --cached --quiet || git commit -m "log: $(date +%Y-%m-%d) build"
```

## 5. Brief Confirmation

Tell the user what was logged in one line. Don't summarize the session back to them — they were there.
