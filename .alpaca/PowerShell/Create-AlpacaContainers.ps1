param (
    [string]$token,
    [string]$projectsJson = "$($ENV:ProjectsJson)"
)

Import-Module ".\.alpaca\PowerShell\module\alpaca-functions.psd1" -Scope Global -Force -DisableNameChecking

$projects = $projectsJson | ConvertFrom-Json

$owner = $Env:GITHUB_REPOSITORY_OWNER
$repository = $Env:GITHUB_REPOSITORY
$repository = $repository.replace($owner, "")
$repository = $repository.replace("/", "")
$branch = $Env:GITHUB_HEAD_REF
# $Env:GITHUB_HEAD_REF is specified only for pull requests, so if it is not specified, use GITHUB_REF_NAME
if (!$branch) {
    $branch = $Env:GITHUB_REF_NAME
}

Write-Host "Starting container for $owner/$repository and ref $branch (projects: $($projects -join ', '))"

$headers = Get-AuthenticationHeader -token $token -owner $owner -repository $repository
$headers.add("Content-Type", "application/json")

$config = Get-ConfigNameForWorkflowName 

$QueryParams = @{
    "api-version" = "0.12"
}
$apiUrl = Get-AlpacaEndpointUrlWithParam -controller "Container" -endpoint "GitHub/Build" -QueryParams $QueryParams

$containers = @{}

foreach ($project in $projects) {
    Write-Host "Starting container for project $project"

    $body = @{
        source = @{
            owner = "$owner"
            repo = "$repository"
            branch = "$branch"
            project = "$($project -replace '^\.$', '_')"
        }
        containerConfiguration = "$config"
        workflow = @{
            actor = "$($Env:GITHUB_ACTOR)"
            workflowName = "$($Env:GITHUB_WORKFLOW)"
            WorkflowRef = "$($Env:GITHUB_WORKFLOW_REF)"
            RunID = "$($Env:GITHUB_RUN_ID)"
            Repository = "$($Env:GITHUB_REPOSITORY)"
        }
    }

    $response = Invoke-RestMethod $apiUrl -Method 'POST' -Headers $headers -Body $body -AllowInsecureRedirect

    $container = @{
        Id = $response.id
        User = $response.username
        Password = $response.Password
        Url = $response.webUrl
    }
    $containers.Add($project, $container)
    Write-Host Created container $container.Id
}

$containersJson = $containers | ConvertTo-Json -Depth 99 -Compress

Write-Output ContainersJson=$containersJson >> $ENV:GITHUB_OUTPUT
Write-Host Created $containers.Keys.Length containers