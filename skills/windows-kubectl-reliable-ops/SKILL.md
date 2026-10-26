---
name: windows-kubectl-reliable-ops
description: Reliable Windows PowerShell execution for local kubectl, Prometheus/Grafana data collection, and Chinese report workflows. Use when a task may hit Codex sandbox or filesystem permission boundaries, transient Kubernetes API failures, unavailable command-line tools, PowerShell encoding problems, or mojibake in Chinese CSV/Markdown/JSON output.
---

# Windows kubectl Reliable Operations

Use this workflow for `kubectl` and local data-processing work on Windows.

## Start Every PowerShell Command Safely

Dot-source `scripts/Initialize-SessionUtf8.ps1` at the start of each PowerShell command that reads, transforms, or emits Chinese text:

```powershell
. "$env:CODEX_HOME\skills\windows-kubectl-reliable-ops\scripts\Initialize-SessionUtf8.ps1"
```

If `CODEX_HOME` is unset, use the absolute skill path discovered from the current environment. Still pass `-Encoding UTF8` explicitly to `Get-Content`, `Set-Content`, `Import-Csv`, and `Export-Csv` where supported. Write Chinese CSV as UTF-8 BOM when Excel compatibility matters.

For Python, keep `PYTHONUTF8=1` and `PYTHONIOENCODING=utf-8`. Open text files with an explicit encoding. Prefer `utf-8-sig` for Chinese CSV output and `utf-8` for Markdown/JSON.

## Preflight Permissions and Tools

Run the preflight before a long collection or after an environment change:

```powershell
& "$env:CODEX_HOME\skills\windows-kubectl-reliable-ops\scripts\Test-ExecutionEnvironment.ps1" -Workspace D:\kubectl
```

Add `-ProbeKubernetes` only when a live API check is required. Treat its JSON output as evidence, not as permission to broaden access.

Before each command, classify the operation:

1. Read/write inside declared workspace roots: run sandboxed first.
2. Read outside roots, run a GUI/admin command, or write a protected path: request escalation directly with a narrow user-facing justification.
3. On `Access denied`, sandbox denial, or likely sandbox DNS/network failure: retry once with `require_escalated`; do not invent path-copy or shell-bypass workarounds.
4. Keep escalation scope minimal. Never weaken `sandbox_mode`, change `approval_policy` to unconditional access, or request a broad executable prefix to avoid future reviews.
5. For destructive operations, verify the resolved absolute target and obtain approval when the user did not explicitly request deletion.

## Use Deterministic Tool Fallbacks

On this workstation, use `$env:RG_EXECUTABLE`, expected to be `D:\kubectl\.tools\ripgrep\rg.exe`, for every ripgrep call. If the variable is unavailable, use that absolute path directly. Do not invoke bare `rg`: PATH can resolve it to the blocked WindowsApps package binary.

Test the independent executable before relying on it. If its `--version` command fails, use `Select-String` and `Get-ChildItem` in the same PowerShell process. Do not invoke the known-blocked WindowsApps binary.

Prefer structured parsers for JSON/CSV. Avoid passing Chinese dictionary keys through nested PowerShell here-strings; place reusable logic in a UTF-8 script file or use escaped Unicode keys when a shell boundary is unavoidable.

## Handle Transient API Failures

Use `scripts/Invoke-WithRetry.ps1` for short idempotent read-only commands when the called program lacks retry logic:

```powershell
& "$env:CODEX_HOME\skills\windows-kubectl-reliable-ops\scripts\Invoke-WithRetry.ps1" `
  -FilePath D:\kubectl\kubectl.exe `
  -ArgumentList @('get', '--raw=/readyz', '--request-timeout=10s')
```

Retry only recognized transient errors such as EOF, timeout, TLS handshake timeout, connection reset, temporary DNS failure, HTTP 502/503/504, or rate limiting. Stop immediately for authentication, authorization, syntax, missing resource, and validation errors. Use bounded exponential backoff and report the final error.

For large Kubernetes reads, prefer per-namespace queries and snapshots over `kubectl get -A -o json`. Reuse validated snapshots when the remote API is unstable, and clearly label cached versus freshly collected data.

For idempotent HTTP downloads, use `scripts/Invoke-WebRequestWithRetry.ps1`. It downloads to a partial file, retries recognized transient transport failures, and only replaces the destination after a successful response. A persistent sandbox network denial still requires one narrowly scoped escalated retry.

## Verify Output

After collection or report generation:

1. Reopen output with the declared encoding.
2. Check headers, row counts, date bounds, null rates, and calculation invariants.
3. Confirm no mojibake replacement characters are present.
4. Record whether live API, cached snapshot, fallback tool, or escalated execution was used.
5. Do not claim success when a required command remained blocked or a session is still running.
