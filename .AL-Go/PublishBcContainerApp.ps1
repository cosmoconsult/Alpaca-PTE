Param([Hashtable]$parameters) 

$Needs=$ENV:NeedsContext | ConvertFrom-Json
$containerConfig = $Needs."CustomJob-CreateAlpaca-Container".outputs

if (!$Env:ContainerStarted){
    Write-Host "::group::Wait for image to be ready"
    Wait-ForImage -token $Env:_token -containerName $containerConfig.containerID
    Write-Host "::endgroup::"
    Write-Host "::group::Wait for container start"
    Wait-ForAlpacaContainer -token $Env:_token -containerName $containerConfig.containerID
    Write-Host "::endgroup::"
}

Write-Host Get password from SecureString
$password=ConvertFrom-SecureString -SecureString $parameters.bcAuthContext.Password -AsPlainText

Publish-BCAppToDevEndpoint -containerUrl $parameters.Environment `
                           -containerUser $parameters.bcAuthContext.username `
                           -containerPassword $password `
                           -path $parameters.appFile