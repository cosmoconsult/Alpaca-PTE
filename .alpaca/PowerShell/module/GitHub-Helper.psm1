function Write-GitHubWorkflowLog {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Command,
        [string]$LineDelimiter = "`n",
        [string]$LinePrefix,
        [string]$LineSuffix
    )

    $messageLines = $Message -split '\r?\n' | ForEach-Object { "$LinePrefix$_$LineSuffix" }
    
    $formattedMessage = "$Command$($messageLines -join $LineDelimiter)"

    Write-Host "$formattedMessage"
}
Export-ModuleMember -Function Write-GitHubWorkflowLog

function Write-GitHubWorkflowError {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [switch]$AsAnnotation,
        [string]$LinePrefix = "`e[31m",
        [string]$LineSuffix = "`e[0m"
    )
    $parameters = @{
        Message    = $Message
        LinePrefix = $LinePrefix
        LineSuffix = $LineSuffix
    }

    if ($AsAnnotation) {
        $parameters.Command = "::error::"
        $parameters.LineDelimiter = '%0A'
    }
    
    Write-GitHubWorkflowLog @parameters
}
Export-ModuleMember -Function Write-GitHubWorkflowError
