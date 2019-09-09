
#Check for Sitecore Gallery regristration, if not regestered add it.
if(!(Get-PSRepository | Where-Object{$_.Name -eq "SitecoreGallery"})){Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2;}

#Install Sitecore Install Framewokr
Install-Module SitecoreInstallFramework

#Update SitecoreInstallFramework
Update-Module SitecoreInstallFramework

Install-SitecoreConfiguration .\SolrInstall-config.json