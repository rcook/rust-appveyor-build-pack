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

function buildCargoTargets {
    [OutputType([string[]])]
    param()

    $cargoBinDir = Resolve-Path -Path "$(Get-HomeDir)\.cargo\bin"
    $savedPath = $env:PATH
    $env:PATH = $env:PATH + [System.IO.Path]::PathSeparator + $cargoBinDir
    try {
        Invoke-ExternalCommand cargo build
        Invoke-ExternalCommand cargo build --release
        $targetNames = (Invoke-ExternalCommand cargo read-manifest | ConvertFrom-Json).'targets'.'name'
    }
    finally {
        $env:PATH = $savedPath
    }

    $targetNames
}

class DirInfo {
    [object] $TargetDir
    [object] $DistDir
    [object] $StagingDir
}

function createDirs {
    $targetDir = Resolve-Path -Path "$($buildInfo.BuildDir)\target"

    $distDir = Join-Path -Path $targetDir -ChildPath dist
    if (Test-Path -Path $distDir) {
        Remove-Item -Force -Recurse -Path $distDir
    }
    New-Item -ErrorAction Ignore -ItemType Directory -Path $distDir | Out-Null
    $distDir = Resolve-Path -Path $distDir

    $stagingDir = Join-Path -Path $targetDir -ChildPath staging
    if (Test-Path -Path $stagingDir) {
        Remove-Item -Force -Recurse -Path $stagingDir
    }
    New-Item -ErrorAction Ignore -ItemType Directory -Path $stagingDir | Out-Null

    [DirInfo] @{
        TargetDir = $targetDir
        DistDir = $distDir
        StagingDir = $stagingDir
    }
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

    $targetNames = buildCargoTargets

    $dirInfo = createDirs

    Write-Output $buildInfo | Out-File -Encoding ascii -FilePath "$($dirInfo.DistDir)\build.txt"
    Write-Output $buildInfo.Version | Out-File -Encoding ascii -FilePath "$($dirInfo.DistDir)\version.txt"

    Copy-Item `
        -Path "$($dirInfo.DistDir)\version.txt" `
        -Destination "$($dirInfo.StagingDir)\$($buildInfo.ProjectSlug).txt"
    $targetNames | ForEach-Object {
        $targetPath = Resolve-Path -Path "$($dirInfo.TargetDir)\release\$(Get-ExecutableFileName -BaseName $_)"
        Copy-Item -Path $targetPath -Destination $dirInfo.StagingDir
    }

    $zipPath = Join-Path -Path $dirInfo.DistDir -ChildPath "$($buildInfo.ProjectSlug).zip"
    $files = Get-ChildItem -Path $dirInfo.StagingDir
    if (Get-IsWindows) {
        & 7z a $zipPath $files
    }
    elseif ((Get-IsLinux) -or (Get-IsMacOS)) {
        & zip -j $zipPath $files
    }
    else {
        throw 'Unsupported platform'
    }
}

Write-Output 'Build step'
main
