Try
{
    "Logging in to Azure..."
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection 
     Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

    "Selecting Azure subscription..."
    Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid 
}
Catch
{
     $ErrorMessage = 'Login to Azure subscription failed.'
     $ErrorMessage += " `n"
     $ErrorMessage += 'Error: '
     $ErrorMessage += $_
     Write-Error -Message $ErrorMessage `
                   -ErrorAction Stop
}

$rgname = 'pepsico-preprod'
$vmname = 'MyVM0-pp0'
$ScriptToRun = "c:\Tools\copyfromazure.ps1"
Out-File -InputObject $ScriptToRun -FilePath ScriptToRun.ps1 
Invoke-AzureRmVMRunCommand -ResourceGroupName $rgname -Name $vmname -CommandId 'RunPowerShellScript' -ScriptPath ScriptToRun.ps1
Remove-Item -Path ScriptToRun.ps1