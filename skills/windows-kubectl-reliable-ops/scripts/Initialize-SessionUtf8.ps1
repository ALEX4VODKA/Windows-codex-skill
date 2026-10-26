[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$global:OutputEncoding = $utf8NoBom

if ($null -eq $global:PSDefaultParameterValues) {
    $global:PSDefaultParameterValues = @{}
}
$global:PSDefaultParameterValues['*:Encoding'] = 'utf8'

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

