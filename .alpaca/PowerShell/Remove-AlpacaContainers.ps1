param (
    [string]$token
)

try {
    $containers = [pscustomobject[]]("$($env:ALPACA_CONTAINERS_JSON)" | ConvertFrom-Json)
    Write-Host "Deleting containers: '$($containers.Id -join "', '")' [$($containers.Count)]"
} 
catch {
    throw "Failed to determine containers: $($_.Exception.Message)"
}

Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

$failures = 0

foreach ($container in $containers) {
    try {
        Remove-AlpacaContainer -container $container -token $token
    } catch {
        Write-Host "::error::Failed to delete container '$($container.Id)': $($_.Exception.Message)"
        $failures += 1
    }
}

Write-Host "Deleted $($containers.Count - $failures) of $($containers.Count) containers"
if ($failures) {
    exit 1
}