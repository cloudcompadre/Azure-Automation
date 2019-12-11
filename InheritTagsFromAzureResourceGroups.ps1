# Inherit tags from Resource Groups using Azure Automation Playbook with RunAs.
# No Error-Handling for Classic resources and other non-taggable resources. Ignore these.
# Required PS Modules: Az.Account, Az.Resources

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    $connectionResult =  Connect-AzAccount -Tenant $servicePrincipalConnection.TenantID `
                             -ApplicationId $servicePrincipalConnection.ApplicationID   `
                             -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
                             -ServicePrincipal
    "Logged in."

}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$RGS = Get-AzResourceGroup
foreach ($RG in $RGS) {

$G = Get-AzResourceGroup -Name $RG.ResourceGroupName
if ($null -ne $G.Tags) {
    $resources = Get-AzResource -ResourceGroupName $G.ResourceGroupName
    foreach ($r in $resources)
    {
        $resourcetags = (Get-AzResource -ResourceId $r.ResourceId).Tags
        if ($resourcetags)
        {
            foreach ($key in $G.Tags.Keys)
            {
                if (-not($resourcetags.ContainsKey($key)))
                {
                    $resourcetags.Add($key, $G.Tags[$key])
                }
            }
            Set-AzResource -Tag $resourcetags -ResourceId $r.ResourceId -Force
        }
        else
        {
            Set-AzResource -Tag $G.Tags -ResourceId $r.ResourceId -Force
        }
    }
}

}
