---
name: agent-wrap-up
description: End-of-session capture for any coding agent, AI assistant, or LLM harness
---

# Agent Wrap-Up

Use this workflow when the user ends a work session. It is a portable contract, not a vendor-specific command.

## Required behavior

1. Create a concise diary entry if the user has enabled diary capture.
2. Add a short summary to the conversation ledger if the `conv` command is installed.
3. Capture source transcripts only when the harness exposes them and the user has enabled transcript storage.
4. Run configured local sync or backup adapters only when they exist and are in scope.
5. Report outcomes step by step: completed, skipped because unavailable or disabled, and failed.

Never claim that a transcript was captured, a repository was pushed, or a backup was published from an exit code alone. Confirm the resulting file, commit, remote response, or other downstream effect.

## Data boundaries

Treat prompts, responses, tool calls, source code, customer data, credentials, and paths as sensitive. Do not copy them into this repository. Raw transcripts should remain local and gitignored unless the user explicitly chooses a protected destination.

## Harness adapter

The harness should map its own command or end-of-session hook to this workflow. It may use the included markdown commands, invoke `conv`, or implement the same contract in its native format. If no transcript API exists, skip transcript capture and say so; summary and diary layers still work.

## Suggested completion message

“Wrap-up complete: diary [saved/skipped/failed], summary [saved/skipped/failed], transcript [captured/skipped/failed], integrations [list result].”
