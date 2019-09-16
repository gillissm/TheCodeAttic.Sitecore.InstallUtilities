# Sitecore Single Machine Install

This directory include the basic scripts required to perform a *developer* machine install (ie all compontents on a single machine.)

This is based on scripts I created March 2018 to simplify the installation of Sitecore 9.0, https://gist.github.com/gillissm/1a3d826e6287e4cd106acea941748643. (For full details see the corresponding blog post https://thecodeattic.wordpress.com/2018/04/03/the-easier-way-to-sitecore-xp-9/.) My team and I have continued to use this script with minimal modifications for local installs.

As Sitecore has updated features and scripts (introducing the Sitecore Install Assistant), I thought this would be a good time revamp my install scripts and utilities. In addition, to taking into consideration the Sitecore Installation Assistant, I have been leveraging the very nice [Sitecore.HabitatHome.Utilities](https://github.com/Sitecore/Sitecore.HabitatHome.Utilities) which provide some additional scripts and logic for performing not just site installation but also the installation of Sitecore modules.

## Why Not the Sitecore Install Assistant

The Sitecore Install Assistant (SIA) does a nice job at simplifying the installation, requiring you never to have to open a PowerShell prompt or a JSON file for updates...BUT it is also a bit limiting in what it allows for you to dictate. A couple items I miss having control over are:

* Full host name definition...the SIA prompts for a pre-fix then appends 'sc.dev.local' to it.
* HTTPS binding of the Sitecore site
* Control freak...I need to feel the power...
