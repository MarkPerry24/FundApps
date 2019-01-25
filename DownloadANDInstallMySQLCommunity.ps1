# Enable verbose logging
$VerbosePreference = "Continue"

# trap all errors and terminate since we have no means of recovery
trap { "An Error Occurred Terminating the Script: $_"; break }

# Force .Net to use TLSv1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Obtain valid windows download
$mysqlBaseURI = "https://dev.mysql.com"
$mysqlHref = "/downloads/windows/installer/8.0.html"
$mysqlURI = "{0}{1}" -f $mysqlBaseURI, $mysqlHref
$webResponse = Invoke-WebRequest -Uri $mysqlURI
$webResponseNode = $webResponse.ParsedHtml.all | ? tagname -eq TD | ? className -eq sub-text | ? innerHTML -match '(?<mysqlInstaller>mysql-installer-community-\d\.\d.\d+.\d\.msi)' | Select -Last 1
$mysqlInstaller = $Matches.mysqlInstaller
$downloadLink = ($webResponseNode.parentNode.previousSibling.lastChild.lastChild.lastChild | Select -ExpandProperty href) -replace "about:"
$verifiableMd5 = $webResponseNode.parentNode.lastChild.children | ? tagName -eq CODE | Select -ExpandProperty innertext

# Set destination file paths
$mySQLCommunityMSI = Join-Path $env:temp $mysqlInstaller

# Download required file
$finalDownloadLink = (Invoke-WebRequest -Uri ("{0}{1}" -f $mysqlBaseURI,$downloadLink)).Links | ? innerHTML -like "No thanks*" | Select -ExpandProperty hRef
Invoke-WebRequest -Uri ("{0}{1}" -f $mysqlBaseURI,$finalDownloadLink) -OutFile $mySQLCommunityMSI -UseBasicParsing

# Test File Hash against downloaded verifiable hash
$md5 = (Get-FileHash -Algorithm MD5 -LiteralPath $mySQLCommunityMSI -Verbose).Hash.tolower()

if (-not($md5 -eq $verifiableMd5))
{
    throw "md5 signature does not match:`n$md5 != $verifiableMd5"
}

# Test msi was signed and is valid
if ((Get-AuthenticodeSignature -LiteralPath $mySQLCommunityMSI).Status -ne "Valid")
{
    throw "Invalid download, file not signed properly"
}

# Install MySQL & Log result to '%temp%\mySQLInstallLog.txt'
$fullLogFile = Join-Path $env:Temp "mySQLInstallLog.txt"
[string[]]$params = ,"/i", $mySQLCommunityMSI, "/q", "/l*xv", $fullLogFile
Start-Process "msiexec.exe" -ArgumentList $params -Wait -Verb runAs
