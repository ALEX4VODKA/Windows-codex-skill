[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$skill = Join-Path $repo 'skills\windows-local-ops'
$rangeScript = Join-Path $skill 'scripts\Read-TextRange.ps1'
$sessionScript = Join-Path $skill 'scripts\Set-Utf8Session.ps1'

# PowerShell parser check without executing the target script.
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($rangeScript, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Read-TextRange.ps1 contains PowerShell syntax errors.' }
$tokens = $null; $parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($sessionScript, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Set-Utf8Session.ps1 contains PowerShell syntax errors.' }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('windows-local-ops-test-' + [Guid]::NewGuid().ToString('N') + '.txt')
try {
    $lines = 1..300 | ForEach-Object { "第$_ 行 -- 中文 UTF8" }
    [System.IO.File]::WriteAllLines($tmp, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    $actual = (& $rangeScript -Path $tmp -StartLine 101 -Count 5) -join "`n"
    if ($actual -notmatch '101: 第101 行' -or $actual -notmatch '105: 第105 行') {
        throw 'Range did not return the requested numbered Chinese lines.'
    }
    if ($actual -notmatch 'MORE=true TRUNCATED=false') {
        throw 'Range did not expose the expected partial-file marker.'
    }
    $last = (& $rangeScript -Path $tmp -StartLine 299 -Count 5) -join "`n"
    if ($last -notmatch 'MORE=false TRUNCATED=false') {
        throw 'Range incorrectly claims there is more data after EOF.'
    }
    $small = (& $rangeScript -Path $tmp -StartLine 1 -Count 100 -MaxChars 500) -join "`n"
    if ($small -notmatch 'TRUNCATED=true') {
        throw 'Character budget did not mark partial output.'
    }
    Write-Output 'PASS: PowerShell parse, Chinese UTF-8, bounded range, EOF and truncation markers.'
} finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
}
