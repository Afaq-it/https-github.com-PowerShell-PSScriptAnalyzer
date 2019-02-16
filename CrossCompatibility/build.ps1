# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

[CmdletBinding(DefaultParameterSetName='AllFrameworks')]
param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    $Configuration = 'Debug',

    [Parameter()]
    [ValidateSet('netstandard2.0', 'net452')]
    [string]
    $Framework,

    [switch]
    $Test,

    [switch]
    $Clean
)

$ErrorActionPreference = 'Stop'

if ($IsWindows -eq $false) {
    $script:TargetFrameworks = 'netstandard2.0'
} else {
    $script:TargetFrameworks = 'netstandard2.0','net452'
}

$script:Psm1Path = [System.IO.Path]::Combine($PSScriptRoot, 'CrossCompatibility.psm1')
$script:Psd1Path = [System.IO.Path]::Combine($PSScriptRoot, 'CrossCompatibility.psd1')
$script:ProfileDirPath = [System.IO.Path]::Combine($PSScriptRoot, 'profiles')

$script:BinModDir = [System.IO.Path]::Combine($PSScriptRoot, 'out', 'CrossCompatibility')
$script:BinModSrcDir = Join-Path $PSScriptRoot 'CrossCompatibility'

$script:PublishDlls = @{
    'net452' = @('CrossCompatibility.dll', 'CrossCompatibility.pdb', 'Newtonsoft.Json.dll')
    'netstandard2.0' = @('CrossCompatibility.dll', 'CrossCompatibility.pdb', 'Newtonsoft.Json.dll')
}

function Invoke-CrossCompatibilityModuleBuild
{
    param(
        [Parameter()]
        [ValidateSet('netstandard2.0', 'net452')]
        [string]
        $Framework = 'netstandard2.0',

        [Parameter()]
        [ValidateSet('Debug', 'Release')]
        [string]
        $Configuration = 'Debug'
    )

    Push-Location $script:BinModSrcDir
    try
    {
        dotnet publish -f $Framework -c $Configuration
    }
    finally
    {
        Pop-Location
    }
}

function Publish-CrossCompatibilityModule
{
    param(
        [Parameter()]
        [string]
        $SrcRootDir = $script:BinModSrcDir,

        [Parameter()]
        [string]
        $DestinationDir = $script:BinModDir,

        [Parameter()]
        [string[]]
        $TargetFramework = $script:TargetFrameworks
    )

    if (-not (Test-Path $DestinationDir))
    {
        New-Item -ItemType Directory $DestinationDir
    }
    elseif (-not (Test-Path $DestinationDir -PathType Container))
    {
        throw "$DestinationDir exists but is not a directory. Aborting."
    }

    Copy-Item -LiteralPath $script:Psd1Path -Destination (Join-Path $DestinationDir 'CrossCompatibility.psd1')
    Copy-Item -LiteralPath $script:Psm1Path -Destination (Join-Path $DestinationDir 'CrossCompatibility.psm1')
    Copy-Item -Recurse -LiteralPath $script:ProfileDirPath -Destination $DestinationDir -ErrorAction Ignore

    foreach ($framework in $TargetFramework)
    {
        $dest = Join-Path $DestinationDir $framework
        if (-not (Test-Path $dest))
        {
            $null = New-Item -ItemType Directory -Path $dest
        }

        $binPath = [System.IO.Path]::Combine($SrcRootDir, 'bin', $Configuration, $framework, 'publish')
        $dlls = $script:PublishDlls[$framework]

        foreach ($dll in $dlls)
        {
            $dllPath = Join-Path $binPath $dll
            $null = Copy-Item -LiteralPath $dllPath -Destination $dest
        }
    }
}

if ($Clean)
{
    Remove-Item -Force -Recurse $script:BinModDir
}

# Only build if the output directory does not exist
if (-not (Test-Path "$PSScriptRoot/out/CrossCompatibility"))
{
    if ($Framework)
    {
        Invoke-CrossCompatibilityModuleBuild -Configuration $Configuration -Framework $Framework
        Publish-CrossCompatibilityModule -TargetFramework $Framework
    }
    else
    {
        foreach ($f in $script:TargetFrameworks)
        {
            Invoke-CrossCompatibilityModuleBuild -Framework $f -Configuration $Configuration
        }
        Publish-CrossCompatibilityModule
    }
}
else
{
    Write-Verbose "CrossCompatibility module already built -- skipping build"
    Write-Verbose "Use '-Clean' to force building"
}

if ($Test)
{
    $testPath = "$PSScriptRoot/Tests"
    & (Get-Process -Id $PID).Path -Command "Invoke-Pester -Path '$testPath'"
}
