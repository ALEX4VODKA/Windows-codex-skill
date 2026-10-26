[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [ValidateRange(1, 2147483647)]
    [int]$StartLine = 1,

    [ValidateRange(1, 500)]
    [int]$Count = 80,

    [ValidateRange(500, 32000)]
    [int]$MaxChars = 6000,

    [string]$EncodingName = 'utf-8'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "Not a regular file: $resolved"
}

# Strict UTF-8 by default; caller may provide the verified legacy encoding.
if ($EncodingName -eq 'utf-8') {
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
} else {
    $encoding = [System.Text.Encoding]::GetEncoding($EncodingName)
}
$reader = [System.IO.StreamReader]::new($resolved, $encoding, $true)

try {
    $lineNo = 0
    $atEof = $false
    while ($lineNo -lt ($StartLine - 1)) {
        $skipped = $reader.ReadLine()
        if ($null -eq $skipped) {
            $atEof = $true
            break
        }
        $lineNo++
    }

    $emitted = 0
    $budget = $MaxChars
    $truncated = $false
    $more = $false
    Write-Output "BEGIN_RANGE start=$StartLine count=$Count max_chars=$MaxChars"

    while (-not $atEof -and $emitted -lt $Count) {
        $line = $reader.ReadLine()
        if ($null -eq $line) {
            $atEof = $true
            break
        }
        $lineNo++
        $emitted++
        $render = ('{0,6}: ' -f $lineNo) + $line
        if ($render.Length -gt $budget) {
            if ($budget -gt 0) {
                Write-Output ($render.Substring(0, $budget))
            }
            Write-Output "[INCOMPLETE_LINE line=$lineNo; output character limit reached]"
            $truncated = $true
            $more = $true
            break
        }
        Write-Output $render
        $budget -= $render.Length
    }
    if (-not $atEof -and -not $truncated) {
        $more = ($null -ne $reader.ReadLine())
    }
    $moreString = $more.ToString().ToLowerInvariant()
    $truncatedString = $truncated.ToString().ToLowerInvariant()
    Write-Output "END_RANGE emitted=$emitted last_line=$lineNo MORE=$moreString TRUNCATED=$truncatedString"
} finally {
    $reader.Dispose()
}
