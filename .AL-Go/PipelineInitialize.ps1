$needsContext = "$($env:NeedsContext)" | ConvertFrom-Json

$initializationJob = $needsContext.'CustomJob-Alpaca-Initialization'
$createContainersJob = $needsContext.'CustomJob-CreateAlpaca-Container'

$scriptsPath = "./.alpaca/Scripts/"
$scriptsArchiveUrl = $initializationJob.outputs.scriptsArchiveUrl
$scriptsArchiveDirectory = $initializationJob.outputs.scriptsArchiveDirectory

Write-Host "Preparing Alpaca scripts directory at '$scriptsPath'"
if (Test-Path -Path $scriptsPath) {
    Remove-Item -Path $scriptsPath -Recurse -Force
}
New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null

if ($scriptsArchiveUrl) {
    try {
        $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        $tempArchivePath = "$tempPath.zip"

        Write-Host "Downloading Alpaca scripts archive from '$scriptsArchiveUrl'"
        Invoke-WebRequest -Uri $scriptsArchiveUrl -OutFile $tempArchivePath

        Write-Host "Extracting Alpaca scripts archive"
        Expand-Archive -Path $tempArchivePath -DestinationPath $tempPath -Force

        Write-Host "Copying Alpaca scripts to '$scriptsPath'"
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
Get-ChildItem -Path $scriptsPath -File -Recurse | ForEach-Object {
    Write-Host "- '$(Resolve-Path -Path $_.FullName -Relative)'"
}

$overridePath = Join-Path $scriptsPath "/Overrides/RunAlPipeline/PipelineInitialize.ps1"
Write-Host "Override path: $overridePath"
if (Test-Path $overridePath) {
    Write-Host "Invoking Alpaca override"
    . $overridePath -ScriptsPath $scriptsPath -InitializationJob $initializationJob -CreateContainersJob $createContainersJob
}