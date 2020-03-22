<#
.SYNOPSIS
    Common functions.

.DESCRIPTION
    Common functions.
#>
#Requires -Version 5

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-IsWindows() {
    [OutputType([bool])]
    param()

    $var = Get-Variable -ErrorAction Ignore -Name IsWindows -Scope Global
    if ($var -ne $null -and ([bool] $var.Value)) {
        $true
    }
    else {
        ($env:OS -ne $null) -and ($env:OS.IndexOf('Windows', [StringComparison]::OrdinalIgnoreCase) -ge 0)
    }
}
Export-ModuleMember -Function Get-IsWindows

function Get-IsLinux() {
    [OutputType([bool])]
    param()

    $var = Get-Variable -ErrorAction Ignore -Name IsLinux -Scope Global
    ($var -ne $null -and ([bool] $var.Value))
}
Export-ModuleMember -Function Get-IsLinux

function Get-IsMacOS() {
    [OutputType([bool])]
    param()

    $var = Get-Variable -ErrorAction Ignore -Name IsMacOS -Scope Global
    ($var -ne $null -and ([bool] $var.Value))
}
Export-ModuleMember -Function Get-IsMacOS

function wrapCommand {
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock] $ScriptBlock
    )

    $savedErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $ScriptBlock
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
}

function Invoke-ExternalCommand {
    [CmdletBinding()]
    param(
        [switch] $Capture,
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Command,
        [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true, Position = 1)]
        [string[]] $Remaining
    )

    wrapCommand -ScriptBlock {
        if ($Capture) {
            $output = $(& $Command $Remaining 2>&1)
            $exitCode = $LastExitCode
        }
        else {
            $output = $null
            & $Command $Remaining 2>&1 | ForEach-Object {
                $line = ([string]$_).TrimEnd()
                if ($line.Length -gt 0) {
                    Write-Host -ForegroundColor DarkYellow "> $line"
                }
            }
            $exitCode = $LastExitCode
        }

        if ($exitCode -ne 0) {
            if ($Remaining.Count -gt 0) {
                throw "$command $Remaining failed with exit code $exitCode"
            }
            else {
                throw "$command failed with exit code $exitCode"
            }
        }

        if ($output -ne $null) {
            $output
        }
    }
}
Export-ModuleMember -Function Invoke-ExternalCommand

function Get-ExecutableFileName {
    [OutputType([string])]
    param([string] $BaseName)

    if (Get-IsWindows) {
        "$($BaseName).exe"
    }
    elseif ((Get-IsLinux) -or (Get-IsMacOS)) {
        $BaseName
    }
    else {
        throw 'Unsupported platform'
    }
}
Export-ModuleMember -Function Get-ExecutableFileName

function getEnv {
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $value = [System.Environment]::GetEnvironmentVariable($Name)
    if ($value -eq $null) {
        throw "Environment variable $Name not defined"
    }
    $value
}

function getPlatformId {
    [OutputType([string])]
    param()

    if (Get-IsWindows) {
        'x86_64-windows'
    }
    elseif (Get-IsLinux) {
        'x86_64-linux'
    }
    elseif (Get-IsMacOS) {
        'x86_64-macos'
    }
    else {
        throw 'Unsupported platform'
    }
}

class BuildInfo {
    [string] $BuildDir
    [string] $ProjectSlug
    [bool] $IsTag
    [bool] $IsBranch
    [string] $RefName
    [Version] $Version
}

class Version {
    [string] $HomePageUri
    [string] $ReleasesUri
    [string] $GitDescription
    [bool] $IsDirty
    [string] $PlatformId
    [string] $Version
    [int] $CommitOffset
    [string] $CommitHash
    [object] $VersionParts
    [object] $Major
    [object] $Minor
    [object] $Patch
    [string] $FullVersion
}

function Get-IsAppVeyorBuild {
    [OutputType([bool])]
    param()

    $env:APPVEYOR_BUILD_FOLDER -ne $null
}
Export-ModuleMember -Function Get-IsAppVeyorBuild

function Get-AppVeyorBuildInfo {
    [OutputType([BuildInfo])]
    param()

    $buildDir = getEnv -Name APPVEYOR_BUILD_FOLDER
    $projectSlug = getEnv -Name APPVEYOR_PROJECT_SLUG
    $isTag = (getEnv -Name APPVEYOR_REPO_TAG) -eq 'true'
    $isBranch = (getEnv -Name APPVEYOR_REPO_TAG) -ne 'true'
    $refName = getEnv -Name APPVEYOR_REPO_BRANCH
    $repoName = getEnv -Name APPVEYOR_REPO_NAME

    $homePageUri = "https://github.com/$repoName"
    $releasesUri = "https://github.com/$repoName/releases/latest"
    $gitDescription = Invoke-ExternalCommand -Capture git describe --long --dirty --match='v[0-9]*'
    $gitDescriptionParts = $gitDescription.Split('-')
    if ($gitDescriptionParts.Length -eq 3) {
        $version = $gitDescriptionParts[0]
        $commitOffset = [int] $gitDescriptionParts[1]
        $commitHash = $gitDescriptionParts[2]
        $isDirty = $false
    }
    elseif (($gitDescriptionParts.Length -eq 4) -and ($gitDescriptionParts[3] -eq 'dirty')) {
        $version = $gitDescriptionParts[0]
        $commitOffset = [int] $gitDescriptionParts[1]
        $commitHash = $gitDescriptionParts[2]
        $isDirty = $true
    }
    else {
        throw "Invalid Git description $gitDescription"
    }

    if ($version[0] -ne 'v') {
        throw "Invalid version $version"
    }

    $versionParts = $version.Substring(1).Split('.')
    if (($versionParts.Length -lt 1) -or ($versionParts.Length -gt 3)) {
        throw "Invalid version $version"
    }

    $major = if ($versionParts.Length -gt 0) { [int] $versionParts[0] } else { $null }
    $minor = if ($versionParts.Length -gt 1) { [int] $versionParts[1] } else { $null }
    $patch = if ($versionParts.Length -gt 2) { [int] $versionParts[2] } else { $null }

    $platformId = getPlatformId

    $fullVersion = $version

    if ($commitOffset -gt 0) {
        $fullVersion += "-$commitOffset"
    }

    $fullVersion += "-$commitHash"

    if ($isDirty) {
        $fullVersion += '-dirty'
    }

    if ($isBranch) {
        $fullVersion += "-$refName"
    }

    $fullVersion += "-$platformId"

    $version = [Version] @{
        HomePageUri    = $homePageUri
        ReleasesUri    = $releasesUri
        GitDescription = $gitDescription
        IsDirty        = $isDirty
        PlatformId     = $platformId
        Version        = $version
        CommitOffset   = $commitOffset
        CommitHash     = $commitHash
        VersionParts   = $versionParts
        Major          = $major
        Minor          = $minor
        Patch          = $patch
        FullVersion    = $fullVersion
    }

    [BuildInfo] @{
        BuildDir    = $buildDir
        ProjectSlug = $projectSlug
        IsTag       = $isTag
        IsBranch    = $isBranch
        RefName     = $refName
        Version     = $version
    }
}
Export-ModuleMember -Function Get-AppVeyorBuildInfo

function Get-LocalBuildInfo {
    [OutputType([BuildInfo])]
    param()

    $version = [Version] @{
        HomePageUri    = '(home-page-uri)'
        ReleasesUri    = '(releases-uri)'
        GitDescription = '(git-description)'
        IsDirty        = $false
        PlatformId     = getPlatformId
        Version        = '(version)'
        CommitOffset   = 0
        CommitHash     = '(commit-hash)'
        VersionParts   = @()
        Major          = $null
        Minor          = $null
        Patch          = $null
        FullVersion    = 'Development'
    }

    [BuildInfo] @{
        BuildDir    = Resolve-Path -Path $PSScriptRoot\..
        ProjectSlug = 'project'
        IsTag       = $false
        IsBranch    = $false
        RefName     = '(ref-name)'
        Version     = $version
    }
}
Export-ModuleMember -Function Get-LocalBuildInfo

function Get-HomeDir {
    [OutputType([object])]
    param()

    if ($env:USERPROFILE -ne $null) {
        $env:USERPROFILE
    }
    else {
        $env:HOME
    }
}
Export-ModuleMember -Function Get-HomeDir
