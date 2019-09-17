# Sitecore Experience Accelerator (SXA) Solr Setup

If you are note following the install instructions closely it is easy to forget about the need to create the required indexes in Solr to support Sitecore Experience Accelerator (SXA).

The actual installation guide walks you through creating the indexes manually, but who wants to do that ever.

The following is a variation on SXA install scripts provided as part of the [very helpful Sitecore Habitat Home Utilities](https://github.com/Sitecore/Sitecore.HabitatHome.Utilities).

  //Based on the sxa-solr.json file found in Sitecore Habitat Home Utilities found at https://github.com/Sitecore/Sitecore.HabitatHome.Utilities

## To Use

1. Update 


Based on the SXA scripts found in the Sitecore Habitat Home Utilities, https://github.com/Sitecore/Sitecore.HabitatHome.Utilities, repository.
This provides a single script to create SXA required Solr cores, update the Sitecore instances configuration files, and add SXA Suggest request handler to Solr.

The script requires the usage of two JSON configuration files to work properly. By default the script looks in the directory that it is being executred from ($PSScriptRoot).
An optional parameter ($PathToJson) is available.

The script also contains an uninstall/cleanup flag allowing one to indicate the deletion/cleanup of the SXA Cores.