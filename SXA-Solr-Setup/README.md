# Sitecore Experience Accelerator (SXA) Solr Setup

Installing Sitecore Experience Accelerator (SXA) is fairly simple. You first install the package for [Sitecore PowerShell Extensions (SPE)](https://marketplace.sitecore.net/Modules/Sitecore_PowerShell_console.aspx). Then the SXA [package](https://dev.sitecore.net/Downloads/Sitecore_Experience_Accelerator/19/Sitecore_Experience_Accelerator_190.aspx)...then your done right?...well if you do not follow the installation guide closely, you'll end up like me after every install with broken features as you never installed and configured the required Solr index cores.

For those lazy and skip reading the instructions, so you miss the step that say go create Solr cores and here's how, you need [this PowerShell script](https://github.com/gillissm/TheCodeAttic.Sitecore.InstallUtilities/tree/master/SXA-Solr-Setup).

I must give recognition where its due, as the core functionality of the script is not my own, but taken from the [very helpful Sitecore Habitat Home Utilities](https://github.com/Sitecore/Sitecore.HabitatHome.Utilities). I have added a wrapper script and combined some of the configuration JSON files to hopefully help simplify the usage.

## What the Script does

In a nutshell the script will create the required Solr cores for SXA, this will be SXA_Master_Index and SXA_Web_Index. The script has logic to properly append a prefix to the above index names, allowing you to have many SXA sites up and running. (How many is to many is not for me to say.)

After creating the Solr cores, the script will go into you site web root and update the configuration files appropriately to match your prefixed named cores.

Finally, the script sets up the suggester request handler in Solr for the SXA cores.

## To Use

Enough rambling and onto the the required steps

1. Copy the following three files to a single location such as C:\sitecoreinstall\sxa-solr.
   1. [sitecore-sxa-solrinstall.ps1](https://github.com/gillissm/TheCodeAttic.Sitecore.InstallUtilities/blob/master/SXA-Solr-Setup/sitecore-sxa-solrinstall.ps1)
   2. [solr-suggester-config.json](https://github.com/gillissm/TheCodeAttic.Sitecore.InstallUtilities/blob/master/SXA-Solr-Setup/solr-suggester-config.json)
   3. [sxa-solr.json](https://github.com/gillissm/TheCodeAttic.Sitecore.InstallUtilities/blob/master/SXA-Solr-Setup/sxa-solr.json)

2. Open a PowerShell prompt running as Admin.
3. Change your directory to the folder as created in step 1
```powershell CD C:\sitecoreinstall\sxa-solr```

4. Run the script
```powershell .\sitecore-sxa-solrinstall.ps1```

5. You will be prompted to complete the following required parameters, and then be shown a check list to ensure everything is correct.
6. Enter Y or N depending on if you wish to continue with the process

![Prompt of Parameters and Continuation Question](/documentation/images/sxa-solrinstall-img1.png)

1. The script will run and upon completion you should see the following message (or if your unluckly a red message of an error.)

![Completion of Script](/documentation/images/sxa-solrinstall-img2.png)

## How to Uninstall

For whatever reason you need to delete the SXA Solr cores and reset the configuration files then you'll want to run launch the script with the *UninstallCores* flag.

```powershell .\sitecore-sxa-solrinstall.ps1 -UninstallCores```

You will then be prompted to enter the required parameters, followed by a confirmation message.

![Uninstall Solr Cores parameters and confirmation message](/documentation/images/sxa-solrinstall-img3.png)

The script will run, and you'll get a dark green confirmation or a red error message to resolve.

![Uninstall Solr Cores Completion Message](/documentation/images/sxa-solrinstall-img4.png)
