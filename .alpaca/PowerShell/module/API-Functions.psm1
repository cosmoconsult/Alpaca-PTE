function Initialize-AlpacaBackend {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$owner
    )
    if (![string]::IsNullOrWhiteSpace($ENV:ALPACA_BACKEND_URL)) {
        exit # Alpaca backend URL is already set, no need to reinitialize
    }

    Write-Host "Initializing Alpaca backend"
    $headers = Get-AuthenticationHeader -token $token -owner $owner
    $headers.add("Content-Type", "application/json")

    $queryParams = @{
        "includeRepos" = "false"
    }
    $apiUrl = Get-AlpacaEndpointUrlWithParam -api "alpaca" -controller "GitHub/Owner" -ressource $owner -QueryParams $queryParams
    $owner = Invoke-RestMethod $apiUrl -Method 'POST' -Headers $headers -AllowInsecureRedirect
    Write-Host "DEBUG: Owner response: $($owner | ConvertTo-Json)"
    if ($owner.backendUrl) {
        $backendUrl = $owner.backendUrl
        if ($backendUrl -notlike "*/") {
            $backendUrl = $backendUrl + "/"
        }
        Write-Host "DEBUG: Setting ALPACA_BACKEND_URL to: $backendUrl"
        $ENV:ALPACA_BACKEND_URL = $backendUrl
    }
}

Export-ModuleMember -Function Initialize-AlpacaBackend

function Get-AlpacaBackendUrl {
    if (![string]::IsNullOrWhiteSpace($ENV:ALPACA_BACKEND_URL)) {
        # Alpaca backend URL is set
        return $ENV:ALPACA_BACKEND_URL
    }
    else {
        # Default backend URL
        #return "https://cosmo-alpaca-enterprise.westeurope.cloudapp.azure.com/"
        return "https://ppi-demo.westeurope.cloudapp.azure.com/"
    }
}

function Get-AlpacaEndpointUrlWithParam {
    Param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("k8s", "alpaca")]
        [string]$api = "k8s",
        [Parameter(Mandatory = $true)]
        [string]$controller,
        [string]$endpoint,
        [string]$ressource,
        [string]$routeSuffix,
        [Hashtable] $QueryParams
    )
    $url = Get-AlpacaBackendUrl
    Write-Host "DEBUG: Using backend Base URL: $url"
    switch ($api) {
        "k8s" { $url = $url + "api/docker/release/" }
        "alpaca" { $url = $url + "api/alpaca/release/" }
    }
    $url = $url + $controller  

    if ($endpoint) {
        $url = $url + "/" + $endpoint 
    }
    
    if ($ressource) {
        $url = $url + "/" + $ressource
    }

    if ($routeSuffix) {
        $url = $url + "/" + $routeSuffix
    }
    
    if ($QueryParams) {
        $url = $url + "?"
        $QueryParams.GetEnumerator() | ForEach-Object {
            $url = $url + $_.Key + "=" + $_.Value + "&"
        }
        $url = $url.TrimEnd("&")
    }
    return $url
}

Export-ModuleMember -Function Get-AlpacaEndpointUrlWithParam

function Get-AuthenticationHeader {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$token,
        [string]$owner,
        [string]$repository
    )
    $headers = @{
        Authorization          = "Bearer $token"
        "Authorization-GitHub" = "$token"
    }
    if ($owner) {
        $headers.add("Authorization-Owner", $owner)
    }
    if ($repository) {
        $headers.add("Authorization-Repository", $repository)
    }
    return $headers
}

Export-ModuleMember -Function Get-AuthenticationHeader

function Get-ConfigNameForWorkflowName {
    switch ($ENV:GITHUB_WORKFLOW) {
        "NextMajor" { return "NextMajor" }
        "NextMinor" { return "NextMinor" }
        default { return "current" }
    }
}

Export-ModuleMember -Function Get-ConfigNameForWorkflowName