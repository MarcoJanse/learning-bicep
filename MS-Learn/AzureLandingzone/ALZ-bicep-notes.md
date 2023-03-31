# Azure Landingzone Bicep notes

- [Azure Landingzone Bicep notes](#azure-landingzone-bicep-notes)
  - [Introduction](#introduction)
  - [Prerequisite steps](#prerequisite-steps)
  - [Steps](#steps)
    - [Management Groups](#management-groups)
    - [Policies](#policies)
    - [Custom Role Definitions](#custom-role-definitions)
    - [Logging, Automation and Sentinel](#logging-automation-and-sentinel)
    - [Management Groups Diagnostic Settings](#management-groups-diagnostic-settings)
    - [Hub networking](#hub-networking)
    - [Role Assignments for Management Groups and Subscriptions](#role-assignments-for-management-groups-and-subscriptions)
    - [Subscription Placement](#subscription-placement)
    - [Built-in and Custom Policy assignments](#built-in-and-custom-policy-assignments)
      - [Issues](#issues)
        - [Update 25/03/2023](#update-25032023)
    - [Spoke Networking](#spoke-networking)

## Introduction

These are some personal notes during deployment of the Azure Landing Zone on my personal Azure tenant

## Prerequisite steps

- Forked the [Azure/ALZ-Bicep](https://github.com/Azure/ALZ-Bicep) repo to my own repo [MarcoJanse/ALZ-Bicep](https://github.com/MarcoJanse/ALZ-Bicep).
- Created a branch [ictstuff-landingzone-test](https://github.com/MarcoJanse/ALZ-Bicep/tree/ictstuff-landingzone-test).
- In Azure, elevated my account in Azure AD.
- Added myself as an owner on the root management group.
- Wasn't working via the portal, so I did the following:

```powershell
Connect-AZAccount

$user = Get-AzADUser -UserPrincipalName (Get-AzContext).Account
New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id
```

- After that, removed the elevation in Azure AD
- Signed in again

## Steps

### Management Groups

- Log in using `Connect-AzAccount`
- Navigate to locally cloned git repo of (forked) ALZ-Bicep: `ALZ-Bicep`.
- Open VScode here: `code .`.
- Switch to the `ictstuff-landingzone`-branch.
- Copy the `ALZ-Bicep\infra-as-code\bicep\modules\managementGroups\parameters\managementGroups.parameters.all.json` and rename it.
  - This way, you can keep syncing with the upstream branch and not run into any merge conflicts when the original files get updated.
  - In my case I named it `ALZ-Bicep\infra-as-code\bicep\modules\managementGroups\parameters\managementGroups.parameters.ictstuff.json`.
- Update the parameters below with your own, for example:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "parTopLevelManagementGroupPrefix": {
      "value": "alz"
    },
    "parTopLevelManagementGroupDisplayName": {
      "value": "Azure Landing Zones"
    },
    "parTopLevelManagementGroupParentId": {
      "value": "-mg"
    },
    "parLandingZoneMgAlzDefaultsEnable": {
      "value": true
    },
    "parLandingZoneMgConfidentialEnable": {
      "value": false
    },
    "parLandingZoneMgChildren": {
      "value": {}
    },
    "parTelemetryOptOut": {
      "value": false
    }
  }
}
```

- Create the below variable that will make a hastable of al the cmdlet parameters and values:

```powershell
$inputObject = @{
  DeploymentName          = 'ictstuff-ManagementGroupsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location                = 'westeurope'
  TemplateFile            = 'infra-as-code\bicep\modules\managementGroups\managementGroups.bicep'
  TemplateParameterFile  = 'infra-as-code\bicep\modules\managementGroups\parameters\managementGroups.parameters.ictstuff.json'
}
```

- Deploy the bicep file using the hash of the parameters to create the management group structure.

```powershell
New-AzTenantDeployment @inputObject -Verbose
```

### Policies

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`.
- Copy the parameter file `\infra-as-code\bicep\modules\policy\definitions\parameters\customPolicyDefinitions.parameters.all.json` and rename it.
  - In my case, I named it `\infra-as-code\bicep\modules\policy\definitions\parameters\customPolicyDefinitions.parameters.ictstuff.json`
  - Change `parTargetManagementGroupId` value to to match your `parTopLevelManagementGroupPrefix` from the [Management group deployment](#management-groups).
    - Don't forget the suffix if you have added one.
- Create the below variable that will make a hash table of al the cmdlet parameters and values:

```powershell
$inputObject = @{
  DeploymentName        = 'ictstuff-PolicyDefsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'alz-mg'
  TemplateFile          = "infra-as-code/bicep/modules/policy/definitions/customPolicyDefinitions.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/policy/definitions/parameters/customPolicyDefinitions.parameters.ictstuff.json'
}
```

- After that, run the `New-AzManagementGroupDeployment` using the created variable for all parameters

```powershell
New-AzManagementGroupDeployment @inputObject -Verbose
```

> The `-Verbose` parameter is optional

### Custom Role Definitions

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`.
- Copy the parameter file `\infra-as-code\bicep\modules\customRoleDefinitions\parameters\customRoleDefinitions.parameters.all.json` and rename it.
  - In my case, I named it `\infra-as-code\bicep\modules\customRoleDefinitions\parameters\customRoleDefinitions.parameters.ictstuff.json`
  - Change `parTargetManagementGroupId` value to to match your `parTopLevelManagementGroupPrefix` from the [Management group deployment](#management-groups).
    - Don't forget the suffix if you have added one.
- Create the below variable that will make a hash table of al the cmdlet parameters and values:

```powershell
$inputObject = @{
  DeploymentName        = 'ictstuff-CustomRoleDefsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'alz-mg'
  TemplateFile          = "infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/customRoleDefinitions/parameters/customRoleDefinitions.parameters.ictstuff.json'
}
```

- After that, run the `New-AzManagementGroupDeployment` using the created variable for all parameters

```powershell
New-AzManagementGroupDeployment @inputObject -Verbose
```

> The `-Verbose` parameter is optional

### Logging, Automation and Sentinel

> Please make sure you know which subscription you want to deploy your resources under.

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Modify the parameter file `\infra-as-code\bicep\modules\logging\parameters\logging.parameters.all.json`.
  - Change `parLogAnalyticsWorkspaceName` value to `ictstuff-log-analytics`.
  - Change `parLogAnalyticsWorkspaceLocation` value to `westeurope`.
  - Change `parAutomationAccountLocation` value to `westeurope`.
- Use the below scripts to define required parameters and create the necessary resource group:

```powershell
# Set the top level MG Prefix in accordance to your environment.
$TopLevelMGPrefix = "ictstuff"

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'ictstuff-LoggingDeploy-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = "rg-logging-shared-weu-001"
  TemplateFile          = "infra-as-code/bicep/modules/logging/logging.bicep"
  TemplateParameterFile = "infra-as-code/bicep/modules/logging/parameters/logging.parameters.all.json"
}
```

- Once you have the variables defined, use the blocks below to create the required resource group and after that, deploy the logging Bicep module:

```powershell
Select-AzSubscription -SubscriptionId $ManagementSubscriptionId

# Create Resource Group - optional when using an existing resource group
New-AzResourceGroup `
  -Name $inputObject.ResourceGroupName `
  -Location westeurope
```

- Deploy the Logging bicep module using the command below:

```powershell
New-AzResourceGroupDeployment @inputObject -Verbose
```

### Management Groups Diagnostic Settings

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Modify the parameter file  `/infra-as-code\bicep\orchestration\mgDiagSettingsAll\parameters\mgDiagSettingsAll.parameters.all.json` 
  - Change `parTopLevelManagementGroupPrefix` to `ictstuff`
  - Change `parLogAnalyticsWorkspaceResourceId` to include your subscription ID, the resourcegroup that holds the log analytics workspace and the log analytics workspace name. (HINT: get the subscription ID with this cmdlet:

```powershell
Get-AzSubscription | Where-Object { $_.Name -match 'Marco-3fifty-02' } | Select-Object -ExpandProperty Id
Select-AzSubscription -SubscriptionId $ManagementSubscriptionId
```

- Next, create a hashtable with the parameters and deploy the bicep template.

```powershell
$inputObject = @{
  TemplateFile          = "infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep"
  Location              = "westeurope"
  ManagementGroupId     = "ictstuff"
}
```

Deploy the Diagnostics settings bicep template using the command below:

```powershell
 New-AzManagementGroupDeployment @InputObject -Verbose
 ```

### Hub networking

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Modify the bicep file `infra-as-code\bicep\modules\hubNetworking\hubNetworking.bicep` with the following changes:
  - `param parDdosEnabled bool = false` Unless you want to drain your subscription budget very quickly
- Modify the parameters file `infra-as-code\bicep\modules\hubNetworking\parameters\hubNetworking.parameters.all.json` with your own values
  - `parLocation`
  - `parHubNetworkName`
  - `parAzBastionName`
  - `parDdosPlanName`
  - `parAzFirewallName`
  - `parAzFirewallPoliciesName`
  - `parHubRouteTableName`
  - `parPrivateDnsZones`
    - `privatelink.westeurope.azmk8s.io`
    - `privatelink.westeurope.batch.azure.com`
    - `privatelink.westeurope.kusto.windows.net`
    - `privatelink.we.backup.windowsazure.com`
- Do not deploy an VPN gateway and ExpressRoute by removing all parameters inside the following arrays. (make them empty):
  - `parVpnGatewayConfig`
  - `parExpressRouteGatewayConfig`

After that, first select the right subscription. You might have a separate subscription for connectivity/networking, but I will use the Visual Studio MPN subscription

```powershell
# Commented the code below out as I currently only have one Visual Studio subscription again. :(
#
# Set Platform connectivity subscription ID as the the current subscription
# $ConnectivitySubscriptionId = Get-AzSubscription | Where-Object { $_.Name -match 'Marco-3fifty-02' } | Select-Object -ExpandProperty Id

# Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
```

Next, create a hastable of all parameters to deploy the hub networking bicep template

```powershell
# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'ictstuff-HubNetworkingDeploy-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = "rg-hubnetworking-shared-weu-001"
  TemplateFile          = "infra-as-code/bicep/modules/hubNetworking/hubNetworking.bicep"
  TemplateParameterFile = "infra-as-code/bicep/modules/hubNetworking/parameters/hubNetworking.parameters.all.json"
}
```

- Now, create the Azure resource group to hold all resources in the region you prefer

```powershell
New-AzResourceGroup `
  -Name $inputObject.ResourceGroupName `
  -Location 'westeurope'
```

- Finally, deploy the resources in the bicep file using the variables and the inputobject you created.

```powershell
New-AzResourceGroupDeployment @inputObject -Verbose
```

> Verbose is optional, and it's recommended to do a `-WhatIf` first to validate your code and expected outcome.

### Role Assignments for Management Groups and Subscriptions

> The example below is to assign a Readers role to a security group: **sg-ictstuff-readers**

1. On your system, make sure you are in the root of the ALZ-Bicep git repo.
2. Open Code in this folder: `code .`
3. Modify the bicep file `infra-as-code\bicep\modules\roleAssignments\parameters\roleAssignmentManagementGroup.securityGroup.parameters.all.json` with the following changes:
   1. Remove the `parRoleAssignmentNameGuid` code block. This is optional and will be constructed by the `roleAssignmentResourceGroup.bicep`-file.
   2. `parRoleDefinitionId` with the GUID of the (built-in) role definition. See [Azure built-in roles | MS-Learn](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles). For example, the built-in Reader role has the following GUID: `acdd72a7-3385-48ef-bd42-f606fba81ae7`
   3. `parAssigneeObjectId` with the objectID of your security group. In my example, I use `sg-ictstuff-readers`. (But I won't display the GUID here...)
4. Making sure you are logged in to Azure with the Az PowerShell module, create the inputobject below:

```powershell
$inputObject = @{
  DeploymentName        = 'alz-RoleAssignmentsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'ictstuff'
  TemplateFile          = "infra-as-code/bicep/modules/roleAssignments/roleAssignmentManagementGroup.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/roleAssignments/parameters/roleAssignmentManagementGroup.securityGroup.parameters.all.json'
}
```

Next, create the role assignment:

```powershell
New-AzManagementGroupDeployment @inputObject
```

### Subscription Placement

> Skipped this one for now

### Built-in and Custom Policy assignments

```powershell
$inputObject = @{
  DeploymentName        = 'alz-alzPolicyAssignmentDefaultsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'ictstuff'
  TemplateFile          = "infra-as-code/bicep/modules/policy/assignments/alzDefaults/alzDefaultPolicyAssignments.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/policy/assignments/alzDefaults/parameters/alzDefaultPolicyAssignments.parameters.all.json'
}
```

Deploy whenever you're ready and add `-Verbose` or `-WhatIf` as you like

```powershell
New-AzManagementGroupDeployment @inputObject
```

#### Issues

Currently getting lots of issues with deployment of this:

```powershell
New-AzManagementGroupDeployment: Deployment 'ALZBicep-polAssi-denyPrivEscAKS-lz-westeurope-5co7pqsca4y44' could not be found.
StatusCode: 404
ReasonPhrase: Not Found
OperationID : ffbddf6b-adbb-43ef-8761-37e419049690

New-AzManagementGroupDeployment: A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond. (management.azure.com:443)
```

##### Update 25/03/2023

This seems to be resolved with `Az.Accounts` module version `2.11.2`. See [Disconnect-AzAccount AccountNotFound error #20871 | GitHub.com](https://github.com/Azure/azure-powershell/issues/20871)

### Spoke Networking

> Not required at the moment
