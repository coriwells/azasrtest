<# 
    .DESCRIPTION 
        This will create a Public IP address for the failed over VM(s). 
         
        Pre-requisites 
        All resources involved are based on Azure Resource Manager (NOT Azure Classic)

        The following AzureRm Modules are required
        - AzureRm.Profile
        - AzureRm.Resources
        - AzureRm.Compute
        - AzureRm.Network

        How to add the script? 
        Add the runbook as a post action in boot up group containing the VMs, where you want to assign a public IP.. 
         
        Clean up test failover behavior 
        You must manually remove the Public IP interfaces 
 
    .NOTES 
        AUTHOR: krnese@microsoft.com 
        LASTEDIT: 20 March, 2017 
#> 
param ( 
        [Object]$RecoveryPlanContext 
      ) 

Write-Output $RecoveryPlanContext

if($RecoveryPlanContext.FailoverDirection -ne 'PrimaryToSecondary')
{
    Write-Output 'Script is ignored since Azure is not the target'
}
else
{

    $vmMapId = $RecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | Select -ExpandProperty Name
    $vmMapData = $recoveryPlanContext.vmMap.$vmMapId
    $vmMapRG = $recoveryPlanContext.vmMap.$vmMapId.ResourceGroupName

    Write-Output ("Found the following VMGuid(s): `n" + $vmMapId)

    if ($vmMapId -is [system.array])
    {
        $vmMapId = $vmMapId[0]

        Write-Output "Found multiple VMs in the Recovery Plan"
    }
    else
    {
        Write-Output "Found only a single VM in the Recovery Plan"
    }

    $vmMapRG = $RecoveryPlanContext.VmMap.$vmMapId.ResourceGroupName

    Write-OutPut ("Name of resource group: " + $vmMapRG)
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
    # Get VMs within the Resource Group
Try
 {
    $VMs = Get-AzureRmVm -ResourceGroupName $vmMapRG
    Write-Output ("Found the following VMs: `n " + $VMs.Name) 
 }
Catch
 {
      $ErrorMessage = 'Failed to find any VMs in the Resource Group.'
      $ErrorMessage += " `n"
      $ErrorMessage += 'Error: '
      $ErrorMessage += $_
      Write-Error -Message $ErrorMessage `
                    -ErrorAction Stop
 }
Try
 {
    foreach ($VM in $VMs)
    {
        $VMostype = Get-AzureRmVM -ResourceGroupName $vmMapRG -Name $VM.Name | Select Name,@{Name='OSType'; Expression={$_.StorageProfile.OSDisk.OSType}}
        Write-Output ("This vm is  `n " + $VM.Name)
        Write-Output ("Has the Operating System `n " + $VMostype.OSType)  
        if ($VMostype.OSType = "Linux") {
            Invoke-AzureRmVMRunCommand -ResourceGroupName $vmMapRG -VMName $VM.Name -CommandId 'RunShellScript' -ScriptPath '/copytoazure.sh'
        }
        else {
            Invoke-AzureRmVMRunCommand -ResourceGroupName $vmMapRG -VMName $VM.Name -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Tools\copytoazure.ps1'        }
    }
    Write-Output ("Operation completed on the following VM(s): `n" + $VMs.Name)
 }
Catch
 {
      $ErrorMessage = 'Failed to move files as requested.'
      $ErrorMessage += " `n"
      $ErrorMessage += 'Error: '
      $ErrorMessage += $_
      Write-Error -Message $ErrorMessage `
                    -ErrorAction Stop
 }
}