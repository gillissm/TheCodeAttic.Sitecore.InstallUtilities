<#
.SYNOPSIS
The script provides the minimal required data to uninstall an installation of Sitecore that was done via the Sitecore Install Assistant (SIA)
 
The script requires the user to proivde four parameters and retrieves the remaining data from the last SIA log file.

If your installation leveraged the defaul setup.exe.config provided by SIA then no edits to this file is required.

.DESCRIPTION
The script provides the minimal required data to uninstall an installation of Sitecore that was done via the Sitecore Install Assistant (SIA)
 
The script requires the user to proivde four parameters and retrieves the remaining data from the last SIA log file.

If your installation leveraged the defaul setup.exe.config provided by SIA then no edits to this file is required.

.PARAMETER SqlServer
The DNS name or IP of the SQL Instance that you installed against.

Required
String

.PARAMETER SqlAdminUser
A SQL user with sysadmin privileges

Required
String

.PARAMETER SqlAdminPassword
The password for SQLAdminUser.

Required
String

.PARAMETER SIALogFile
The full path to a specific log file that the uninstall should be based on. If not included will default to the most recent log file at "$env:USERPROFILE\sitecore.installassistant"

Optional
String

.EXAMPLE
.\Sitecore-Uninstall-SIA.ps1

You will then be prompted for required parameters.

.EXAMPLE
.\Sitecore-Uninstall-SIA.ps1 -SqlServer localhost -SqlAdminUser sa -SqlAdminPassword sa

.EXAMPLE
.\Sitecore-Uninstall-SIA.ps1 -SqlServer localhost -SqlAdminUser sa -SqlAdminPassword sa -SIALogFile "C:\Installs\sia-20191101.log"

#>

param(
    # The DNS name or IP of the SQL Instance.
    [Parameter(Mandatory = $true, HelpMessage = "The DNS name or IP of the SQL Instance")]
    [string]$SqlServer,
    # A SQL user with sysadmin privileges.
    [Parameter(Mandatory = $true, HelpMessage = "A SQL user with sysadmin privileges")]
    [string]$SqlAdminUser,
    # The password for $SQLAdminUser.
    [Parameter(Mandatory = $true, HelpMessage = "The password for SQLAdminUser.")]
    [string]$SqlAdminPassword,
    # The full path to a specific log file for uninstalling
    [Parameter(Mandatory = $false, HelpMessage = "The full path to a specific log file that the uninstall should be based on.")]
    [string]$SIALogFile = ""
)

Import-Module SitecoreInstallFramework -RequiredVersion 2.2.0
Import-Module SitecoreFundamentals

if ($SIALogFile -eq "" ) {
    # Retrieve the log file from the last run of SIA.
    $logfile = Get-ChildItem -Path "$env:USERPROFILE\sitecore.installassistant" -Filter "Sitecore-InstallConfiguration_*.txt" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

    $SIALogFile = Join-Path "$env:USERPROFILE\sitecore.installassistant" $logFile.Name
}

#The root folder with the WDP files and XP0-SingelDeveloper.json
$SCInstallRoot = ""
#The full path to the XP0-SingelDeveloper.json or similar custom configuration JSON.
$SCInstallConfig = ""

#Get Working Directory, SCInstallRoot
$workingDirectoryPath = Select-String -Path $SIALogFile -Pattern "^WorkingDirectory" -list
$whatIfLine = Select-String -Path $SIALogFile -Pattern "^WhatIf" -list
	
if ($workingDirectoryPath.LineNumber -lt ($whatIfLine.LineNumber - 1)) {
    #is a wrapped line.
    $secondPart = Get-Content $SIALogFile | Select-Object -Index $workingDirectoryPath.LineNumber
    $secondPart = $secondPart.Trim()
    if ($secondPart.Startswith("/")) {
        $SCInstallRoot = Join-Path ($workingDirectoryPath -split " :")[1].Trim() $secondPart
    }
    else {
        $SCInstallRoot = "{0} {1}" -f ($workingDirectoryPath -split " :")[1].Trim(), $secondPart		
    }        
}	
else {
    $SCInstallRoot = ($workingDirectoryPath -split " : ")[1].Trim()
}

#Get Install Configuration JSON
$configurationPath = Select-String -Path $SIALogFile -Pattern ".XP0-SingleDeveloper.json$" -list
	
if (-Not $configurationPath.Line.StartsWith("Configuration")) {	
    #is a wrapped line
    $i = $configurationPath.LineNumber - 2
    $firstPath = Get-Content $SIALogFile | Select-Object -Index $i		
    if ($configurationPath.Line.Trim().StartsWith("/")) {
        $SCInstallConfig = Join-Path ($firstPath -split " :")[1].Trim() $configurationPath.Line.Trim()	
    }
    else {
        $SCInstallConfig = "{0} {1}" -f ($firstPath -split " :")[1].Trim(), $configurationPath.Line.Trim()		
    }
        
}
else {
    $SCInstallConfig = ($configurationPath -split " : ")[1].Trim()
}

# The URL of the Solr Server
$SolrUrl = ((Select-String -Path $SIALogFile -Pattern "\[Requesting\].https.[/solr]{1}?" -list) -split "\[Requesting\]")[1].Trim()
# The name for the XConnect service.
$XConnectSiteName = ((Select-String -Path $SIALogFile -SimpleMatch -Pattern "[XConnectXP0_CreateWebsite]:[Create]") -split " ")[1]
# The Sitecore site instance name.
$SitecoreSiteName = ((Select-String -Path $SIALogFile -SimpleMatch -Pattern "[SitecoreXP0_CreateWebsite]:[Create]") -split " ")[1]
# Identity Server site name
$IdentityServerSiteName = ((Select-String -Path $SIALogFile -SimpleMatch -Pattern "[IdentityServer_CreateWebsite]:[Create]") -split " ")[1]
# The Prefix that will be used on SOLR, Website and Database instances.
$Prefix = $SitecoreSiteName.Replace("sc.dev.local", "")

Write-Host -ForegroundColor DarkGreen "------ Uninstall Parameters ------" 

Write-Host "    SIA Log File............... $SIALogFile" 
Write-Host "    Solr URL................... $SolrUrl" 
Write-Host "    Prefix..................... $Prefix" 
Write-Host "    Sitecore Site Name......... $SitecoreSiteName" 
Write-Host "    xConnect Site Name......... $XConnectSiteName" 
Write-Host "    Identity Server Site Name.. $IdentityServerSiteName" 
Write-Host "    Install Working Path....... $SCInstallRoot"
Write-Host "    Install Configuration Path. $SCInstallConfig"


$question = "Do you want to proceed with uninstalling $SitecoreSiteName?"
$choices = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice(" ", $question, $choices, 1)
if ($decision -eq 0) {    
    $singleDeveloperParams = @{
        Path                          = $SCInstallConfig
        SqlServer                     = $SqlServer
        SqlAdminUser                  = $SqlAdminUser
        SqlAdminPassword              = $SqlAdminPassword
        SolrUrl                       = $SolrUrl    
        Prefix                        = $Prefix
        XConnectCertificateName       = $XConnectSiteName
        IdentityServerCertificateName = $IdentityServerSiteName
        IdentityServerSiteName        = $IdentityServerSiteName    
        XConnectSiteName              = $XConnectSiteName
        SitecoreSitename              = $SitecoreSiteName
    }

    Push-Location $SCInstallRoot
    Uninstall-SitecoreConfiguration @singleDeveloperParams *>&1 | Tee-Object XP0-SingleDeveloper-Uninstall.log
    Pop-Location

    Write-Host "Uninstallation has completed for $SitecoreSiteName" -ForegroundColor DarkGreen
}
else {
    Write-Host "Uninstalling of $SitecoreSiteName has been cancelled." -ForegroundColor  DarkYellow
}
