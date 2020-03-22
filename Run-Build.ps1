[CmdletBinding()]
param(
    [switch] $Download,
    [switch] $Refresh,
    [switch] $Trace,
    [ValidateSet('Local', 'TagBuild', 'BranchBuild')]
    [string] $BuildType = 'Local'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($Trace) {
    Set-PSDebug -Strict -Trace 1
}

enum BuildType {
    Local
    TagBuild
    BranchBuild
}

function main {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Download,
        [Parameter(Mandatory = $true)]
        [bool] $Refresh,
        [Parameter(Mandatory = $true)]
        [BuildType] $BuildType
    )

    $repoDir = Get-Location
    if (-not (Test-Path -Path (Join-Path -Path $repoDir -ChildPath Cargo.toml))) {
        throw 'This is not a valid Cargo-based Rust project directory'
    }

    $baseName = 'rust-appveyor-build-pack'
    $packDir = Join-Path -Path $repoDir -ChildPath $baseName

    if ($Refresh) {
        Write-Output 'Removing old rust-appveyor-build-pack'
        Remove-Item -Force -Recurse -Path $packDir
    }

    if (-not (Test-Path -Path $packDir)) {
        if ($Download) {
            Write-Output 'Downloading rust-appveyor-build-pack'
            throw 'Not implemented'
            <#
            if (-not (Test-Path -Path $bootstrapPath)) {
                Invoke-WebRequest `
                    -Uri https://github.com/rcook/$baseName/releases/latest/download/$baseName.ps1 `
                    -OutFile $bootstrapPath
            }
            $bootstrapPath = Resolve-Path -Path $bootstrapPath

            $packDir = Join-Path -Path $repoDir -ChildPath $baseName
            if (-not (Test-Path -Path $packDir)) {
                & $bootstrapPath
            }
            $packDir = Resolve-Path -Path $packDir
            #>
        }
        else {
            Write-Output 'Copying local rust-appveyor-build-pack'
            New-Item -ItemType Directory $packDir | Out-Null
            Copy-Item -Path $PSScriptRoot\src\* -Destination $packDir
        }
    }

    $packDir = Resolve-Path -Path $packDir

    switch ($BuildType) {
        Local { }
        TagBuild {
            $env:APPVEYOR_BUILD_FOLDER = Resolve-Path -Path $repoDir
            $env:APPVEYOR_REPO_BRANCH = 'v11.22.33'
            $env:APPVEYOR_REPO_NAME = 'user/project'
            $env:APPVEYOR_REPO_TAG = 'true'
            $env:APPVEYOR_PROJECT_SLUG = 'project'
        }
        BranchBuild {
            $env:APPVEYOR_BUILD_FOLDER = Resolve-Path -Path $repoDir
            $env:APPVEYOR_REPO_BRANCH = 'test-branch'
            $env:APPVEYOR_REPO_NAME = 'user/project'
            $env:APPVEYOR_REPO_TAG = 'false'
            $env:APPVEYOR_PROJECT_SLUG = 'project'
        }
        default { throw "Unsupported build type $BuildType" }
    }

    & $packDir\install.ps1
    & $packDir\build.ps1
    & $packDir\test.ps1
}

main -Download $Download -Refresh $Refresh -BuildType $BuildType
