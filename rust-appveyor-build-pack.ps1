[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$baseName = 'rust-appveyor-build-pack'
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath $baseName

New-Item `
    -ItemType Directory `
    -Path $outputDir | Out-Null

Invoke-WebRequest `
    -Uri https://github.com/rcook/rust-appveyor-build-pack/releases/latest/download/$baseName.zip `
    -OutFile $outputDir\$baseName.zip

Expand-Archive `
    -Path $outputDir\$baseName.zip `
    -DestinationPath $outputDir
