[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ArtifactsDirectory,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
& python (Join-Path $PSScriptRoot 'smoke_windows_portable.py') `
    --artifacts-directory $ArtifactsDirectory --output-directory $OutputDirectory
exit $LASTEXITCODE
