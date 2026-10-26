[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [string[]]$ArgumentList = @(),

    [ValidateRange(1, 10)]
    [int]$MaxAttempts = 4,

    [ValidateRange(1, 60)]
    [int]$InitialDelaySeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Initialize-SessionUtf8.ps1')

$transientPattern = '(?i)(unexpected\s+EOF|\bEOF\b|timed?\s*out|timeout|context deadline exceeded|TLS handshake timeout|connection (?:reset|refused|closed)|temporary failure|no such host|502|503|504|too many requests|rate.?limit|基础连接已经关闭|接收时发生错误|连接.*关闭|超时)'

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $lines = @(& $FilePath @ArgumentList 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    $message = $lines -join [Environment]::NewLine

    if ($exitCode -eq 0) {
        $lines
        exit 0
    }

    $isTransient = $message -match $transientPattern
    if (-not $isTransient -or $attempt -eq $MaxAttempts) {
        [Console]::Error.WriteLine($message)
        exit $exitCode
    }

    $delay = [Math]::Min(30, $InitialDelaySeconds * [Math]::Pow(2, $attempt - 1))
    [Console]::Error.WriteLine("Temporary failure on attempt $attempt/$MaxAttempts; retrying in $delay seconds.")
    Start-Sleep -Seconds $delay
}
