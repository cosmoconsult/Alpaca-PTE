Write-Host "::group::PipelineInitialize"

$needsContext = "$($env:NeedsContext)" | ConvertFrom-Json

$initializationJob = $needsContext.'CustomJob-Alpaca-Initialization'
$createContainersJob = $needsContext.'CustomJob-CreateAlpaca-Container'

$scriptsPath = "./.alpaca/Scripts/"
$scriptsArchiveUrl = $initializationJob.outputs.scriptsArchiveUrl
$scriptsArchiveDirectory = $initializationJob.outputs.scriptsArchiveDirectory

Write-Host "Prepare Alpaca scripts directory at '$scriptsPath'"
if (Test-Path -Path $scriptsPath) {
    Remove-Item -Path $scriptsPath -Recurse -Force
}
New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null

if ($scriptsArchiveUrl) {
    try {
        $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        $tempArchivePath = "$tempPath.zip"

        Write-Host "Download Alpaca scripts archive from '$scriptsArchiveUrl'"
        Invoke-WebRequest -Uri $scriptsArchiveUrl -OutFile $tempArchivePath

        Write-Host "Extract Alpaca scripts archive"
        Expand-Archive -Path $tempArchivePath -DestinationPath $tempPath -Force

        Write-Host "Copy Alpaca scripts to '$scriptsPath'"
        Get-Item -Path (Join-Path $tempPath $scriptsArchiveDirectory) | 
            Get-ChildItem | 
            ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $scriptsPath -Recurse -Force
            }
    }
    catch {
        throw
    }
    finally {
        if ($tempPath -and (Test-Path $tempPath)) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($tempArchivePath -and (Test-Path $tempArchivePath)) {
            Remove-Item -Path $tempArchivePath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Alpaca scripts found:"
$scriptFiles = Get-ChildItem -Path $scriptsPath -File -Recurse
if ($scriptFiles) {
    $scriptFiles | ForEach-Object {
        Write-Host "- $(Resolve-Path -Path $_.FullName -Relative)"
    }
} else {
    Write-Host "- None"
}

$overridesPath = Join-Path $scriptsPath "/Overrides/RunAlPipeline" 
Write-Host "Alpaca overrides path: $overridesPath"
$overridePath = Join-Path $overridesPath "PipelineInitialize.ps1"
if (Test-Path $overridePath) {
    Write-Host "Invoking Alpaca override"
    . $overridePath -ScriptsPath $scriptsPath -InitializationJob $initializationJob -CreateContainersJob $createContainersJob
}

Write-Host "::endgroup::"