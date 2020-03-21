<#
.SYNOPSIS
    Build step.

.DESCRIPTION
    Build step.
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

function fixUpCargoToml {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [object] $BuildInfo
    )

    $version = $BuildInfo.Version
    $cargoVersion = ''
    if ($version.Major -eq $null) {
        $cargoVersion += '0'
    }
    else {
        $cargoVersion += $version.Major
    }
    $cargoVersion += '.'
    if ($version.Minor -eq $null) {
        $cargoVersion += '0'
    }
    else {
        $cargoVersion += $version.Minor
    }
    $cargoVersion += '.'
    if ($version.Patch -eq $null) {
        $cargoVersion += '0'
    }
    else {
        $cargoVersion += $version.Patch
    }

    $cargoTomlPath = Resolve-Path -Path "$($BuildInfo.BuildDir)\Cargo.toml"
    $content = Get-Content -Path $cargoTomlPath -Raw
    $content = $content -replace 'version = ".+"', "version = `"$cargoVersion`""
    $content = $content -replace 'description = ".+"', "description = `"$($BuildInfo.Version.FullVersion)`""
    $content | Out-File -Encoding ascii -FilePath $cargoTomlPath -NoNewline
}

function main {
    [OutputType([void])]
    param()

    if (Get-IsAppVeyorBuild) {
        $buildInfo = Get-AppVeyorBuildInfo
    }
    else {
        $buildInfo = Get-LocalBuildInfo
    }

    $baseName = "$($buildInfo.ProjectSlug)-$($buildInfo.Version.FullVersion)"

    fixUpCargoToml -BuildInfo $buildInfo

    $cargoBinDir = Resolve-Path -Path "$(Get-HomeDir)\.cargo\bin"
    $savedPath = $env:PATH
    $env:PATH = $env:PATH + [System.IO.Path]::PathSeparator + $cargoBinDir
    try {
        Invoke-ExternalCommand cargo build
        Invoke-ExternalCommand cargo build --release
    }
    finally {
        $env:PATH = $savedPath
    }

    $targetDir = Resolve-Path -Path "$($buildInfo.BuildDir)\target"

    $distDir = Join-Path -Path $targetDir -ChildPath dist
    if (Test-Path -Path $distDir) {
        Remove-Item -Force -Recurse -Path $distDir
    }
    New-Item -ErrorAction Ignore -ItemType Directory -Path $distDir | Out-Null
    $distDir = Resolve-Path -Path $distDir

    Write-Output $buildInfo | Out-File -Encoding ascii -FilePath $distDir\build.txt
    Write-Output $buildInfo.Version | Out-File -Encoding ascii -FilePath $distDir\version.txt

    $versionPath = Resolve-Path -Path $distDir\version.txt
    $executablePath = Resolve-Path -Path "$targetDir\release\$(Get-ExecutableFileName -BaseName hello-world)"
    $stagingDir = Join-Path -Path $distDir -ChildPath $baseName
    New-Item -ErrorAction Ignore -ItemType Directory -Path $stagingDir | Out-Null
    Copy-Item -Path $versionPath -Destination $stagingDir
    Copy-Item -Path $executablePath -Destination $stagingDir

    $zipPath = Join-Path -Path $distDir -ChildPath "$baseName.zip"
    & 7z a $zipPath $stagingDir\*
}

Write-Output 'Build step'
main
