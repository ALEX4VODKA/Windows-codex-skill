[CmdletBinding()]
param()

# Explicit opt-in: affects this process/session only; no registry or profile changes.
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::InputEncoding = $utf8NoBom
    [Console]::OutputEncoding = $utf8NoBom
} catch {
    Write-Warning 'Console encoding cannot be set by this host; use explicit encodings in file operations.'
}
$global:OutputEncoding = $utf8NoBom
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
