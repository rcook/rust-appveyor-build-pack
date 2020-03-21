<#
.SYNOPSIS
    Install step.

.DESCRIPTION
    Install step.
#>
#Requires -Version 5

[CmdletBinding()]
param(
    [switch] $Trace,
    [switch] $DumpEnv,
    [switch] $Detailed,
    [switch] $RustupInit,
    [switch] $Clean
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

    Write-Output "isLinux: $(Get-IsLinux)"
    Write-Output "isMacOS: $(Get-IsMacOS)"
    Write-Output "isWindows: $(Get-IsWindows)"
    Write-Output "executableFileName: $(Get-ExecutableFileName -BaseName base-name)"
    Write-Output "thisDir: $thisDir"
    Write-Output "currentDir: $currentDir"

    Write-Output 'Git tags:'
    Invoke-ExternalCommand git tag | ForEach-Object {
        Write-Output "  $_ $(Invoke-ExternalCommand git rev-list -n 1 $_)"
    }

    Write-Output 'Git branches:'
    Invoke-ExternalCommand git branch -vv -a --color=never | ForEach-Object {
        Write-Output "  $_"
    }

    Write-Output 'Git describe:'
    Write-Output "  $(Invoke-ExternalCommand git describe --long --dirty)"

    if (Get-IsAppVeyorBuild) {
        $buildInfo = Get-AppVeyorBuildInfo
        Write-Output $buildInfo
        Write-Output $buildInfo.Version
    }

    if ($Detailed) {
        Write-Output 'Environment:'
        Get-ChildItem -Path Env: | Sort-Object Key | ForEach-Object {
            Write-Output "  $($_.Key) = $($_.Value)"
        }

        Write-Output "Files under $($thisDir):"
        Get-ChildItem -Force -Recurse -Path $thisDir | Sort-Object FullName | ForEach-Object {
            Write-Output "  $($_.FullName)"
        }

        if ($thisDir -ne $currentDir) {
            Write-Output "Files under $($currentDir):"
            Get-ChildItem -Force -Recurse -Path $currentDir | Sort-Object FullName | ForEach-Object {
                Write-Output "  $($_.FullName)"
            }
        }

        Write-Output 'Git log:'
        Invoke-ExternalCommand git log --oneline --color=never | ForEach-Object {
            Write-Output "  $_"
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
        [bool] $RustupInit,
        [Parameter(Mandatory = $true)]
        [bool] $Clean
    )

    if ($Clean) {
        Invoke-ExternalCommand git checkout -- .
        Invoke-ExternalCommand git clean -fxd
    }

    if ($DumpEnv) {
        dumpEnv -Detailed $Detailed
    }

    if ($RustupInit) {
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

Write-Output 'Install step'
main `
    -DumpEnv $DumpEnv `
    -Detailed $Detailed `
    -RustupInit $RustupInit `
    -Clean $Clean
