param (
    [string]$token,
    [string]$containersJson = "$($ENV:ContainersJson)"
)

Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

$containers = $containersJson | ConvertFrom-Json

$owner = $Env:GITHUB_REPOSITORY_OWNER
$repository = $Env:GITHUB_REPOSITORY
$repository = $repository.replace($owner, "")
$repository = $repository.replace("/", "")

$headers = Get-AuthenticationHeader -token $token -owner $owner -repository $repository

$QueryParams = @{
    "api-version" = "0.12"
}

foreach ($container in $containers.PSObject.Properties.Value) {
    $containerId = $container.Id

    Write-Host "Deleting Container $containerId"
    
    $apiUrl = Get-AlpacaEndpointUrlWithParam -controller "Container" -ressource $containerId -QueryParams $QueryParams
    Invoke-RestMethod $apiUrl -Method 'DELETE' -Headers $headers -AllowInsecureRedirect | Out-Null
    
    Write-Host "Container deleted"
}