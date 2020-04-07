# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

[CmdletBinding(DefaultParameterSetName="BuildOne")]
param(
    [Parameter(ParameterSetName="BuildAll")]
    [switch]$All,

    [Parameter(ParameterSetName="BuildOne")]
    [ValidateRange(3, 7)]
    [int]$PSVersion = $PSVersionTable.PSVersion.Major,

    [Parameter(ParameterSetName="BuildOne")]
    [Parameter(ParameterSetName="BuildAll")]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    # For building documentation only
    # or re-building it since docs gets built automatically only the first time
    [Parameter(ParameterSetName="BuildDocumentation")]
    [switch]$Documentation,

    [Parameter(ParameterSetName='BuildAll')]
    [Parameter(ParameterSetName='BuildOne')]
    [switch]$Clobber,

    [Parameter(Mandatory=$true,ParameterSetName='Clean')]
    [switch] $Clean,

    [Parameter(Mandatory=$true,ParameterSetName='Test')]
    [switch] $Test,

    [Parameter(ParameterSetName='Test')]
    [switch] $InProcess,

    [Parameter(ParameterSetName='Bootstrap')]
    [switch] $Bootstrap,

    [Parameter(ParameterSetName='BuildAll')]
    [Parameter(ParameterSetName='BuildOne')]
    [switch] $Catalog


)

END {
    Import-Module -Force (Join-Path $PSScriptRoot build.psm1)
    if ( $Clean -or $Clobber ) {
        Remove-Build
        if ( $PSCmdlet.ParameterSetName -eq "Clean" ) {
            return
        }
    }

    $setName = $PSCmdlet.ParameterSetName
    switch ( $setName ) {
        "BuildAll" {
            Start-ScriptAnalyzerBuild -All -Configuration $Configuration -Verbose:$Verbose -Catalog:$Catalog
        }
        "BuildDocumentation" {
            Start-ScriptAnalyzerBuild -Documentation -Verbose:$Verbose -Catalog:$Catalog
        }
        "BuildOne" {
            $buildArgs = @{
                PSVersion = $PSVersion
                Configuration = $Configuration
                Verbose = $Verbose
            }
            Start-ScriptAnalyzerBuild @buildArgs
        }
        "Bootstrap" {
            Install-DotNet
            return
        }
        "Test" {
            Test-ScriptAnalyzer -InProcess:$InProcess
            return
        }
        default {
            throw "Unexpected parameter set '$setName'"
        }
    }
}
