<#
.SYNOPSIS
    Test step.

.DESCRIPTION
    Test step.
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

Import-Module -Name $PSScriptRoot\common -Force

function main {
    [OutputType([void])]
    param()

    $cargoBinDir = Resolve-Path -Path "$(Get-HomeDir)\.cargo\bin"
    $savedPath = $env:PATH
    $env:PATH = $env:PATH + [System.IO.Path]::PathSeparator + $cargoBinDir
    try {
        Invoke-ExternalCommand cargo test
        Invoke-ExternalCommand cargo test --release
    }
    finally {
        $env:PATH = $savedPath
    }
}

Write-Output 'Test step'
main
