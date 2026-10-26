[CmdletBinding()]
param(
    [string]$Workspace = (Get-Location).Path,
    [switch]$ProbeKubernetes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Initialize-SessionUtf8.ps1')

$resolvedWorkspace = (Resolve-Path -LiteralPath $Workspace).Path
$checks = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    workspace = $resolvedWorkspace
    encoding = [ordered]@{
        console_input = [Console]::InputEncoding.WebName
        console_output = [Console]::OutputEncoding.WebName
        powershell_output = $global:OutputEncoding.WebName
        python_utf8 = $env:PYTHONUTF8
        python_io_encoding = $env:PYTHONIOENCODING
    }
}

$probeDir = Join-Path $resolvedWorkspace '.codex-preflight'
$probeFile = Join-Path $probeDir 'write-test.tmp'
try {
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    [System.IO.File]::WriteAllText($probeFile, 'ok', [System.Text.UTF8Encoding]::new($false))
    $checks.workspace_write = [ordered]@{ ok = $true; error = $null }
} catch {
    $checks.workspace_write = [ordered]@{ ok = $false; error = $_.Exception.Message }
} finally {
    if (Test-Path -LiteralPath $probeFile) {
        Remove-Item -LiteralPath $probeFile -Force
    }
    if ((Test-Path -LiteralPath $probeDir) -and -not (Get-ChildItem -LiteralPath $probeDir -Force)) {
        Remove-Item -LiteralPath $probeDir -Force
    }
}

$toolSpecs = @(
    [ordered]@{ name = 'python'; candidates = @('python.exe', 'python'); version_args = @('--version') },
    [ordered]@{ name = 'kubectl'; candidates = @((Join-Path $resolvedWorkspace 'kubectl.exe'), 'kubectl.exe', 'kubectl'); version_args = @('version', '--client=true') },
    [ordered]@{ name = 'rg'; candidates = @($env:RG_EXECUTABLE, (Join-Path $resolvedWorkspace '.tools\ripgrep\rg.exe'), 'rg.exe', 'rg'); version_args = @('--version') }
)

$tools = [ordered]@{}
foreach ($spec in $toolSpecs) {
    $found = $null
    foreach ($candidate in $spec.candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $found = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
        $command = Get-Command $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) {
            $found = $command.Source
            break
        }
    }
    $toolResult = [ordered]@{
        found = ($null -ne $found)
        path = $found
        executable = $false
        version = $null
        error = $null
    }
    if ($null -ne $found) {
        try {
            $versionOutput = @(& $found @($spec.version_args) 2>&1 | ForEach-Object { $_.ToString() })
            $versionExitCode = $LASTEXITCODE
            $toolResult.executable = ($versionExitCode -eq 0)
            $toolResult.version = ($versionOutput -join [Environment]::NewLine)
            if ($versionExitCode -ne 0) {
                $toolResult.error = "Version command exited with code $versionExitCode."
            }
        } catch {
            $toolResult.error = $_.Exception.Message
        }
    }
    $tools[$spec.name] = $toolResult
}
$checks.tools = $tools

if ($ProbeKubernetes) {
    $kubectlPath = $tools.kubectl.path
    if ($null -eq $kubectlPath) {
        $checks.kubernetes_api = [ordered]@{ ok = $false; error = 'kubectl not found' }
    } else {
        $output = @(& $kubectlPath get '--raw=/readyz' '--request-timeout=10s' 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
        $checks.kubernetes_api = [ordered]@{
            ok = ($exitCode -eq 0)
            exit_code = $exitCode
            output = ($output -join [Environment]::NewLine)
        }
    }
}

$checks | ConvertTo-Json -Depth 6
