<#
.SYNOPSIS
    Create new Rust AppVeyor build pack.

.DESCRIPTION
    Create new Rust AppVeyor build pack.
#>
#Requires -Version 5

[CmdletBinding()]
param(
    [switch] $Trace
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

function main {
    [OutputType([void])]
    param()

    $sourceDir = Resolve-Path -Path $PSScriptRoot\src
    git describe --long --dirty --match='v[0-9]*' > $sourceDir\version.txt
    $zipPath = Join-Path -Path $PSScriptRoot -ChildPath rust-appveyor-build-pack.zip
    Compress-Archive `
        -Force `
        -DestinationPath $zipPath `
        -CompressionLevel Optimal `
        -Path $sourceDir\*
}

Write-Output 'New-RustAppVeyorBuildPack'
main
