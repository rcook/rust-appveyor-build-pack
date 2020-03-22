<#
.SYNOPSIS
    rust-appveyor-build-pack install step.

.DESCRIPTION
    Install step.
#>
#Requires -Version 5

[CmdletBinding()]
param(
    [switch] $DumpEnv,
    [switch] $Detailed,
    [switch] $NoRustupInit,
    [switch] $Trace
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

Import-Module -Name $PSScriptRoot\common -Force

function dumpEnv {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Detailed
    )

    $thisDir = $PSScriptRoot
    $currentDir = Get-Location

    $versionPath = Resolve-Path -Path $currentDir\rust-appveyor-build-pack\version.txt
    Write-Host -Foreground Blue "rust-appveyor-build-pack version $(Get-Content -Path $versionPath)"

    Write-Host "isLinux: $(Get-IsLinux)"
    Write-Host "isMacOS: $(Get-IsMacOS)"
    Write-Host "isWindows: $(Get-IsWindows)"
    Write-Host "executableFileName: $(Get-ExecutableFileName -BaseName base-name)"
    Write-Host "thisDir: $thisDir"
    Write-Host "currentDir: $currentDir"

    Write-Host 'Git tags:'
    Invoke-ExternalCommand -Capture git tag | ForEach-Object {
        Write-Host "  $_ $(Invoke-ExternalCommand -Capture git rev-list -n 1 $_)"
    }

    Write-Host 'Git branches:'
    Invoke-ExternalCommand -Capture git branch -vv -a --color=never | ForEach-Object {
        Write-Host "  $_"
    }

    Write-Host 'Git describe:'
    Write-Host "  $(Invoke-ExternalCommand -Capture git describe --long --dirty)"

    if (Get-IsAppVeyorBuild) {
        $buildInfo = Get-AppVeyorBuildInfo
        Write-Host $buildInfo
        Write-Host $buildInfo.Version
    }

    if ($Detailed) {
        Write-Host 'Environment:'
        Get-ChildItem -Path Env: | Sort-Object Key | ForEach-Object {
            Write-Host "  $($_.Key) = $($_.Value)"
        }

        Write-Host "Files under $($thisDir):"
        Get-ChildItem -Force -Recurse -Path $thisDir | Sort-Object FullName | ForEach-Object {
            Write-Host "  $($_.FullName)"
        }

        if ($thisDir -ne $currentDir) {
            Write-Host "Files under $($currentDir):"
            Get-ChildItem -Force -Recurse -Path $currentDir | Sort-Object FullName | ForEach-Object {
                Write-Host "  $($_.FullName)"
            }
        }

        Write-Host 'Git log:'
        Invoke-ExternalCommand -Capture git log --oneline --color=never | ForEach-Object {
            Write-Host "  $_"
        }
    }
}

function main {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $DumpEnv,
        [Parameter(Mandatory = $true)]
        [bool] $Detailed,
        [Parameter(Mandatory = $true)]
        [bool] $NoRustupInit
    )

    if ($DumpEnv) {
        dumpEnv -Detailed $Detailed
    }

    if (-not $NoRustupInit) {
        $rustChannel = 'nightly'

        if (Get-IsWindows) {
            $rustupInitUri = 'https://win.rustup.rs'
            $rustPlatformTriple = 'x86_64-pc-windows-msvc'
            $rustupInitPath = ".\rustup-init.exe"

            if (-not (Test-Path -Path $rustupInitPath)) {
                Invoke-WebRequest -Uri $rustupInitUri -OutFile $rustupInitPath
            }

            Invoke-ExternalCommand $rustupInitPath -- `
                --default-host $rustPlatformTriple `
                --default-toolchain $rustChannel `
                --profile minimal `
                -y
        }
        elseif (Get-IsLinux) {
            $rustupInitUri = 'https://sh.rustup.rs'
            $rustPlatformTriple = 'x86_64-unknown-linux-gnu'
            $rustupInitPath = './rustup-init.sh'

            if (-not (Test-Path -Path $rustupInitPath)) {
                Invoke-WebRequest -Uri $rustupInitUri -OutFile $rustupInitPath
            }

            Invoke-ExternalCommand sh $rustupInitPath -- `
                --default-host $rustPlatformTriple `
                --default-toolchain $rustChannel `
                --profile minimal `
                -y
        }
        elseif (Get-IsMacOS) {
            $rustupInitUri = 'https://sh.rustup.rs'
            $rustPlatformTriple = 'x86_64-apple-darwin'
            $rustupInitPath = './rustup-init.sh'

            if (-not (Test-Path -Path $rustupInitPath)) {
                Invoke-WebRequest -Uri $rustupInitUri -OutFile $rustupInitPath
            }

            Invoke-ExternalCommand sh $rustupInitPath -- `
                --default-host $rustPlatformTriple `
                --default-toolchain $rustChannel `
                --profile minimal `
                -y
        }
        else {
            throw 'Unsupported platform'
        }
    }
}

Write-Host -ForegroundColor Magenta 'Install step'
try {
    main `
        -DumpEnv $DumpEnv `
        -Detailed $Detailed `
        -NoRustupInit $NoRustupInit
    Write-Host -ForegroundColor Green 'Install step succeeded'
}
catch {
    Write-Host -ForegroundColor Red 'Installed step failed'
    throw
}
