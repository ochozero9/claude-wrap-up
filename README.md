# Agent Wrap-Up

End-of-session capture for coding agents and other AI workspaces. The workflow records a short summary, optional diary notes, and—when the source logs are available—a searchable copy of the conversation before retention cleanup removes it.

The core is harness-neutral. It does not require a particular model, vendor account, cloud service, repository host, or backup provider. Harnesses that support markdown skills can install the instructions directly; other agents can follow [`SKILL.md`](SKILL.md) or call the included command-line tools.

## What is included

- A portable wrap-up contract in [`SKILL.md`](SKILL.md).
- Markdown instructions for a wrap-up action and a diary action.
- `conv`, a small SQLite-backed command-line tool for summaries and transcript search.
- Idempotent transcript ingestion for Claude Code JSONL logs, with a documented adapter boundary.
- Optional build-log, configuration-sync, reminder, and remote-backup steps. These are disabled unless the user explicitly configures them.

No user data, databases, credentials, private integrations, or machine-specific configuration belongs in this repository.

## Install on macOS, Linux, or WSL

```bash
git clone https://github.com/your-account/claude-wrap-up.git
cd claude-wrap-up
./install.sh
```

The installer accepts `WRAP_UP_HOME`, `WRAP_UP_BIN_DIR`, `WRAP_UP_DIARY_DIR`, `WRAP_UP_COMMANDS_DIR`, and `WRAP_UP_TRANSCRIPT_DIR`. See `install.sh` for defaults and use `WRAP_UP_COMMANDS_DIR="$HOME/.claude/commands"` for Claude Code.

The installer does not overwrite existing databases. It refreshes installed scripts and instruction files.

Requirements: Bash, Python 3, Git, and SQLite. The workflow itself is plain text and shell, so another harness can use the instructions without installing the CLI.

## Use it

At the end of a session, invoke the installed wrap-up command in the way your harness supports. For Claude Code, type `/wrap-up`. The agent should write optional diary notes, add a concise summary, ingest available transcripts, run enabled adapters, and report completed, skipped, and failed steps separately.

The final report must not claim that a backup, remote push, or transcript capture succeeded unless that downstream effect was observed.

## CLI examples

```text
conv add -s "Summary" -p "project" -t "research,decision" -o "Outcome"
conv list
conv search "authentication"
conv ingest /path/to/source-logs
conv sessions
conv transcript SESSION_ID
conv msearch "important phrase"
```

The summary database is intended to be committed by the user’s own repository policy. Raw transcripts are gitignored by default because they may contain private prompts, source code, credentials, or customer data.

## Privacy and workplace use

Review captured text before sharing it. Do not ingest logs from projects or accounts outside your authority. Keep transcript storage local unless you deliberately configure an encrypted destination. See [`SECURITY.md`](SECURITY.md).

The portable core does not assume AppleScript, a particular reminders app, a private config repository, a cloud drive, or a specific Git remote. Add those as local adapter instructions outside this repository. [`adapters/claude-code.md`](adapters/claude-code.md) documents the Claude Code adapter.

## License

MIT. See [`LICENSE`](LICENSE).
