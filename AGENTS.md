# Repository Rules — Windows Codex Toolkit

This repository maintains **reusable Windows shell reliability skills and small PowerShell scripts**, independent of any application project.

- Keep `skills/windows-local-ops/SKILL.md` short and action-oriented; put examples under `references/` and repeatable actions under `scripts/`.
- Preserve `windows-kubectl-reliable-ops` functionality. Treat its original four scripts as imported code requiring separate review; do not silently rewrite behavior.
- Fix **observed** problems with small, testable changes. Add or update a smoke test whenever behavior changes. Distinguish Windows-runtime-tested from static-reviewed-only.
- No routine environment scans, package installation, profile edits, execution policy changes, or automatic retry of writes.
- Do not add new host-specific paths, credentials, kubeconfigs, output dumps, or machine inventory to tracked files. Existing imported historical path examples must be treated as unverified, not current host facts.
- Use Conventional Commits and descriptive branches. Do not commit, push, rewrite history, or merge without explicit user approval.
- Before changing any installed skill, explain source-vs-installation path to avoid divergence. The Git repository is the source of truth.
