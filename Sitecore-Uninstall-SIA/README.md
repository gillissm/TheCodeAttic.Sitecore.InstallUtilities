# Uninstalling an Instance Created by Sitecore Install Assistant

Sitecore 9.2 introduced the new and very nice Sitecore Install Assistant (SIA). It provides a nice GUI wrapper to the tedious task of managing JSON files and PowerShell scripts to installing a local developer instance.

The downside to the nice GUI is how do you uninstall the instance created.

SIF 2 (Sitecore Install Framework) included an uninstall task ```powershell Uninstall-SitecoreConfiguration –Path .\sitecore-XP0.json```. Helpful that it exists, but not helpful directly as we do not get a JSON config when using SIA.

