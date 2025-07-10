Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

$backendUrl = Get-AlpacaBackendUrl
Write-Host "Using Backend Url '$backendUrl'"
Add-Content -encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "backendUrl=$($backendUrl)"