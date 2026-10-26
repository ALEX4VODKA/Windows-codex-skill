[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [uri]$Uri,

    [Parameter(Mandatory = $true)]
    [string]$OutFile,

    [ValidateRange(1, 10)]
    [int]$MaxAttempts = 4,

    [ValidateRange(1, 60)]
    [int]$InitialDelaySeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Initialize-SessionUtf8.ps1')

$destination = [System.IO.Path]::GetFullPath($OutFile)
$destinationDirectory = Split-Path -Parent $destination
$partial = "$destination.partial"
$transientPattern = '(?i)(unexpected\s+EOF|\bEOF\b|timed?\s*out|timeout|TLS handshake timeout|connection (?:reset|refused|closed)|temporary failure|name resolution|no such host|502|503|504|too many requests|rate.?limit|基础连接已经关闭|接收时发生错误|连接.*关闭|超时)'

New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    try {
        if (Test-Path -LiteralPath $partial) {
            Remove-Item -LiteralPath $partial -Force
        }
        Invoke-WebRequest -Uri $Uri -OutFile $partial
        Move-Item -LiteralPath $partial -Destination $destination -Force
        Get-Item -LiteralPath $destination
        return
    } catch {
        $message = $_.Exception.ToString()
        $isTransient = $message -match $transientPattern
        if (-not $isTransient -or $attempt -eq $MaxAttempts) {
            if (Test-Path -LiteralPath $partial) {
                Remove-Item -LiteralPath $partial -Force
            }
            throw
        }

        $delay = [Math]::Min(30, $InitialDelaySeconds * [Math]::Pow(2, $attempt - 1))
        [Console]::Error.WriteLine("Temporary HTTP failure on attempt $attempt/$MaxAttempts; retrying in $delay seconds.")
        Start-Sleep -Seconds $delay
    }
}
