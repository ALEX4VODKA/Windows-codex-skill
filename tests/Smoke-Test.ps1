[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$skill = Join-Path $repo 'skills\windows-local-ops'
$rangeScript = Join-Path $skill 'scripts\Read-TextRange.ps1'
$sessionScript = Join-Path $skill 'scripts\Set-Utf8Session.ps1'
$agensiPackage = Join-Path $repo 'distributions\agensi\windows-codex-toolkit'
$agensiLocalSkill = Join-Path $agensiPackage 'skills\windows-local-ops'
$agensiKubectlSkill = Join-Path $agensiPackage 'skills\windows-kubectl-reliable-ops'
$agensiRangeScript = Join-Path $agensiLocalSkill 'scripts\Read-TextRange.ps1'
$agensiPreflightScript = Join-Path $agensiKubectlSkill 'scripts\Test-ExecutionEnvironment.ps1'

# PowerShell parser check without executing the target script.
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($rangeScript, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Read-TextRange.ps1 contains PowerShell syntax errors.' }
$tokens = $null; $parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($sessionScript, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Set-Utf8Session.ps1 contains PowerShell syntax errors.' }

$agensiSkills = @(Get-ChildItem -LiteralPath $agensiPackage -Filter 'SKILL.md' -File -Recurse)
if ($agensiSkills.Count -ne 2) {
    throw "Agensi package must contain exactly two SKILL.md files; found $($agensiSkills.Count)."
}
foreach ($agensiSkill in $agensiSkills) {
    $skillText = Get-Content -LiteralPath $agensiSkill.FullName -Raw -Encoding UTF8
    if ($skillText -notmatch '(?ms)\A---\r?\n.*?^name:\s*\S+.*?^description:\s*\S+.*?^---\r?\n') {
        throw "Agensi skill has invalid required frontmatter: $($agensiSkill.FullName)"
    }
}

$blockedExtensions = @('.exe', '.dll', '.so', '.dylib', '.bin', '.app', '.dmg', '.msi', '.deb', '.rpm', '.wasm', '.class', '.jar', '.war')
$blockedFiles = @(Get-ChildItem -LiteralPath $agensiPackage -File -Recurse | Where-Object { $_.Extension -in $blockedExtensions })
if ($blockedFiles.Count -gt 0) {
    throw "Agensi package contains blocked executable types: $($blockedFiles.FullName -join ', ')"
}

$agensiScripts = @(Get-ChildItem -LiteralPath $agensiPackage -Filter '*.ps1' -File -Recurse)
foreach ($agensiScript in $agensiScripts) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($agensiScript.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw "Agensi script contains PowerShell syntax errors: $($agensiScript.FullName)"
    }
    $scriptText = Get-Content -LiteralPath $agensiScript.FullName -Raw -Encoding UTF8
    if ($scriptText -match '\$PSScriptRoot') {
        throw "Agensi script depends on a package-relative path: $($agensiScript.FullName)"
    }
}

$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$tmpRoot = Join-Path $tempBase ('windows-ops-test-' + [Guid]::NewGuid().ToString('N'))
$tmp = Join-Path $tmpRoot 'range-input.txt'
try {
    [void][System.IO.Directory]::CreateDirectory($tmpRoot)
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

    $agensiActual = (& $agensiRangeScript -Path $tmp -StartLine 101 -Count 5) -join "`n"
    if ($agensiActual -notmatch '101: 第101 行' -or $agensiActual -notmatch 'MORE=true TRUNCATED=false') {
        throw 'Agensi range script did not preserve bounded UTF-8 behavior.'
    }

    $preflightText = (& $agensiPreflightScript -Workspace $tmpRoot) -join "`n"
    $preflight = $preflightText | ConvertFrom-Json
    if (-not $preflight.workspace_write.ok) {
        throw "Agensi preflight could not verify temporary workspace writes: $($preflight.workspace_write.error)"
    }
    if (Test-Path -LiteralPath (Join-Path $tmpRoot '.windows-ops-preflight')) {
        throw 'Agensi preflight did not clean up its probe directory.'
    }

    Write-Output 'PASS: native and Agensi scripts parse; MCP package layout, self-contained execution, UTF-8 range, EOF, truncation and preflight cleanup verified.'
} finally {
    $resolvedTmpRoot = [System.IO.Path]::GetFullPath($tmpRoot)
    if (-not $resolvedTmpRoot.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean unexpected test directory: $resolvedTmpRoot"
    }
    if (Test-Path -LiteralPath $resolvedTmpRoot) {
        [System.IO.Directory]::Delete($resolvedTmpRoot, $true)
    }
}
