# Claude Code adapter

Claude Code can load the markdown files in `commands/` as slash commands. Set `WRAP_UP_COMMANDS_DIR` to the command directory during installation.

The included transcript importer understands Claude Code session JSONL files. It ignores sidechains and bookkeeping records, keeps user and assistant turns, and deduplicates records by their source UUID. Configure the source directory with `WRAP_UP_TRANSCRIPT_DIR` or pass a file/directory to `conv ingest`.

Claude Code’s retention settings and transcript format can change. Treat ingestion as best-effort and verify the imported session count after running it.
