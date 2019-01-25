param
(
    [System.IO.FileInfo]
    $LogFilePath,

    [System.IO.FileInfo]
    $DestinationPath
)

# Resolve Paths to stop strange behaviour e.g. with a path of ".\" or "."
$LogFilePath = Resolve-Path -Path $LogFilePath | Select -ExpandProperty Path
$DestinationPath = Resolve-Path -Path $DestinationPath | Select -ExpandProperty Path
Get-ChildItem -LiteralPath $LogFilePath.FullName -File | ? LastWriteTime -lt (Get-Date).AddDays(-7) | %{
    Move-Item $_ -Destination $DestinationPath
}