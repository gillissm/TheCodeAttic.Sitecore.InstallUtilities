##
## private functions
##

#
# If necessary, download a file and unzip it to the specified location
#
function downloadAndUnzipIfRequired
{
    Param(
        [string]$toolName,
        [string]$toolFolder,
        [string]$toolZip,
        [string]$toolSourceFile,
        [string]$installRoot
    )

    if(!(Test-Path -Path $toolFolder))
    {
        if(!(Test-Path -Path $toolZip))
        {
            Write-TaskInfo -Message $toolSourceFile -Tag "Downloading $toolName"
            if($pscmdlet.ShouldProcess("$toolSourceFile", "Download source file"))
            {
                Start-BitsTransfer -Source $toolSourceFile -Destination $toolZip
            }
        }
        else
        {
            Write-TaskInfo -Message $toolZip -Tag "$toolName already downloaded"
        }

        Write-TaskInfo -Message $targetFile -Tag "Extracting $toolName"
        if($pscmdlet.ShouldProcess("$toolZip", "Extract archive file"))
        {
            Expand-Archive $toolZip -DestinationPath $installRoot -Force
        }
    }
    else
    {
        Write-TaskInfo -Message $toolFolder -Tag "$toolName folder already exists - skipping"
    }
}

#
# Update the Solr configuration with the changes for HTTP access
#
function configureHTTP
{
    Param(
        [string]$solrHost,
        [string]$solrRoot
    )

    $solrConfig = "$solrRoot\bin\solr.in.cmd"
    if(!(Test-Path -Path "$solrConfig.old"))
    {
        if($pscmdlet.ShouldProcess("$solrConfig", "Rewriting Solr config file HTTP"))
        {
            $cfg = Get-Content $solrConfig
            Rename-Item $solrConfig "$solrConfig.old"
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
            $newCfg | Set-Content $solrConfig
        }

        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config updated for HTTP access"
    }
    else
    {
        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config already updated for HTTP access - skipping"
    }
}

#
# Update the Solr configuration with the changes for HTTPS access
#
function configureHTTPS
{
    Param(
        [string]$solrHost,
        [string]$solrRoot,
        [string]$certStore
    )

    $solrConfig = "$solrRoot\bin\solr.in.cmd"
    if(!(Test-Path -Path "$solrConfig.old"))
    {
        if($pscmdlet.ShouldProcess("$solrConfig", "Rewriting Solr config file for HTTPS"))
        {
            $cfg = Get-Content $solrConfig
            Rename-Item $solrConfig "$solrRoot\bin\solr.in.cmd.old"
            $newCfg = $cfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certStore" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=secret" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certStore" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=secret" }
            $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
            $newCfg | Set-Content $solrConfig
        }

        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config updated for HTTPS access"
    }
    else
    {
        Write-TaskInfo -Message "$solrConfig" -Tag "Solr config already updated for HTTPS access - skipping"
    }
}

##
## Exported functions
##

#
# Download and unzip the appropriate version of NSSM if it's not already in place
#
function Invoke-EnsureNSSMTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$downloadFolder,

        [parameter(Mandatory=$true)]
        [string]$nssmVersion,

        [parameter(Mandatory=$true)]
        [string]$nssmSourcePackage,
        
        [parameter(Mandatory=$true)]
        [string]$installFolder
    )

    PROCESS
    {
        $targetFile = "$installFolder\nssm-$nssmVersion"
        $nssmZip = "$downloadFolder\nssm-$nssmVersion.zip"

        Write-TaskInfo -Message "$nssmVersion" -Tag "Ensuring NSSM installed"

        downloadAndUnzipIfRequired "NSSM" $targetFile $nssmZip $nssmSourcePackage $installFolder
    }
}

#
# Download and unzip the appropriate version of Solr if it's not already in place
#
function Invoke-EnsureSolrTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$downloadFolder,

        [parameter(Mandatory=$true)]
        [string]$solrVersion,

        [parameter(Mandatory=$true)]
        [string]$solrSourcePackage,
        
        [parameter(Mandatory=$true)]
        [string]$installFolder
    )

    PROCESS
    {
        $targetFile = "$installFolder\solr-$solrVersion"
        $solrZip = "$downloadFolder\solr-$solrVersion.zip"

        Write-TaskInfo -Message "$solrVersion" -Tag "Ensuring Solr installed"

        downloadAndUnzipIfRequired "Solr" $targetFile $solrZip $solrSourcePackage $installFolder
    }
}

#
# Update the JAVA_HOME environment variable if required
#
function Invoke-EnsureJavaHomeTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$jrePath
    )

    PROCESS
    {
        $jreVal = [Environment]::GetEnvironmentVariable("JAVA_HOME", [EnvironmentVariableTarget]::Machine)
        if($jreVal -ne $jrePath)
        {
            Write-TaskInfo -Message "$jrePath" -Tag "Ensuring JAVA_HOME environment variable set"

            Write-Host "Setting JAVA_HOME environment variable"
            if($pscmdlet.ShouldProcess("$jrePath", "Setting JAVA_HOME environment variable"))
            {
                [Environment]::SetEnvironmentVariable("JAVA_HOME", $jrePath, [EnvironmentVariableTarget]::Machine)
            }
        }
        else
        {
            Write-TaskInfo -Message "$jrePath" -Tag "JAVA_HOME environment variable already set - skipping"
        }
    }
}

#
# Make sure that the solr host name exists in the hosts file
#
function Invoke-EnsureHostNameTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$solrHost
    )

    PROCESS
    {
        $hostFileName = "c:\\windows\system32\drivers\etc\hosts"
        $hostFile = [System.Io.File]::ReadAllText($hostFileName)
        if(!($hostFile -like "*$solrHost*"))
        {
            Write-TaskInfo -Message "$solrHost" -Tag "Adding host entry"
            if($pscmdlet.ShouldProcess("$solrHost", "Configure host file entry"))
            {
                "`r`n127.0.0.1`t$solrHost" | Add-Content $hostFileName
            }
        }
        else
        {
            Write-TaskInfo -Message "$solrHost" -Tag "Host entry already set - skipping"
        }
    }
}

#
# Process the configuration changes necessary for Solr to run
#
function Invoke-ConfigureSolrTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [bool]$solrSSL,
        [parameter(Mandatory=$true)]
        [string]$solrHost,
        [parameter(Mandatory=$true)]
        [string]$solrRoot,
        [parameter(Mandatory=$true)]
        [string]$certificateStore
    )

    PROCESS
    {
        if($solrSSL)
        {
            Write-TaskInfo -Message "HTTPS" -Tag "Configuring Solr for HTTPS access"
            configureHTTPS $solrHost $solrRoot $certificateStore
        }
        else
        {
            Write-TaskInfo -Message "HTTP" -Tag "Configuring Solr for HTTP access"
            configureHTTP $solrHost $solrRoot
        }
    }
}

#
# Ensure that a trusted SSL Certificate exists for the Solr host name, and export it for Solr to use
#
function Invoke-EnsureSSLCertificateTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [bool]$solrSSL,
        [parameter(Mandatory=$true)]
        [string]$solrName,
        [parameter(Mandatory=$true)]
        [string]$solrHost,
        [parameter(Mandatory=$true)]
        [string]$certificateStore
    )

    PROCESS
    {
        if($solrSSL)
        {
            # Generate SSL cert
            $existingCert = Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -eq "$solrName"
            if(!($existingCert))
            {
                Write-TaskInfo -Message "$solrHost" -Tag "Creating and trusting an new SSL Cert"

                if($pscmdlet.ShouldProcess("$solrHost", "Generate new trusted SSL certificate"))
                {
                    # Generate a cert
                    # https://docs.microsoft.com/en-us/powershell/module/pkiclient/new-selfsignedcertificate?view=win10-ps
                    $cert = New-SelfSignedCertificate -FriendlyName "$solrName" -DnsName "$solrHost" -CertStoreLocation "cert:\LocalMachine" -NotAfter (Get-Date).AddYears(10)                                     
                  
                    # https://stackoverflow.com/questions/8815145/how-to-trust-a-certificate-in-windows-powershell
                    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
                    $store.Open("ReadWrite")
                    $store.Add($cert)
                    $store.Close()

                    # remove the untrusted copy of the cert
                    $cert | Remove-Item
                }
            }
            else
            {
                Write-TaskInfo -Message "$solrHost" -Tag "Trusted SSL certificate already exists - skipping"
            }

            # export the cert to pfx using solr's default password
            if(!(Test-Path -Path $certificateStore))
            {
                Write-TaskInfo -Message "$certificateStore" -Tag "Exporting certificate to disk"

                $cert = Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -eq "$solrName"
    
                $certPwd = ConvertTo-SecureString -String "secret" -Force -AsPlainText

                if($pscmdlet.ShouldProcess("$certificateStore", "Export certificate to disk"))
                {
                    $cert | Export-PfxCertificate -FilePath $certificateStore -Password $certpwd | Out-Null
                }
            }
            else
            {
                Write-TaskInfo -Message "$certificateStore" -Tag "Certificate file already exported - skipping"
            }
        }
    }
}


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

Register-SitecoreInstallExtension -Command Invoke-EnsureNSSMTask -As EnsureNssm -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureSolrTask -As EnsureSolr -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureJavaHomeTask -As EnsureJavaHome -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureHostNameTask -As EnsureHostName -Type Task
Register-SitecoreInstallExtension -Command Invoke-ConfigureSolrTask -As ConfigureSolr -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureSSLCertificateTask -As EnsureSSLCertificate -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureSolrServiceTask -As EnsureSolrService -Type Task
Register-SitecoreInstallExtension -Command Confirm-SolrInstallTask -As SolrInstall -Type Task