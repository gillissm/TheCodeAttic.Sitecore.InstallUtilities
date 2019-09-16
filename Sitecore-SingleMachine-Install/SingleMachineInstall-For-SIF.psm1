
#
# Ensure that a service exists to run the specified version of Solr
#
function Invoke-EnsureSolrServiceTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$solrName,
        [parameter(Mandatory=$true)]
        [string]$installFolder,
        [parameter(Mandatory=$true)]
        [string]$nssmVersion,
        [parameter(Mandatory=$true)]
        [string]$solrRoot,
        [parameter(Mandatory=$true)]
        [string]$solrPort
    )

    PROCESS
    {
        $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
        if(!($svc))
        {
            Write-TaskInfo -Message "$solrName" -Tag "Installing Solr service"

            if($pscmdlet.ShouldProcess("$solrName", "Install Solr service using NSSM"))
            {
                &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrName" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
            }

            $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
        }
        else
        {
            Write-TaskInfo -Message "$solrName" -Tag "Solr service already installed - skipping"
        }

        if($svc.Status -ne "Running")
        {
            Write-TaskInfo -Message "$solrName" -Tag "Starting Solr service"

            if($pscmdlet.ShouldProcess("$solrName", "Starting Solr service"))
            {
                Start-Service "$solrName"
            }
        }
        else
        {
            Write-TaskInfo -Message "$solrName" -Tag "Solr service already started - skipping"
        }
    }
}

#
# Verify Solr is working by opening a browser to the admin UI.
#
function Confirm-SolrInstallTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [bool]$solrSSL,
        [parameter(Mandatory=$true)]
        [string]$solrHost,
        [parameter(Mandatory=$true)]
        [string]$solrPort
    )

    PROCESS
    {
        $protocol = "http"
        if($solrSSL -eq $true)
        {
            $protocol = "https"
        }
        $url = "$($protocol)://$($solrHost):$solrPort/solr/"
        Write-TaskInfo -Message "$url" -Tag "Verifying Solr is running"
        if($pscmdlet.ShouldProcess("$url", "Open Solr in default browser to verify it"))
        {
            Invoke-Expression "start $url"
        }
    }
}






Register-SitecoreInstallExtension -Command Invoke-EnsureSolrServiceTask -As EnsureSolrService -Type Task
Register-SitecoreInstallExtension -Command Confirm-SolrInstallTask -As SolrInstall -Type Task