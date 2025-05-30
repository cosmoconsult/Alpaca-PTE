function Get-AlpacaBackendUrl {
    $backendUrl = $ENV:ALPACA_BACKEND_URL
    if ([string]::IsNullOrWhiteSpace($backendUrl)) {
        $backendUrl = "https://cosmo-alpaca-enterprise.westeurope.cloudapp.azure.com/"
    }
    elseif ($backendUrl -notlike "*/") {
        $backendUrl = $backendUrl + "/"
    }
    return $backendUrl
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
        [Parameter(Mandatory = $true)]
        [string]$owner,
        [Parameter(Mandatory = $true)]
        [string]$repository
    )
    $headers = @{
        Authorization              = "Bearer $token"
        "Authorization-Owner"      = "$owner"
        "Authorization-Repository" = "$repository"
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