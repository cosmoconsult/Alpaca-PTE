# Backward compatibility script to create Alpaca container

param (
    [string]$token
)

Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

try {
    $container = New-AlpacaContainer -project '.' -token $token
} catch {
    Write-Host "::error::Failed to create container: $($_.Exception.Message)"
    exit 1;
} finally {
    Add-Content -encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "containerID=$($container.id)"
    Add-Content -encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "containerUser=$($container.username)"
    Add-Content -encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "containerPassword=$($container.password)"
    Add-Content -encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "containerURL=$($container.webUrl)"
}