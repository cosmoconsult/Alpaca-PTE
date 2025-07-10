$project = $env:_project
$needsContext = "$($env:NeedsContext)" | ConvertFrom-Json

# Get backend Url from needs context
$backendUrl = $needsContext.'CustomJob-Alpaca-Initialization'.outputs.backendUrl
# Set ALPACA_BACKEND_URL (current script and whole github workflow job)
Write-Host "Setting ALPACA_BACKEND_URL to '$backendUrl'"
$env:ALPACA_BACKEND_URL = $backendUrl
Add-Content -encoding UTF8 -Path $env:GITHUB_ENV -Value "ALPACA_BACKEND_URL=$backendUrl"

# Get Container information from needs context
$containers = @("$($needsContext.'CustomJob-CreateAlpaca-Container'.outputs.containersJson)" | ConvertFrom-Json)
$container = $containers | Where-Object { $_.Project -eq $project }
if (! $container) {
    throw "No Alpaca container information for project '$project' found in needs context."
}
# Set ALPACA_CONTAINER_ID (current script and whole github workflow job)
Write-Host "Setting ALPACA_CONTAINER_ID to '$containerId'"
$env:ALPACA_CONTAINER_ID = $container.Id
Add-Content -encoding UTF8 -Path $env:GITHUB_ENV -Value "ALPACA_CONTAINER_ID=$containerId"

$password = ConvertTo-SecureString -String $container.Password -AsPlainText
$myAuthContext = @{"username" = $container.User; "Password" = $password }
$myEnvironment = $container.Url

Set-Variable -Name 'bcAuthContext' -value $myAuthcontext -scope 1
Set-Variable -Name 'environment' -value $myEnvironment -scope 1

Write-Host -ForegroundColor Green 'INITIALIZE Auth context successful'

Import-Module (Join-Path $ENV:GITHUB_WORKSPACE "\.alpaca\PowerShell\module\alpaca-functions.psd1") -Scope Global -Force -DisableNameChecking

Write-Host Get PackagesFolder
$packagesFolder = CheckRelativePath -baseFolder $baseFolder -sharedFolder $sharedFolder -path $packagesFolder -name "packagesFolder"
if (Test-Path $packagesFolder) {
    Remove-Item $packagesFolder -Recurse -Force
}
New-Item $packagesFolder -ItemType Directory | Out-Null
Write-Host Packagesfolder $packagesFolder

Get-DependencyApps -packagesFolder $packagesFolder -token $Env:_token