##########################################################################
# Automate PIM and JIT requests
##########################################################################
# This  scripts must be pasted in the Azure cloud shell 
# Theo Ekelmans - 2024-08-15 - theo.ekelmans@ordina.nl
##########################################################################
# Version - Date - Who - Change
#-------------------------------------------------------------------------
# 1.0 - 2024-08-15 - Theo - Initial version
#
# ToDo: Check GetEligibleRoles against GetActiveRoles and only activate
#       non-active roles
##########################################################################
# Usage:
# 
# Choose your variables below, and then paste everyting into a cloudshell
##########################################################################
# Filter the ScopeDisplayNames you want to PIM for, if you don't know for
# which roles you are eligible, run the GetEligibleRoles command 

#$NameFilter = '*riskf*' # RiskFactor only
$NameFilter = '*aq*'  # Aqaurius only
#$NameFilter = '*'  # everything

$StartDT = Get-Date -Format o # When should the PIM window start
$duration = 'PT8H' # PIM window size: Period Time 8 Hours
$reason = "Requested by: " + (az ad signed-in-user show)[3].Split(":")[1].replace('"', '').replace(',','') + " for DB maintenance"
##########################################################################

#####################################
#Show eligible roles for this tenant
#####################################
function GetEligibleRoles {

    Get-AzRoleEligibilitySchedule -Scope "/" -Filter "asTarget()" `
    | Where-Object { (@('resourcegroup', 'subscription') -contains $_.ScopeType) } `
    | Group-Object RoleDefinitionDisplayName, Scope, RoleDefinitionId `
    | Select-Object @{ Expression = { $_.group[0] } ; Label = 'Item' } `
    | Select-Object -ExpandProperty item `
    | Select-Object PrincipalDisplayName, `
                    ScopeDisplayName, `
                    Status, `
                    @{n = 'CreatedOn';     e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.CreatedOn),     'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    @{n = 'UpdatedOn';     e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.UpdatedOn),     'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    @{n = 'StartDateTime'; e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.StartDateTime), 'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    @{n = 'EndDateTime';   e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.EndDateTime),   'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    RoleDefinitionDisplayName `
    | Format-Table * -force
}

#GetEligibleRoles

#####################################
#Show Active roles
#####################################
function GetActiveRoles {
    #Get the info at the tenant level 
    Get-AzRoleAssignmentScheduleInstance -Scope '/' -Filter "asTarget()" `
    | Select-Object ScopeDisplayName, `
                    @{n = 'StartDateTime'; e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.StartDateTime), 'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    @{n = 'EndDateTime'; e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.EndDateTime), 'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    Status, `
                    AssignmentType `
    | Format-Table * -force
    }

#GetActiveRoles  

#####################################
#Activate my roles
#####################################
function ActivateRoles {
    param (
        [CmdletBinding()]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [String]$NameFilter,
        [String]$duration,
        [String]$reason,
        [datetime]$StartDT
    )

    Get-AzRoleEligibilitySchedule -Scope "/" -Filter "asTarget()" `
    | Where-Object { (@('resourcegroup', 'subscription') -contains $_.ScopeType)  -and ($_.Scope -like "$NameFilter" ) } `
    | Group-Object RoleDefinitionDisplayName, Scope `
    | Select-Object @{ Expression = { $_.group[0] } ; Label = 'Item' } `
    | Select-Object -ExpandProperty item `
    | ForEach-Object {
        $p = @{
            Name                      = (New-Guid).Guid
            Scope                     = $_.Scope
            PrincipalId               = (az ad signed-in-user show)[5].Split(":")[1].replace('"', '').replace(',','').replace(' ','') 
            RoleDefinitionId          = $_.RoleDefinitionId
            ScheduleInfoStartDateTime = $StartDT
        }
        
        New-AzRoleAssignmentScheduleRequest @p -ExpirationDuration $duration -ExpirationType AfterDuration -RequestType SelfActivate -Justification $reason 
        #$p
    }
}



#####################################
# Show eligible roles for this tenant
# and their activation status
#####################################
function getRoleStatus {
    param (
        [CmdletBinding()]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [String]$NameFilter
    )

    $EligibileRoles =     Get-AzRoleEligibilitySchedule -Scope "/" -Filter "asTarget()" `
    | Where-Object { (@('resourcegroup', 'subscription') -contains $_.ScopeType)  -and ($_.Scope -like "$NameFilter" ) } `
    | Group-Object RoleDefinitionDisplayName, Scope, RoleDefinitionId `
    | Select-Object @{ Expression = { $_.group[0] } ; Label = 'Item' } `
    | Select-Object -ExpandProperty item `
    | Select-Object PrincipalDisplayName, `
                    ScopeDisplayName, `
                    @{n = 'Status'; e = { 'Eligible' }}, `
                    @{n = 'ActivationStart'; e = { '-' }}, `
                    @{n = 'ActivationEnd';   e = { '-' }}, `
                    @{n = 'AssignmentType'; e = { '-' }} `
    
    #Get the ActiveRoles info at the tenant level 
    $ActiveRoles = Get-AzRoleAssignmentScheduleInstance -Scope '/' -Filter "asTarget()" `
    | Select-Object ScopeDisplayName, `
                    Status, `
                    @{n = 'ActivationStart'; e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.StartDateTime), 'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    @{n = 'ActivationEnd'; e = { get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($_.EndDateTime), 'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' }}, `
                    AssignmentType `

    # update gaat niet goed als de waarde niet worden gevonden, insert een null of een ''
    foreach($er in $EligibileRoles){

        $ar = $ActiveRoles | Where-Object {$er.ScopeDisplayName -eq $_.ScopeDisplayName}
        if($null -ne $ar) {
            $er.Status = 'Activated'
            $er.ActivationStart = $ar.ActivationStart
            $er.ActivationEnd = $ar.ActivationEnd
            $er.AssignmentType = $ar.AssignmentType
        }   
    }

    $EligibileRoles
}

###############################
#Request all JIT's
#note: this list is slow!
###############################
function ActivateJit
{
    param (
        [CmdletBinding()]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [String]$NameFilter
    )

$ServerList = @()
$JitResult = @()

Write-Host '##############################################################################' 
Write-Host 'Scanning all subscriptions/resourcegroups for VMs with JIT' 
Write-Host '##############################################################################' 

Write-Host 'Gathering info for: <SubscriptionName> - <ResourceGroupName> - <VmName>' 
Write-Host '------------------------------------------------------------------------------' 

$Subscriptions = Get-AzSubscription | Where-Object { ($_.Name -like "$NameFilter" ) } 
ForEach ($Subscription in $Subscriptions) {
    $SubscriptionName = $Subscription.Name

    Set-AzContext -SubscriptionName "$SubscriptionName" | Out-Null
    $RGs = Get-AzResourceGroup 
        foreach ($RG in $RGs) {

            #Get the JIT policies for this resourcegroup
            $AzJITPolicies = Get-AzJitNetworkAccessPolicy -ResourceGroupName $RG.ResourceGroupName

            # # Show the policy details per VM for this resourcegroup
            # foreach ($VMJP in $AzJITPolicies.VirtualMachines){
            #     $VMJP.Id
            #     $VMJP.Ports.MaxRequestAccessDuration
            #     $VMJP.Ports.Number
            #     $VMJP.Ports.Protocol
            # }

            #Go though all the VM's in this resourcegroup that have a JIT policy attached and assemble the info per VM 
            $VMs = Get-AzVM -ResourceGroupName $RG.ResourceGroupName | Where-Object {$_.Id -in $AzJITPolicies.VirtualMachines.Id}
            foreach ($VM in $VMs) {

                $ResourceGroupName = $RG.ResourceGroupName
                $VmName = $VM.Name

                Write-Host 'Gathering info for:'$SubscriptionName' - '$ResourceGroupName' - '$VmName

                $VmPrivateIP = Get-AzNetworkInterface `
                | Where-Object { $_.VirtualMachine -and $_.IPConfigurations -and $_.IPConfigurations.PrivateIPAddress -and $_.Name -Match "$($VmName)*" } `
                | Select-Object @{n="PrivateIPAddress"; e= { $_.IpConfigurations.PrivateIPAddress }}

                # VM Status (running/deallocated/stopped)
                $VMDetail = Get-AzVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Status
                $VMStatusDetail = $VMDetail.Statuses.DisplayStatus -match "^VM .*$"
                
                $item = New-Object psobject
                $item |Add-Member -type NoteProperty -Name "Subscription" -Value $SubscriptionName
                $item |Add-Member -type NoteProperty -Name "ResourceGroup" -Value $RG.ResourceGroupName
                $item |Add-Member -type NoteProperty -Name "VMName" -Value $VM.Name
                $item |Add-Member -type NoteProperty -Name "VmSize" -Value $VM.HardwareProfile.VMSize  
                $item |Add-Member -type NoteProperty -Name "VMStatus" -Value "$VMStatusDetail"
                $item |Add-Member -type NoteProperty -Name "OSType" -Value $VM.StorageProfile.OSDisk.OSType
                $item |Add-Member -type NoteProperty -Name "OSVersion" -Value $Vm.StorageProfile.ImageReference.Sku
                $item |Add-Member -type NoteProperty -Name "AvailabilityZone" -Value $VM.Zones[0]
                $item |Add-Member -type NoteProperty -Name "PrivateIP" -Value $VmPrivateIP.PrivateIPAddress
                $item |Add-Member -type NoteProperty -Name "JitName" -Value $AzJITPolicies.Name
                $item |Add-Member -type NoteProperty -Name "Duration" -Value ($AzJITPolicies.VirtualMachines | Where-Object {$_.Id -eq $VM.Id}).Ports.MaxRequestAccessDuration
                $item |Add-Member -type NoteProperty -Name "Port" -Value ($AzJITPolicies.VirtualMachines | Where-Object {$_.Id -eq $VM.Id}).Ports.Number
                $item |Add-Member -type NoteProperty -Name "Protocol" -Value ($AzJITPolicies.VirtualMachines | Where-Object {$_.Id -eq $VM.Id}).Ports.Protocol
                $item |Add-Member -type NoteProperty -Name "Prefix" -Value ($AzJITPolicies.VirtualMachines | Where-Object {$_.Id -eq $VM.Id}).Ports.AllowedSourceAddressPrefix
                $item |Add-Member -type NoteProperty -Name "VMid" -Value $VM.Id
                
                $ServerList += $item

           }
        }   
    }

# $ServerList | Format-Table Subscription,ResourceGroup,VMName,VmSize,VMStatus,AvailabilityZone,JitName,Duration,PrivateIP,Port,Protocol -force

Write-Host '------------------------------------------------------------------------------' 
Write-Host 'Requesting JIT access for: <SubscriptionName> - <VmName>'
Write-Host '------------------------------------------------------------------------------' 

foreach($Server in $ServerList){

    $SubscriptionName = $Server.Subscription
    $AzureVMName = $Server.VMName

    Write-Host 'Requesting JIT access for:'$($SubscriptionName)'-'$($AzureVMName) 

    $AzSubscription = Select-AzSubscription -Subscription (get-azsubscription | Where-Object {$_.Name -match $SubscriptionName} ) 
    $vm = Get-AzVM -Name $AzureVMName
    $IpPrefix = $Server.Prefix
    
    $JitPolicy = (@{
            id    = $vm.Id; 
            ports = (@{
                    number                     = $Server.Port
                    endTimeUtc                 = Get-Date (Get-Date -AsUTC).AddHours(1) -Format O #ToDo: extract this from PT1H
                    allowedSourceAddressPrefix = @($IpPrefix) 
                })
        })
    $ActivationVM = @($JitPolicy)
    $Result = Start-AzJitNetworkAccessPolicy -ResourceGroupName $($vm.ResourceGroupName) -Location $vm.Location -Name "default" -VirtualMachine $ActivationVM

    $item = New-Object psobject
    $item |Add-Member -type NoteProperty -Name "Subscription" -Value $Server.Subscription
    $item |Add-Member -type NoteProperty -Name "ResourceGroup" -Value $Server.ResourceGroup
    $item |Add-Member -type NoteProperty -Name "VMName" -Value $Server.VMName
    $item |Add-Member -type NoteProperty -Name "VmSize" -Value $Server.VmSize
    $item |Add-Member -type NoteProperty -Name "VMStatus" -Value $Server.VMStatus
    #$item |Add-Member -type NoteProperty -Name "OSType" -Value $Server.OSType
    #$item |Add-Member -type NoteProperty -Name "OSVersion" -Value $Server.OSVersion
    $item |Add-Member -type NoteProperty -Name "AZ" -Value $Server.AvailabilityZone
    $item |Add-Member -type NoteProperty -Name "PrivateIP" -Value $Server.PrivateIP
    $item |Add-Member -type NoteProperty -Name "JitName" -Value $Server.JitName
    $item |Add-Member -type NoteProperty -Name "Duration" -Value $Server.Duration
    $item |Add-Member -type NoteProperty -Name "Port" -Value $Server.Port
    $item |Add-Member -type NoteProperty -Name "Protocol" -Value $Server.Protocol
    $item |Add-Member -type NoteProperty -Name "Prefix" -Value $Server.Prefix
    #$item |Add-Member -type NoteProperty -Name "VMid" -Value $Server.VMid
    $item |Add-Member -type NoteProperty -Name "StartDT" -Value (get-date ([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( ($Result.StartTimeUtc), 'Central European Standard Time')) -format 'yyyy-MM-dd HH:mm:ss' )
    
    $JitResult += $item

}
Write-Host '------------------------------------------------------------------------------' 
Write-Host 'Done, result below'
Write-Host '------------------------------------------------------------------------------' 
$JitResult | Format-Table * -force

}

#####################################
# Automate PIM and JIT
#####################################
function AutomatePimJit {
    param (
        [CmdletBinding()]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [String]$NameFilter,
        [String]$duration,
        [String]$reason,
        [datetime]$StartDT
    )
    Clear-Host

    Write-Host '------------------------------------------------------------------------------' 
    Write-Host 'Activate my roles for: '$NameFilter 
    Write-Host '------------------------------------------------------------------------------' 
    ActivateRoles $NameFilter $duration $reason $StartDT

    do {
        $RoleState = getRoleStatus $NameFilter

        Clear-Host
        Write-Host '------------------------------------------------------------------------------' 
        Write-Host 'Wait until the PIM requests are approved for: '$NameFilter 
        Write-Host '------------------------------------------------------------------------------' 
        $RoleState  | Format-Table

    } While ($RoleState | Where-Object {  ($_.Status -like "Eligible" ) } )

    Write-Host '------------------------------------------------------------------------------' 
    Write-Host 'Start JITs for: '$NameFilter 
    Write-Host '------------------------------------------------------------------------------' 
    ActivateJit $NameFilter
}

AutomatePimJit $NameFilter $duration $reason $StartDT

