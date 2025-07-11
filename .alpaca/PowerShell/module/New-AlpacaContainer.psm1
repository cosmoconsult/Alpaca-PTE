function New-AlpacaContainer {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$project,
        [Parameter(Mandatory = $true)]
        [string]$token
    )

    $owner = $env:GITHUB_REPOSITORY_OWNER
    $repository = $env:GITHUB_REPOSITORY
    $repository = $repository.replace($owner, "")
    $repository = $repository.replace("/", "")
    $branch = $env:GITHUB_HEAD_REF
    # $Env:GITHUB_HEAD_REF is specified only for pull requests, so if it is not specified, use GITHUB_REF_NAME
    if (!$branch) {
        $branch = $env:GITHUB_REF_NAME
    }

    Write-Host "Creating container for project '$project' of '$owner/$repository' on ref '$branch'"

    $headers = Get-AuthenticationHeaders -token $token -owner $owner -repository $repository
    $headers.add("Content-Type", "application/json")

    $config = Get-ConfigNameForWorkflowName 

    $QueryParams = @{
        "api-version" = "0.12"
    }
    $apiUrl = Get-AlpacaEndpointUrlWithParam -controller "Container" -endpoint "GitHub/Build" -QueryParams $QueryParams

    $request = @{
        source = @{
            owner = "$owner"
            repo = "$repository"
            branch = "$branch"
            project = "$($project -replace '^\.$', '_')"
        }
        containerConfiguration = "$config"
        workflow = @{
            actor = "$($env:GITHUB_ACTOR)"
            workflowName = "$($env:GITHUB_WORKFLOW)"
            WorkflowRef = "$($env:GITHUB_WORKFLOW_REF)"
            RunID = "$($env:GITHUB_RUN_ID)"
            Repository = "$($env:GITHUB_REPOSITORY)"
        }
    }
    
    $body = $request | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod $apiUrl -Method 'POST' -Headers $headers -Body $body -AllowInsecureRedirect

    $container = [pscustomobject]@{
        Project = $project
        Id = $response.id
        User = $response.username
        Password = $response.Password
        Url = $response.webUrl
    }
    
    Write-Host "Created container '$($container.Id)'"

    return $container
}
Export-ModuleMember -Function New-AlpacaContainer