<#
.SYNOPSIS
The script provides the minimal required data to uninstall an installation of Sitecore that was done via the Sitecore Install Assistant (SIA)
 
The script requires the user to proivde four parameters and retrieves the remaining data from the last SIA log file.

If your installation leveraged the defaul setup.exe.config provided by SIA then no edits to this file is required.

.DESCRIPTION
The script provides the minimal required data to uninstall an installation of Sitecore that was done via the Sitecore Install Assistant (SIA)
 
The script requires the user to proivde four parameters and retrieves the remaining data from the last SIA log file.

If your installation leveraged the defaul setup.exe.config provided by SIA then no edits to this file is required.

.PARAMETER SCInstallRoot
The root folder with the WDP files and the XPO-SingleDeveloper.json. This will normally be the same directory as the Siteore Install Assistant executable.

Required
String

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

.EXAMPLE
.\Sitecore-Uninstall-SIA.ps1 -SCInstallRoot "C:\SitecoreVersions\SC9.2\SIA" -SqlServer localhost -SqlAdminUser sa -SqlAdminPassword sa

#>

param(
# The root folder with the WDP files.
[Parameter(Mandatory=$true, HelpMessage="The root folder with the WDP files and XP0-SingelDeveloper.json")]
[string]$SCInstallRoot,
# The DNS name or IP of the SQL Instance.
[Parameter(Mandatory=$true, HelpMessage="The DNS name or IP of the SQL Instance")]
[string]$SqlServer,
# A SQL user with sysadmin privileges.
[Parameter(Mandatory=$true, HelpMessage="A SQL user with sysadmin privileges")]
[string]$SqlAdminUser,
# The password for $SQLAdminUser.
[Parameter(Mandatory=$true, HelpMessage="The password for SQLAdminUser.")]
[string]$SqlAdminPassword
)

Import-Module SitecoreInstallFramework -RequiredVersion 2.1.0
Import-Module SitecoreFundamentals

## ONLY CHANGE IF YOU EDITED THE setup.exe.config
# Retrieve the log file from the last run of SIA.
$logfile = Get-ChildItem -Path "$env:USERPROFILE\sitecore.installassistant" -Filter "Sitecore-InstallConfiguration_*.txt"  | Sort-Object -Property LastWriteTime -Descending | Select -First 1

# The URL of the Solr Server
$SolrUrl = "https" + $((Select-String -Path $logfile -Pattern 'https://*/solr' -list) -split 'https')[1]
# The name for the XConnect service.
$XConnectSiteName = ((Select-String -Path $logfile -SimpleMatch -Pattern "[XConnectXP0_CreateWebsite]:[Create]") -split " ")[1]
# The Sitecore site instance name.
$SitecoreSiteName = ((Select-String -Path $logfile -SimpleMatch -Pattern "[SitecoreXP0_CreateWebsite]:[Create]") -split " ")[1]
# Identity Server site name
$IdentityServerSiteName = ((Select-String -Path $logfile -SimpleMatch -Pattern "[IdentityServer_CreateWebsite]:[Create]") -split " ")[1]
# The Prefix that will be used on SOLR, Website and Database instances.
$Prefix = $SitecoreSiteName.Replace("sc.dev.local", "")

Write-Host -ForegroundColor DarkGreen "------ Uninstall Parameters ------" 

Write-Host "    Solr URL................... $SolrUrl" 
Write-Host "    Prefix..................... $Prefix" 
Write-Host "    Sitecore Site Name......... $SitecoreSiteName" 
Write-Host "    xConnect Site Name......... $XConnectSiteName" 
Write-Host "    Identity Server Site Name.. $IdentityServerSiteName" 
Write-Host "    SC Install Root............ $SCInstallRoot" 

$question = "Do you want to proceed with uninstalling $SitecoreSiteName?"
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice(" ", $question, $choices, 1)
if ($decision -eq 0) {    
    $singleDeveloperParams = @{
        Path = "$SCInstallRoot\XP0-SingleDeveloper.json"
        SqlServer = $SqlServer
        SqlAdminUser = $SqlAdminUser
        SqlAdminPassword = $SqlAdminPassword
        SolrUrl = $SolrUrl    
        Prefix = $Prefix
        XConnectCertificateName = $XConnectSiteName
        IdentityServerCertificateName = $IdentityServerSiteName
        IdentityServerSiteName = $IdentityServerSiteName    
        XConnectSiteName = $XConnectSiteName
        SitecoreSitename = $SitecoreSiteName
    }

    Push-Location $SCInstallRoot
    Uninstall-SitecoreConfiguration @singleDeveloperParams *>&1 | Tee-Object XP0-SingleDeveloper-Uninstall.log
    Pop-Location

    Write-Host "Uninstallation has completed for $SitecoreSiteName" -ForegroundColor DarkGreen
} else {
    Write-Host "Uninstalling of $SitecoreSiteName has been cancelled." -ForegroundColor  DarkYellow
}