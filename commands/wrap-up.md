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

If build log entries were created this session (commit AND push so the GitHub copy stays current):
```bash
cd ~/claude/build-logs && git add -A
git diff --cached --quiet || { git commit -m "log: $(date +%Y-%m-%d) build" && git push -q origin main; }
```

## 5. Sync claude-config (~/.claude)

This repo silently drifts if it isn't pushed every session (it went 78% uncommitted once). Commit + push memory/diary/skills/commands, with a secret-scan guard so a pasted key never leaks. `decisions/`, credentials, and the daemon layer are gitignored → never staged. `mcp.json`'s inline key is intentional and excluded from the scan. Auto-push is fine here — pushing claude-config has no deploy consequence.

```bash
cd ~/.claude && git add -A
if git diff --cached --quiet; then
  echo "claude-config: nothing to sync"
else
  HITS=$(git grep --cached -nIE 'sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[0-9A-Za-z-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY' -- . ':!mcp.json' 2>/dev/null | head)
  if [ -n "$HITS" ]; then
    echo "⚠️ claude-config: possible secret — NOT committing. Review:"; echo "$HITS"; git reset -q
  else
    git commit -q -m "wrap-up: $(date +%Y-%m-%d) sync (memory/diary/skills)" && git push -q origin main && echo "claude-config: synced"
  fi
fi
```

## 6. Surface Due Reminders

List any due/overdue items from the **Decisions** and **Claude Follow-ups** Reminders lists and raise them in the confirmation, so dated items don't slip. (Claude Follow-ups = Claude's own proactive nudges — see memory `claude-followups-reminders`.)

```bash
for L in "Decisions" "Claude Follow-ups"; do
  due=$(osascript -e "tell application \"Reminders\" to get name of (reminders of list \"$L\" whose completed is false and remind me date < (current date))" 2>/dev/null)
  [ -n "$due" ] && echo "  $L due → $due"
done
```

## 7. Brief Confirmation

Tell the user what was logged in one line, plus any due reminders surfaced in step 6. Don't summarize the session back to them — they were there.
