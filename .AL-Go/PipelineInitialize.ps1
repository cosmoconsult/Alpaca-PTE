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
        $tempPath = [System.IO.Path]::GetTempFileName()
        $tempArchivePath = "$tempPath.zip"

        Write-Host "Downloading Alpaca scripts archive from '$scriptsArchiveUrl'"
        Invoke-WebRequest -Uri $scriptsArchiveUrl -OutFile $tempArchivePath

        Write-Host "Extracting Alpaca scripts archive"
        Expand-Archive -Path $tempArchivePath -DestinationPath $tempPath -Force

        Write-Host "Copying Alpaca scripts to '$scriptsPath'"
        Get-ChildItem -Path (Join-Path $tempPath $scriptsArchiveDirectory) | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $scriptsPath -Force
        }
    }
    catch {
        throw
    }
    finally {
        if ($tempPath -and (Test-Path $tempPath)) {
            Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
        }
        if ($tempArchivePath -and (Test-Path $tempArchivePath)) {
            Remove-Item -Path $tempArchivePath -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Alpaca scripts found:"
Get-ChildItem -Path $scriptsPath -File -Recurse | ForEach-Object {
    Write-Host "- '$($_.FullName)'"
}

$overridePath = Join-Path $scriptsPath "/Override/RunAlPipeline/PipelineInitialize.ps1"
if (Test-Path $overridePath) {
    Write-Host "Invoking Alpaca override"
    . $overridePath -ScriptsPath $scriptsPath -InitializationJob $initializationJob -CreateContainersJob $createContainersJob
}