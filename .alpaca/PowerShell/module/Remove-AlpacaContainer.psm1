function Remove-AlpacaContainer {
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject]$container,
        [Parameter(Mandatory = $true)]
        [string]$token
    )

    $owner = $env:GITHUB_REPOSITORY_OWNER
    $repository = $env:GITHUB_REPOSITORY
    $repository = $repository.replace($owner, "")
    $repository = $repository.replace("/", "")

    Write-Host "Deleting Container '$($container.Id)' of project '$($container.Project)'"

    $headers = Get-AuthenticationHeaders -token $token -owner $owner -repository $repository

    $QueryParams = @{
        "api-version" = "0.12"
    }        
    $apiUrl = Get-AlpacaEndpointUrlWithParam -controller "Container" -ressource $container.Id -QueryParams $QueryParams
    
    Invoke-RestMethod $apiUrl -Method 'DELETE' -Headers $headers -AllowInsecureRedirect | Out-Null
        
    Write-Host "Deleted Container '$($container.Id)'"
}
Export-ModuleMember -Function Remove-AlpacaContainer