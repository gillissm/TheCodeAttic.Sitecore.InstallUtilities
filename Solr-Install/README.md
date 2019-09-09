# Installing Solr

## Summary

This is a re-package of the Solr Install script created by Jeremy Davis in 2017, and found at https://gist.github.com/jermdavis/49018386ae7544ce0689568edb7ca2b8 in which I forked in February 2018 for use with Sitecore installations.

## How to Use

1. Open a PowerShell command prompt with 'Run as Administrator'
2. At the prompt change the directory the location of this file
3. Ensure that Sitecore Installation Framework is installed by running
```powershell Get-Module SitecoreInstallFramework -ListAvailable```
4. You need to confirm that you have at least 2.0.0 installed, updates can be achieved by running
```powershell Update-Module SitecoreInstallFramework```
5. Update the following minimal parameters in *SolrInstal-Config.json* to represent your environment
   1. InstallFolder
   2. SolrHost
   3. SolrPort
   4. SolrServiceName
   5. SolrVersion
   6. JREVersion
6. Run the following command
```powershell  Install-SitecoreConfiguration .\SolrInstall-config.json```
7. If you at first get a cannot connect message in the browser, refresh and the Solr Admin UI should display

### Optional Install Steps

1. Update the following minimal parameters in *SolrInstal-Config.json* to represent your environment
   1. InstallFolder
   2. SolrHost
   3. SolrPort
   4. SolrServiceName
   5. SolrVersion
   6. JREVersion
2. Run the following: ```powershell .\Install-Solr.ps1```
   1. This will run a script that ensures that Sitecore Install Framework is on the machine and then runs the Solr installation based on the SolrInstall-config.json.