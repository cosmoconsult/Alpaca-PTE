# Backward compatibility script to remove Alpaca container

param (
    [string]$token
)

$Needs = $ENV:needsContext | ConvertFrom-Json
$container = [pscustomobject]@{
    Project = '.'
    Id      = $Needs."CustomJob-CreateAlpaca-Container".outputs.containerId
}
if (! $container.Id) {
    throw "Failed to determine container"
}

Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

try {
    Remove-AlpacaContainer -container $container -token $token
} catch {
    Write-Host "::error::Failed to delete container '$($container.Id)': $($_.Exception.Message)"
    exit 1
}