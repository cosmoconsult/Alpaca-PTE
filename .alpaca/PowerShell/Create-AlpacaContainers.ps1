param (
    [string]$token
)

try {
    $projects = [string[]]("$($env:ALGO_PROJECTS_JSON)" | ConvertFrom-Json)
    if (! $projects) {
        throw "No AL-Go projects defined."
    }
    Write-Host "Creating containers for projects: '$($projects -join "', '")' [$($projects.Count)]"
} 
catch {
    throw "Failed to determine AL-Go projects: $($_.Exception.Message)"
}

Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

$containers = @()

try {
    foreach ($project in $projects) {
        $containers += New-AlpacaContainer -project $project -token $token
    }
} catch {
    Write-Host "::error::Failed to create container: $($_.Exception.Message)"
    exit 1;
} finally {
    Write-Host "Created $($containers.Count) of $($projects.Count) containers"

    $containersJson = $containers | ConvertTo-Json -Depth 99 -Compress -AsArray
    Add-Content -encoding UTF8 -Path $env:GITHUB_ENV -Value "ALPACA_CONTAINERS_JSON=$($containersJson)"
    Add-Content -encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "containersJson=$($containersJson)"
}