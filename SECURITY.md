# Privacy and sharing checklist

Before publishing or sharing a copy of this repository:

- Remove databases, transcript files, exported conversations, logs, and screenshots.
- Search tracked files for home-directory paths, names, email addresses, account names, repository URLs, hostnames, API keys, tokens, and private project names.
- Keep personal integrations in a local adapter outside the shared repository.
- Do not commit real prompts or responses from work, customers, or private projects.
- Review Git history as well as current files; deleting a secret from the working tree does not remove it from old commits.
- If a secret was ever committed, rotate it before sharing.

The included importer stores raw source lines by design. That is useful for recovery but means transcript storage must be treated as sensitive data.
