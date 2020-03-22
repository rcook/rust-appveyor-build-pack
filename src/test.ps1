<#
.SYNOPSIS
    rust-appveyor-build-pack test step.

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

    $targetDir = Resolve-Path -Path $PSScriptRoot\..\target
    $cargoBinDir = Resolve-Path -Path "$(Get-HomeDir)\.cargo\bin"
    $savedPath = $env:PATH
    $env:PATH = $env:PATH + [System.IO.Path]::PathSeparator + $cargoBinDir
    try {
        Invoke-ExternalCommand cargo test '--' --logfile (Join-Path -Path $targetDir -ChildPath debug\debug-test.log)
        Invoke-ExternalCommand cargo test --release '--' --logfile (Join-Path -Path $targetDir -ChildPath release\release-test.log)
    }
    finally {
        $env:PATH = $savedPath
    }
}

Write-Host -ForegroundColor Magenta 'Test step'
try {
    main
    Write-Host -ForegroundColor Green 'Test step succeeded'
}
catch {
    Write-Host -ForegroundColor Red 'Test step failed'
    throw
}
