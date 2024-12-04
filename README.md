# Automate_Pim_and_Jit
2 powershell scripts that automate Azure PIM and JIT

This is my first attempt to write a Azure cloud shell script that will (based on a filter parameter) itereate through all your subscriptions, resource groups and VM's, start a PIM request, wait for all PIM's to be approved, start JIT's for all found VM's and report back with some extra info.

Simply open a coudshell on https://portal.azure.com/#home and paste the content of one of the ps1 files as plain text in the cloudshell. 

![image](https://github.com/user-attachments/assets/8bef3e8c-b52a-4969-a860-03cbdbb6607c)
* Note: the first time you open a cloudshell you need to choose for powershell

The nice thing is that the cloudshell pre-autenticates you, so the script can run immediately in the correct security context :)

And for the CiSo's allready whining in the background... this scipt can do nothing more then automate what a user can do via the portal gui.

------------------------------------------------------------------------------

Usage:
------------------------------------------------------------------------------

Open one of the PS1 files, copy all the text and paste it as plain text into the cloudshell

* Automate_PIM_and_JIT.ps1 does the PIM and the JIT
* Reactivate_JIT.ps1 is used after your JIT window expires, but the PIM is still valid.

------------------------------------------------------------------------------

An example of some of the output when connection to *aq* 

``` 
------------------------------------------------------------------------------
Wait until the PIM requests are approved for:  *aq*
------------------------------------------------------------------------------
 
PrincipalDisplayName ScopeDisplayName Status    ActivationStart     ActivationEnd       AssignmentType
-------------------- ---------------- ------    ---------------     -------------       --------------
RG-XXXAQ-t           aqxxx01-t-rg     Activated 2024-12-04 09:56:50 2024-12-04 17:56:48 Activated
RG-XXXAQ-a           aqxxx-a-rg       Activated 2024-12-04 09:56:51 2024-12-04 17:56:48 Activated
RG-XXXAQ-p           aqxxx-p-rg       Activated 2024-12-04 09:56:49 2024-12-04 17:56:48 Activated
RG-XXXAQ-d           aqxxx01-d-rg     Activated 2024-12-04 09:56:50 2024-12-04 17:56:49 Activated
RG-XXXAQ-d           aqxxx02-d-rg     Activated 2024-12-04 09:56:49 2024-12-04 17:56:48 Activated
 
------------------------------------------------------------------------------
Start JITs for:  *aq*
------------------------------------------------------------------------------
##############################################################################
Scanning all subscriptions/resourcegroups for VMs with JIT
##############################################################################
Gathering info for: <SubscriptionName> - <ResourceGroupName> - <VmName>
------------------------------------------------------------------------------
Gathering info for: xxxaq-a-lz - aqxxx-a-rg - aq01-a-jh-vm
Gathering info for: xxxaq-a-lz - aqxxx-a-rg - aq01-a-jh02-vm
Gathering info for: xxxaq-a-lz - aqxxx-a-rg - aq01-a-jh03-vm
Gathering info for: xxxaq-a-lz - aqxxx-a-rg - aq01-a-ssms-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aq03-d-aq-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aq03-d-ce-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aq03-d-jss-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aq03-d-sql03-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aq03-d-ssms-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aqrs1-d-ce-vm
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aqrs1-d-sqlEvm1
Gathering info for: xxxaq-d-lz - aqxxx01-d-rg - aqrs1-d-sqlEvm2
Gathering info for: xxxaq-d-lz - aqxxx02-d-rg - aq33-d-sql03-vm
Gathering info for: xxxaq-p-lz - aqxxx-p-rg - aq01-p-jh-vm
Gathering info for: xxxaq-p-lz - aqxxx-p-rg - aq01-p-jh02-vm
Gathering info for: xxxaq-p-lz - aqxxx-p-rg - aq01-p-jh03-vm
Gathering info for: xxxaq-p-lz - aqxxx-p-rg - aq01-p-ssms-vm
------------------------------------------------------------------------------
Requesting JIT access for: <SubscriptionName> - <VmName>
------------------------------------------------------------------------------
Requesting JIT access for: xxxaq-a-lz - aq01-a-jh-vm
Requesting JIT access for: xxxaq-a-lz - aq01-a-jh02-vm
Requesting JIT access for: xxxaq-a-lz - aq01-a-jh03-vm
Requesting JIT access for: xxxaq-a-lz - aq01-a-ssms-vm
Requesting JIT access for: xxxaq-d-lz - aq03-d-aq-vm
Requesting JIT access for: xxxaq-d-lz - aq03-d-ce-vm
Requesting JIT access for: xxxaq-d-lz - aq03-d-jss-vm
Requesting JIT access for: xxxaq-d-lz - aq03-d-sql03-vm
Requesting JIT access for: xxxaq-d-lz - aq03-d-ssms-vm
Requesting JIT access for: xxxaq-d-lz - aqrs1-d-ce-vm
Requesting JIT access for: xxxaq-d-lz - aqrs1-d-sqlEvm1
Requesting JIT access for: xxxaq-d-lz - aqrs1-d-sqlEvm2
Requesting JIT access for: xxxaq-d-lz - aq33-d-sql03-vm
Requesting JIT access for: xxxaq-p-lz - aq01-p-jh-vm
Requesting JIT access for: xxxaq-p-lz - aq01-p-jh02-vm
Requesting JIT access for: xxxaq-p-lz - aq01-p-jh03-vm
Requesting JIT access for: xxxaq-p-lz - aq01-p-ssms-vm
------------------------------------------------------------------------------
Done, result below
------------------------------------------------------------------------------
 Subscription ResourceGroup VMName          VmSize             VMStatus   AZ PrivateIP               JitName Duration Port Protocol Prefix     StartDT
------------ ------------- ------          ------             --------   -- ---------                ------- -------- ---- -------- ------     -------
xxxaq-a-lz   aqxxx-a-rg    aq01-a-jh-vm    Standard_D2s_v5    VM running    10.188.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:31:33
xxxaq-a-lz   aqxxx-a-rg    aq01-a-jh02-vm  Standard_D2s_v5    VM running    10.188.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:31:43
xxxaq-a-lz   aqxxx-a-rg    aq01-a-jh03-vm  Standard_D2s_v5    VM running    10.188.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:32:14
xxxaq-a-lz   aqxxx-a-rg    aq01-a-ssms-vm  Standard_D2s_v5    VM running    10.188.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:32:23
xxxaq-d-lz   aqxxx01-d-rg  aq03-d-aq-vm    Standard_DS14_v2   VM running    10.147.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:32:41
xxxaq-d-lz   aqxxx01-d-rg  aq03-d-ce-vm    Standard_D2s_v5    VM running    10.147.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:33:06
xxxaq-d-lz   aqxxx01-d-rg  aq03-d-jss-vm   Standard_D2s_v5    VM running    10.147.x.y              default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:33:38
xxxaq-d-lz   aqxxx01-d-rg  aq03-d-sql03-vm Standard_E8bds_v5  VM running    10.147.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:33:55
xxxaq-d-lz   aqxxx01-d-rg  aq03-d-ssms-vm  Standard_D2s_v5    VM running    10.147.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:34:11
xxxaq-d-lz   aqxxx01-d-rg  aqrs1-d-ce-vm   Standard_D2s_v5    VM running    10.147.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:34:28
xxxaq-d-lz   aqxxx01-d-rg  aqrs1-d-sqlEvm1 Standard_E32bds_v5 VM running 1  {10.147.x.y, 10.147.x.y} default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:34:31
xxxaq-d-lz   aqxxx01-d-rg  aqrs1-d-sqlEvm2 Standard_E32bds_v5 VM running 2  {10.147.x.y, 10.147.x.y} default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:34:48
xxxaq-d-lz   aqxxx02-d-rg  aq33-d-sql03-vm Standard_E8bds_v5  VM running    10.187.x.y               default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:35:19
xxxaq-p-lz   aqxxx-p-rg    aq01-p-jh-vm    Standard_D2s_v5    VM running    10.93.x.y                default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:35:47
xxxaq-p-lz   aqxxx-p-rg    aq01-p-jh02-vm  Standard_D2s_v5    VM running    10.93.x.y                default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:36:04
xxxaq-p-lz   aqxxx-p-rg    aq01-p-jh03-vm  Standard_D2s_v5    VM running    10.93.x.y                default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:36:20
xxxaq-p-lz   aqxxx-p-rg    aq01-p-ssms-vm  Standard_D2s_v5    VM running    10.93.x.y                default PT1H     3389 TCP      10.0.0.0/8 2024-12-04 14:36:26

```
