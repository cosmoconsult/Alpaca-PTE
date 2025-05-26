function Get-DependencyApps {
    Param(
        $packagesFolder,
        $token
    )

    $owner = $Env:GITHUB_REPOSITORY_OWNER
    $repository = $Env:GITHUB_REPOSITORY
    $repository = $repository.replace($owner, "")
    $repository = $repository.replace("/", "")
    $branch = $Env:GITHUB_REF_NAME

    Write-Host "Starting container for $owner/$repository and ref $branch"

    $headers = Get-AuthenticationHeader -token $token -owner $owner -repository $repository
    $headers.add("Content-Type", "application/json")

    $config = Get-ConfigNameForWorkflowName 

    $body = @"
    {
        "source": {
            "owner": "$owner",
            "repo": "$repository",
            "branch": "$branch"
        },
        "containerConfiguration": "$config",
        "workflow": {
            "actor": "$($Env:GITHUB_ACTOR)",
            "workflowName": "$($Env:GITHUB_WORKFLOW)",
            "WorkflowRef": "$($Env:GITHUB_WORKFLOW_REF)",
            "RunID": "$($Env:GITHUB_RUN_ID)",
            "Repository": "$($Env:GITHUB_REPOSITORY)"
        }
    }
"@

    $QueryParams = @{
        "api-version" = "0.12"
    }
    $apiUrl = Get-AlpacaEndpointUrlWithParam -controller "Container" -endpoint "GitHub/GetBuildContainerArtifacts" -QueryParams $QueryParams
    $artifacts = Invoke-RestMethod $apiUrl -Method 'GET' -Headers $headers -Body $body -AllowInsecureRedirect

    foreach ($artifact in $artifacts) {
        if ($artifact.target -eq 'App') {
            if ($artifact.type -eq 'Url') {
                Write-Host "::group::Downloading $($artifact.name) from $($artifact.url)"
                
                $tempArchive = "$([System.IO.Path]::GetTempFileName()).zip"
                $tempFolder = ([System.IO.Path]::GetRandomFileName())
                Invoke-WebRequest -Uri $artifact.url -OutFile $tempArchive
                Expand-Archive -Path $tempArchive -DestinationPath $tempFolder -Force

                Write-Host "Extracted files:"
                
                Get-ChildItem -Path $tempFolder -Recurse -File | ForEach-Object {
                    Write-Host "- $($_.FullName)"

                    # Move file to PackagesFolder
                    $destinationPath = Join-Path $packagesFolder $_.Name
                    if (-not (Test-Path $destinationPath)) {
                        Write-Host "  Moving to PackagesFolder..."
                        Move-Item -Path $_.FullName -Destination $destinationPath -Force
                    }
                    else {
                        Write-Host "  Ignoring... file already exists in PackagesFolder"
                    }
                }

                # Clean up temporary files
                if (Test-Path $tempArchive) {
                    Remove-Item -Path $tempArchive -Force -ErrorAction SilentlyContinue
                }
                if (Test-Path $tempFolder) {
                    Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-Host "::endgroup::"
            }
            else {
                Write-Host "NuGet handled by AL-Go $($artifact.name)"
            }
        }
    }

    Write-Host "::group::Files in PackagesFolder $packagesFolder"
    $files = Get-ChildItem -Path $packagesFolder -File
    foreach ($file in $files) {
        Write-Host "- $($file.Name)"
    }
    Write-Host "::endgroup::"
}

Export-ModuleMember -Function Get-DependencyApps