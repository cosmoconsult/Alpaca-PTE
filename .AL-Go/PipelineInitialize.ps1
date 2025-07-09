$project = $Env:_project
$needsContext = "$($Env:NeedsContext)" | ConvertFrom-Json
$containers = @("$($needsContext.'CustomJob-CreateAlpaca-Container'.outputs.containersJson)" | ConvertFrom-Json)
$container = $containers | Where-Object { $_.Project -eq $project }

if (! $container) {
    throw "No container information for project '$project' found in needs context."
}

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