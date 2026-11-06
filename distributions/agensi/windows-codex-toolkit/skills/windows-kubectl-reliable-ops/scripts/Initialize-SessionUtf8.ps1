[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::InputEncoding = $utf8NoBom
    [Console]::OutputEncoding = $utf8NoBom
} catch {
    Write-Warning 'Console encoding cannot be set by this host; use explicit encodings in file operations.'
}
$global:OutputEncoding = $utf8NoBom

if ($null -eq $global:PSDefaultParameterValues) {
    $global:PSDefaultParameterValues = @{}
}
$global:PSDefaultParameterValues['*:Encoding'] = 'utf8'

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
