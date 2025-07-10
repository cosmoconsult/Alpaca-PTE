Param(
    [Hashtable]$parameters
)

if ($parameters.appFile.GetType().BaseType.Name -eq 'Array') {
    # Check if current run is installing dependenciy apps
    # Dependency apps are already installed and should be skipped
    $equal = $true
    for ($i = 0; $i -lt $appsBeforeApps.Count; $i++) {
        if ($appsBeforeApps[$i] -ne $parameters.appFile[$i]) {
            $equal = $false
            break
        }
    }

    if (-not $equal) {
        #check second dependency array
        $equal = $true
        for ($i = 0; $i -lt $appsBeforeTestApps.Count; $i++) {
            if ($appsBeforeTestApps[$i] -ne $parameters.appFile[$i]) {
                $equal = $false
                break
            }
        }
    }

    if ($equal) {
        Write-Host "Skip apps before apps/testapps because they are already handled by Alpaca"
        return
    }
}

if (! $env:ALPACA_CONTAINER_READY){
    Write-Host "::group::Wait for image to be ready"
    Wait-ForImage -token $env:_token -containerName $env:ALPACA_CONTAINER_ID
    Write-Host "::endgroup::"
    Write-Host "::group::Wait for container start"
    Wait-ForAlpacaContainer -token $env:_token -containerName $env:ALPACA_CONTAINER_ID
    Write-Host "::endgroup::"

    # Set ALPACA_CONTAINER_READY (current script and whole github workflow job)
    $env:ALPACA_CONTAINER_READY = $true
    Add-Content -encoding UTF8 -Path $env:GITHUB_ENV -Value "ALPACA_CONTAINER_READY=$true"
}

Write-Host Get password from SecureString
$password=ConvertFrom-SecureString -SecureString $parameters.bcAuthContext.Password -AsPlainText

Publish-BCAppToDevEndpoint -containerUrl $parameters.Environment `
                           -containerUser $parameters.bcAuthContext.username `
                           -containerPassword $password `
                           -path $parameters.appFile