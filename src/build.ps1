<#
.SYNOPSIS
    rust-appveyor-build-pack build step.

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

    $lines = [string[]] (Get-Content -Path $cargoTomlPath)
    for ($i = 0; $i -lt $lines.Length; ++$i) {
        $lines[$i] = $lines[$i] -replace '^version = ".+"', "version = `"$cargoVersion`""
        $lines[$i] = $lines[$i] -replace '^description = ".+"', "description = `"$($BuildInfo.Version.FullVersion)`""
    }

    $content = $lines -join "`n"
    $content | Out-File -Encoding ascii -FilePath $cargoTomlPath
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
        $targetNames = (Invoke-ExternalCommand -Capture cargo read-manifest | ConvertFrom-Json).'targets'.'name'
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
        TargetDir  = $targetDir
        DistDir    = $distDir
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

    fixUpCargoToml -BuildInfo $buildInfo

    $targetNames = buildCargoTargets

    $dirInfo = createDirs

    Set-Content -Encoding ascii -Path "$($dirInfo.DistDir)\build.txt" -Value ($buildInfo | Out-String).Trim()
    Set-Content -Encoding ascii -Path "$($dirInfo.DistDir)\version.txt" -Value ($buildInfo.Version | Out-String).Trim()

    Copy-Item `
        -Path "$($dirInfo.DistDir)\version.txt" `
        -Destination "$($dirInfo.StagingDir)\$($buildInfo.ProjectSlug).txt"
    $targetNames | ForEach-Object {
        $targetPath = Resolve-Path -ErrorAction Ignore -Path "$($dirInfo.TargetDir)\release\$(Get-ExecutableFileName -BaseName $_)"
        if ($null -eq $targetPath) {
            Write-Host "No executable found for target $_"
        }
        else {
            Write-Host "Found executable $targetPath found for target $_"
            Copy-Item -Path $targetPath -Destination $dirInfo.StagingDir
        }
    }

    $zipPath = Join-Path -Path $dirInfo.DistDir -ChildPath "$($buildInfo.ProjectSlug)-$($buildInfo.Version.PlatformId).zip"
    if (Get-IsWindows) {
        Get-ChildItem -Path $dirInfo.StagingDir | Compress-Archive `
            -DestinationPath $zipPath `
            -CompressionLevel Optimal
    }
    elseif ((Get-IsLinux) -or (Get-IsMacOS)) {
        $files = Get-ChildItem -Path $dirInfo.StagingDir
        & zip -j $zipPath $files
    }
    else {
        throw 'Unsupported platform'
    }
}

Write-Host -ForegroundColor Magenta 'Build step'
try {
    main
    Write-Host -ForegroundColor Green 'Build step succeeded'
}
catch {
    Write-Host -ForegroundColor Red 'Build step failed'
    throw
}
