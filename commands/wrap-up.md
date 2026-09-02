---
description: End-of-session capture for diary notes, summaries, transcripts, and configured integrations
---

# Wrap Up Session

Perform the end-of-session tasks that are available in this workspace. Keep the final report concise and distinguish completed, skipped, and failed steps.

## 1. Diary and breadcrumbs

If diary capture is enabled, follow the diary instructions and save the entry under:

```text
${WRAP_UP_DIARY_DIR:-~/.local/share/agent-wrap-up/diary}/entries/
```

If there was meaningful work that will not appear in version control, append a few breadcrumb lines under the matching `breadcrumbs/YYYY-MM-DD.md` file.

## 2. Summary ledger

If `conv` is installed, record a one- to two-sentence summary, project, topics, decisions, and outcomes:

```bash
conv add -s "SUMMARY" [-p "PROJECT"] [-t "TAGS"] [-d "DECISIONS"] [-o "OUTCOMES"]
```

Do not put credentials, private customer data, or sensitive source code into the summary.

## 3. Transcript capture

If the harness exposes transcript files and transcript storage is enabled, run:

```bash
conv ingest "${WRAP_UP_TRANSCRIPT_DIR:-$HOME/.config/agent-wrap-up/transcripts}"
```

Verify the reported imported count. If the harness has no compatible transcript source, skip this step and say why. Do not imply that a summary proves the raw transcript was saved.

## 4. Configured integrations

Run only local adapters explicitly configured by the user, such as a build-log sync, repository commit, reminder scan, or encrypted backup. Each adapter must report its own result. Never push personal configuration, raw transcripts, or secrets merely because a remote is available.

## 5. Confirmation

Report one line with the result of diary, summary, transcript, and integrations. Mention any due reminders or failed syncs only when the configured adapter actually surfaced them.
