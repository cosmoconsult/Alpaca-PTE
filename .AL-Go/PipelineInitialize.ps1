$Needs=$ENV:NeedsContext | ConvertFrom-Json
$containerConfig = $Needs."CustomJob-CreateAlpaca-Container".outputs

$password = ConvertTo-SecureString -String $containerConfig.containerPassword -AsPlainText
$myAuthContext = @{"username"=$containerConfig.containerUser; "Password"=$password}
$myEnvironment = $containerConfig.containerURL

Set-Variable -Name 'bcAuthContext' -value $myAuthcontext -scope 1
Set-Variable -Name 'environment' -value $myEnvironment -scope 1

Write-Host -ForegroundColor Green 'INITIALIZE Auth context successful'

Import-Module (Join-Path $ENV:GITHUB_WORKSPACE "\.alpaca\PowerShell\module\alpaca-functions.psd1") -Scope Global -Force
