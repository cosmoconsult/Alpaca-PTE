Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

$backendUrl = Get-AlpacaBackendUrl

Write-Output "backendUrl=$($backendUrl)" >> $ENV:GITHUB_OUTPUT
Write-Host "Backend URL: $backendUrl"