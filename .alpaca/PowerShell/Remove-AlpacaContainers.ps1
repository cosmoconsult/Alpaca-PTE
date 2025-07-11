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

$errors = @()

foreach ($container in $containers) {
    try {
        Remove-AlpacaContainer -container $container -token $token
    } catch {
        $errors += "Failed to delete container '$($container.Id)': $($_.Exception.Message)"
    }
}

Write-Host "Deleted $($containers.Count - $errors.Count) of $($containers.Count) containers"
if ($errors.Count -gt 0) {
    throw ($errors -join "`n")
}