<#
    .SYNOPSIS
    Script for rotating files older than x days defaults to 7 days.
    Can be automated daily or whenever in a number of ways and should also run on linux with powerShell 6 installed.
    1.  Windows Task Scheduler
    2.  Automation pipeline e.g. Ansible, Chef, Puppet, vsts pipeline etc.
#>

param
(
    [Parameter(Mandatory)]
    [System.IO.FileInfo]
    $LogFilePath,

    [Parameter(Mandatory)]
    [System.IO.FileInfo]
    $DestinationPath,

    [uint16]
    $Age = 7
)

# Resolve Paths to stop strange behaviour e.g. with a path of ".\" or "."
$LogFilePath = Resolve-Path -Path $LogFilePath | Select -ExpandProperty Path
$DestinationPath = Resolve-Path -Path $DestinationPath | Select -ExpandProperty Path
Get-ChildItem -LiteralPath $LogFilePath.FullName -File | ? LastWriteTime -lt (Get-Date).AddDays($Age) | %{
    Move-Item $_ -Destination $DestinationPath
}