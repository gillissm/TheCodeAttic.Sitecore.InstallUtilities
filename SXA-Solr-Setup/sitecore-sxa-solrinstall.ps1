<#
.SYNOPSIS
Based on the SXA scripts found in the Sitecore Habitat Home Utilities, https://github.com/Sitecore/Sitecore.HabitatHome.Utilities, repository.
This provides a single script to create SXA required Solr cores, update the Sitecore instances configuration files, and add SXA Suggest request handler to Solr.

The script requires the usage of two JSON configuration files to work properly. By default the script looks in the directory that it is being executred from ($PSScriptRoot).
An optional parameter ($PathToJson) is available.

The script also contains an uninstall/cleanup flag allowing one to indicate the deletion/cleanup of the SXA Cores.

.DESCRIPTION
Based on the SXA scripts found in the Sitecore Habitat Home Utilities, https://github.com/Sitecore/Sitecore.HabitatHome.Utilities, repository.
This provides a single script to create SXA required Solr cores, update the Sitecore instances configuration files, and add SXA Suggest request handler to Solr.

The script requires the usage of two JSON configuration files to work properly. By default the script looks in the directory that it is being executred from ($PSScriptRoot).
An optional parameter ($PathToJson) is available.

The script also contains an uninstall/cleanup flag allowing one to indicate the deletion/cleanup of the SXA Cores.

.PARAMETER SitecoreSiteName
Name of the Sitecore instance, script assumes that the sitecore name can be used as the URL as well as a file path lookup

Required
String

.PARAMETER SolrUrl
Full URL to Solr must include Port and the slash solr, ex: https://solr811.thecodeattic.sc:8988/solr

Required
String

.PARAMETER SolrRoot
Fully qualified path to the Solr server, for example C:\solr811\solr-8.1.1

Required
String

.PARAMETER SolrCorePrefix
Value to be appended to all Solr cores, cannot contain dots/periods

Required
String

.PARAMETER SolrService
The Name of the Solr Service.

Required
String

.PARAMETER SitecoreAdminPassword
The Password for the Sitecore Admin User. This will be regenerated if left on the default.

Required
String

.PARAMETER SitePhysicalRoot
Root folder to install the site to. If left on the default [systemdrive]:\\inetpub\\wwwroot\<SitecoreSiteName> will be used

Optional
String

.PARAMETER UninstallCores
Include the switch to delete/uninstall the SXA Solr Cores

Optional
Switch

.PARAMETER PathToJson
Full path to the directory that contains both sxa-solr.json and solr-suggester-config.json. Defaults to the directory of the script file.

Optional
String

.EXAMPLE
.\Sitecore-Sxa-SolrInstall.ps1

.EXAMPLE
.\Sitecore-Sxa-SolrInstall.ps1 -PathToJson C:\myconfigs

.EXAMPLE
.\Sitecore-Sxa-SolrInstall.ps1 -UninstallCores
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Name of the Sitecore instance, script assumes that the sitecore name can be used as the URL as well as a file path lookup")]
    [string]$SitecoreSiteName,
    [Parameter(Mandatory = $true, HelpMessage = "Full URL to Solr must include Port and the slash solr, ex: https://solr811.thecodeattic.sc:8988/solr")]
    [string]$SolrUrl,
    [Parameter(Mandatory = $true, HelpMessage = "Fully qualified path to the Solr server, for example C:\solr811\solr-8.1.1")]
    [string]$SolrRoot,
    [Parameter(Mandatory = $true, HelpMessage = "Value to be appended to all Solr cores, cannot contain dots/periods")]
    [string]$SolrCorePrefix, 
    [Parameter(Mandatory = $true, HelpMessage = "The Name of the Solr Service.")]
    [string]$SolrService,
    [Parameter(Mandatory = $true, HelpMessage = "The Password for the Sitecore Admin User. This will be regenerated if left on the default.")]
    [string]$SitecoreAdminPassword,
    [Parameter(Mandatory = $false, HelpMessage = "Root folder to install the site to. If left on the default [systemdrive]:\\inetpub\\wwwroot\<SitecoreSiteName> will be used")]
    [string]$SitePhysicalRoot = "",
    [Parameter(Mandatory = $false, HelpMessage = "Include the switch to delete/uninstall the SXA Solr Cores")]
    [switch]$UninstallCores,
    [Parameter(Mandatory = $false, HelpMessage = "Full path to the directory that contains both sxa-solr.json and solr-suggester-config.json. Defaults to the directory of the script file.")]
    [switch]$PathToJson = $PSScriptRoot
)

Import-Module SitecoreInstallFramework -Force -RequiredVersion 2.2.0
Import-Module SitecoreFundamentals

$sitewebroot = if ($SitePhysicalRoot -eq "") { "C:\inetpub\wwwroot\$SitecoreSiteName" }Else { $SitePhysicalRoot }

Write-Host -ForegroundColor DarkGreen "------ Solr Core Setup Parameters ------" 
Write-Host "    Path................... $PathToJson\sxa-solr.json"
Write-Host "    SolrUrl................ $SolrUrl"
Write-Host "    SolrRoot............... $SolrRoot"
Write-Host "    SolrService............ $SolrService"
Write-Host "    CorePrefix............. $SolrCorePrefix"
Write-Host "    SiteName............... $SitecoreSiteName"
Write-Host "    SitecoreAdminPassword.. $SitecoreAdminPassword"
Write-Host "    SiteWebRootPath........ $sitewebroot"
Write-Host "    SuggesterJsonPath...... $PathToJson\solr-suggester-config.json"

if($UninstallCores)
{
    $question = "Do you want to proceed with deleting Solr cores for SXA?"
}
else {
    $question = "Do you want to proceed with creating Solr cores for SXA?"    
}

$choices = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice(" ", $question, $choices, 1)
if ($decision -eq 0) {    
    $sxaIndexCreateParams = @{
        Path                  = "$PathToJson\sxa-solr.json"
        SolrUrl               = $SolrUrl
        SolrRoot              = $SolrRoot
        SolrService           = $SolrService
        CorePrefix            = $SolrCorePrefix
        SiteName              = $SitecoreSiteName
        SitecoreAdminPassword = $SitecoreAdminPassword
        SiteWebRootPath       = $sitewebroot
        SuggesterJsonPath     = "$PathToJson\solr-suggester-config.json"
    }

    if($UninstallCores)
    {
        Uninstall-SitecoreConfiguration @sxaIndexCreateParams *>&1 | Tee-Object SXAIndex-Uninstall.log
        Write-Host "Solr Core uninstall for SXA completed" -ForegroundColor DarkGreen
    }
    else{
        Install-SitecoreConfiguration @sxaIndexCreateParams *>&1 | Tee-Object SXAIndex-Install.log
        Write-Host "Solr Core setup for SXA completed" -ForegroundColor DarkGreen
    }    

    
}
else {
    Write-Host "Solr Core setup was cancelled by the user." -ForegroundColor DarkYellow
}