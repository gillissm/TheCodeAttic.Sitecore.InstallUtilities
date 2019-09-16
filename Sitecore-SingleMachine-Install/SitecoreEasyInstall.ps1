#define parameters

##CUSTOM TO THE ENVIRONMENT - THE FOLLOWING ALL SHOULD BE UPDATED TO REFLECT YOUR LOCAL MACHINE
###Value that will be used as the prefix for Sitecore URL, db prefix and Solr core prefixes
$prefix = "easysitecore20" 
###Path to the working directory, where this file has been saved to
$PSScriptRoot = "C:\\Sc9Install\\EasyInstall" 
###Path to the Sitecore License File
$SitecoreLicense = "C:\\SitecoreVersions\\license.xml"
###Name that Solr will run as
$SolrHostName= "solrForSitecore20"
###Version of Solr to be installed, Sitecore XP 9 will only run using Solr 6.6.2 
$SolrVersion = "6.6.2"
###Name of the MS SQL Server that will be connected to
$SqlServer = "PLW3007\LOCALSQL2017" 
###SQL Admin User that has the ability to create new databases and users
$SqlAdminUser = "sa" 
###SQL Admin Password
$SqlAdminPassword="mysupergoodpassword"
###Java Runtime currently installed
$JREVersion = "9.0.4"

##OPTIONAL UPDATES
### URL that xConnect will run on
$XConnectCollectionService = "$prefix.xconnect" 
###This is what the URL and IIS Instance will be configured for your site
$sitecoreSiteName = "$prefix.sc" 
###Directory Solr will be installed to
$SolrInstallFolder = "c:\\$SolrHostName"
###Path to the root of Solr install
$SolrRoot = "$SolrInstalLFolder\Solr-$SolrVersion" 
###Name of the NSSM server which will be created
$SolrService = "$SolrHostName-$SolrVersion"
###Change the port (default Solr install is 8983) this Solr version will run under, helpful if you have multiple Solr Instances
$SolrPort = "8983"

##DO NOT CHANGE
###Full URL to the Solr Install
$SolrUrl = "https://{0}:{1}/solr" -f $SolrHostName, $SolrPort
###Version of NSSSM (Non-Sucking Service Manager) that should be downloaded, for Windows 10 Creator Updates and above the listed 'beta' must be used.
$NSSMVersion = "2.24-101-g897c7ad"
###URL to the gist of the Solr Insall Config JSON
$SolrInstallConfigUrl ="https://gist.githubusercontent.com/gillissm/0a12078ba3a58a93f5c7a288b3e1b481/raw/015a973a14742c6725285321f3b13e06a773bf78/SolrServer.json"
###URL to the gist of the Solr Insall PowerShell Module
$SolrInstallModuleUrl = "https://gist.githubusercontent.com/gillissm/0a12078ba3a58a93f5c7a288b3e1b481/raw/015a973a14742c6725285321f3b13e06a773bf78/SolrInstall-SIF-Extensions.psm1"

#BASIC SETUP
##Setup SIF
###Register Feed Location
Write-Host -Message "Begin Registration of Sitecore MyGet Feed" -Tag "SIF Install"
$testForRepository = Get-PSRepository -Name "SitecoreGallery" -ErrorAction SilentlyContinue
if($testForRepository -eq $null){
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/f/sc-powershell/api/v2
    Write-Host -Message "Sitecore MyGet Feed Registered Successfully" -Tag "SIF Install"
}
else {
    Write-Host -Message "Sitecore MyGet Feed already registered" -Tag "SIF Install"
}

#Install SIF 
Write-Host -Message "Begin Installation of SIF" -Tag "SIF Install"
$testForSIF = Find-Module -Name SitecoreInstallFramework -ErrorAction SilentlyContinue
if($testForRepository -eq $null){
    Install-Module SitecoreInstallFramework
    Write-Host -Message "Sitecore Install Framework Successfully Installed" -Tag "SIF Install"
}
else {
    Write-Host -Message "Sitecore Install Framework already installed" -Tag "SIF Install"
}
Write-Host -Message "Update SIF" -Tag "SIF Install"
Update-Module SitecoreInstallFramework

##InstalL Sitecore Fundamentals
$testForSF = Find-Module -Name SitecoreFundamentals -ErrorAction SilentlyContinue
if($testForSF -eq $null){
    Install-Module SitecoreFundamentals
    Write-Host -Message "Sitecore Fundamentals Successfully Installed" -Tag "Sitecore Fundamentals Install"
}
else {
    Write-Host -Message "Sitecore Fundamentals already installed" -Tag "Sitecore Fundamentals Install"
}
Write-Host -Message "Update Sitecore Fundamentals" -Tag "Sitecore Fundamentals Install"
Update-Module SitecoreFundamentals

Import-Module SitecoreInstallFramework
Import-Module SitecoreFundamentals

##Get Solr Config
$solrInstallConfigPath = "$PSScriptRoot\SolrInstall-Config.json"
if(-NOT (Test-path -Path $solrInstallConfigPath)){
    (Invoke-WebRequest -UseBasicParsing -Uri $SolrInstallConfigUrl).Content | Out-File $solrInstallConfigPath -Force
    Write-TaskInfo -Message "Solr Install Config saved to $solrInstallConfigPath" -Tag "Solr Install Module Setup"
}
else {
    Write-TaskInfo -Message "Solr Install Config already existed at $solrInstallConfigPath" -Tag "Solr Install Module Setup"
}

##Get and Save Solr PowerShell Module
$modulePath =($env:PSModulePath).Split(";")[0] + "\SolrInstall-SIF-Extensions"
if(-NOT (Test-path -Path $modulePath)){
    New-Item -Path ($env:PSModulePath).Split(";")[0] -ItemType Directory -Name "SolrInstall-SIF-Extensions"
    (Invoke-WebRequest -UseBasicParsing -Uri $SolrInstallModuleUrl).Content | Out-File "$modulePath\SolrInstall-SIF-Extensions.psm1" -Force
    Write-TaskInfo -Message "Solr module saved to $modulePath" -Tag "Solr Install Module Setup"
}
else
{
    Write-TaskInfo -Message "Solr module already existed at $modulePath" -Tag "Solr Install Module Setup"
}

##install Solr
$solrInstallParams =@{
    Path =  "$PSScriptRoot\SolrInstall-Config.json"
    JREVersion = $JREVersion
    SolrVersion = $SolrVersion
    NSSMVersion = $NSSMVersion
    InstallFolder = $SolrInstallFolder
    DownloadFolder = $PSScriptRoot
    SolrUseSSL = $true
    SolrHost = $SolrHostName
    SolrPort = $SolrPort
    SolrServiceName = $SolrService
}

Install-SitecoreConfiguration @solrInstallParams 


#install client certificate for xconnect 
$certParams = @{ 
    Path = "$PSScriptRoot\xconnect-createcert.json" 
    CertificateName = "$prefix.xconnect_client" 
} 
Install-SitecoreConfiguration @certParams -Verbose 

#install solr cores for xdb 
$solrParams = @{ 
    Path = "$PSScriptRoot\xconnect-solr.json" 
    SolrUrl = $SolrUrl 
    SolrRoot = $SolrRoot 
    SolrService = $SolrService 
    CorePrefix = $prefix 
} 
Install-SitecoreConfiguration @solrParams 

#deploy xconnect instance 
$xconnectParams = @{ 
    Path = "$PSScriptRoot\xconnect-xp0.json" 
    Package = "$PSScriptRoot\Sitecore 9.0.1 rev. 171219 (OnPrem)_xp0xconnect.scwdp.zip" 
    LicenseFile = $SitecoreLicense
    Sitename = $XConnectCollectionService 
    XConnectCert = $certParams.CertificateName 
    SqlDbPrefix = $prefix 
    SqlServer = $SqlServer 
    SqlAdminUser = $SqlAdminUser 
    SqlAdminPassword = $SqlAdminPassword 
    SolrCorePrefix = $prefix 
    SolrURL = $SolrUrl 
} 
Install-SitecoreConfiguration @xconnectParams 

#install solr cores for sitecore 
$solrParams = @{ 
    Path = "$PSScriptRoot\sitecore-solr.json" 
    SolrUrl = $SolrUrl 
    SolrRoot = $SolrRoot 
    SolrService = $SolrService 
    CorePrefix = $prefix 
} 
Install-SitecoreConfiguration @solrParams 

#install sitecore instance 
$xconnectHostName = "$prefix.xconnect" 
$sitecoreParams = @{ 
    Path = "$PSScriptRoot\sitecore-XP0.json" 
    Package = "$PSScriptRoot\Sitecore 9.0.1 rev. 171219 (OnPrem)_single.scwdp.zip" 
    LicenseFile = $SitecoreLicense
    SqlDbPrefix = $prefix 
    SqlServer = $SqlServer 
    SqlAdminUser = $SqlAdminUser 
    SqlAdminPassword = $SqlAdminPassword 
    SolrCorePrefix = $prefix 
    SolrUrl = $SolrUrl 
    XConnectCert = $certParams.CertificateName 
    Sitename = $sitecoreSiteName 
    XConnectCollectionService = "https://$XConnectCollectionService"
}
Install-SitecoreConfiguration @sitecoreParams