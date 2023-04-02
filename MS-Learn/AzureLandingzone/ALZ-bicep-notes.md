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

- Log in using `Connect-AzAccount`
- Make sure a subscription is selected that's part of the correct Azure tenant.
  - You can use `Get-AzContext` to view that
    - If not, use the following to set the right subscription:

```powershell
Set-AzContext -Subscription (Get-AzSubscription | Where-Object Name -match '<unique part of subscription name>').Id
```

- Create the below variable that will make a hashtable of al the cmdlet parameters and values:

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
New-AzTenantDeployment @inputObject -WhatIf
```

> WhatIf is recommended to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

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
New-AzManagementGroupDeployment @inputObject -WhatIf
```

> WhatIf is recommended to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

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
New-AzManagementGroupDeployment @inputObject -WhatIf
```

> WhatIf is recommended to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

> The `-Verbose` parameter is optional

### Logging, Automation and Sentinel

> Please make sure you know which subscription you want to deploy your resources under.

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Copy the parameter file `\infra-as-code\bicep\modules\logging\parameters\logging.parameters.all.json` and rename it.
  - In my case, I named it `\infra-as-code\bicep\modules\logging\parameters\logging.parameters.ictstuff.json`
  - [Optional]: Change `parLogAnalyticsWorkspaceName` value if you want.
  - Change `parLogAnalyticsWorkspaceLocation` value to `westeurope`.
  - Change `parAutomationAccountLocation` value to `westeurope`.
  - [Optional]: Change `parAutomationAccountName` value if you want
  - Under `parTags`, change the `Environment` to your desired value. (I used Shared)
- Use the below scripts to define required parameters and create the necessary resource group:

```powershell
# Set the top level MG Prefix in accordance to your environment.
$TopLevelMGPrefix = "alz"

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'ictstuff-LoggingDeploy-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = "rg-logging-shared-001"
  TemplateFile          = "infra-as-code/bicep/modules/logging/logging.bicep"
  TemplateParameterFile = "infra-as-code/bicep/modules/logging/parameters/logging.parameters.ictstuff.json"
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
New-AzResourceGroupDeployment @inputObject -WhatIf
```

> WhatIf is recommended to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

### Management Groups Diagnostic Settings

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Copy the parameter file  `/infra-as-code\bicep\orchestration\mgDiagSettingsAll\parameters\mgDiagSettingsAll.parameters.all.json` and rename it.
  - In my case, I named it `/infra-as-code\bicep\orchestration\mgDiagSettingsAll\parameters\mgDiagSettingsAll.parameters.ictstuff.json`
  - [optional] Change `parTopLevelManagementGroupPrefix` to your desired value
  - [optional] Change `parTopLevelManagementGroupSuffix` to your desired value.
    - I used `-mg` here
  - Change `parLogAnalyticsWorkspaceResourceId` to include your subscription ID, the resourcegroup that holds the log analytics workspace and the log analytics workspace name.
  **HINT:** get the subscription ID with this cmdlet:

```powershell
Get-AzSubscription | Where-Object { $_.Name -match '<unique part of subscription name>' } | Select-Object -ExpandProperty Id
```

- Next, create a hashtable with the parameters and deploy the bicep template.

```powershell
$inputObject = @{
  TemplateFile          = "infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep"
  TemplateParameterFile = "infra-as-code/bicep/orchestration/mgDiagSettingsAll/parameters/mgDiagSettingsAll.parameters.ictstuff.json"
  Location              = "westeurope"
  ManagementGroupId     = "alz-mg"
}
```

Deploy the Diagnostics settings bicep template using the command below:

```powershell
 New-AzManagementGroupDeployment @InputObject -WhatIf
 ```

 > WhatIf is recommended to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

### Hub networking

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Copy the parameters file `infra-as-code\bicep\modules\hubNetworking\parameters\hubNetworking.parameters.all.json` and rename it
  - I used `infra-as-code\bicep\modules\hubNetworking\parameters\hubNetworking.parameters.ictstuff.json` and edited the following values:
    - `parLocation`
    - `parHubNetworkName`
    - `parHubNetworkAddressPrefix`
      - I used `172.20.0.0/16` and created the following `parSubnets`

```json
"parSubnets": {
      "value": [
        {
          "name": "AzureBastionSubnet",
          "ipAddressRange": "172.20.0.0/24"
        },
        {
          "name": "ManagementSubnet",
          "ipAddressRange": "172.20.1.0/24"
        },
        {
          "name": "GatewaySubnet",
          "ipAddressRange": "172.20.254.0/24"
        },
        {
          "name": "AzureFirewallSubnet",
          "ipAddressRange": "10.20.255.0/24"
        }
      ]
    },
```

> Please note that you cannot rename the `AzureBastionSubnet`. This name is mandatory

- Continue with the rest of the `hubNetworking.parameters.ictstuff.json` file
  - After the `parSubnets, verify or change these values:
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

Next, create a hash table of all parameters to deploy the hub networking bicep template

```powershell
# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'ictstuff-HubNetworkingDeploy-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = "rg-hubnetworking-shared-001"
  TemplateFile          = "infra-as-code/bicep/modules/hubNetworking/hubNetworking.bicep"
  TemplateParameterFile = "infra-as-code/bicep/modules/hubNetworking/parameters/hubNetworking.parameters.ictstuff.json"
}
```

- Now, create the Azure resource group to hold all resources in the region you prefer

```powershell
New-AzResourceGroup `
  -Name $inputObject.ResourceGroupName `
  -Location 'westeurope'
```

- Finally, deploy the resources in the bicep file using the variables and the `inputobject` you created.

```powershell
New-AzResourceGroupDeployment @inputObject -WhatIf
```

> WhatIf is recommended parameter to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

### Role Assignments for Management Groups and Subscriptions

> The example below is to assign a Readers role to a security group: **sg-ictstuff-readers**

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Copy the bicep file `infra-as-code\bicep\modules\roleAssignments\parameters\roleAssignmentManagementGroup.securityGroup.parameters.all.json` and rename it.
  - In mÿ case, I renamed it to `infra-as-code\bicep\modules\roleAssignments\parameters\roleAssignmentManagementGroup.securityGroup.parameters.ictstuff.json`
    - Remove the `parRoleAssignmentNameGuid` code block. This is optional and will be constructed by the `roleAssignmentResourceGroup.bicep`-file.
    - `parRoleDefinitionId` with the GUID of the (built-in) role definition. See [Azure built-in roles | MS-Learn](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles). For example, the built-in Reader role has the following GUID: `acdd72a7-3385-48ef-bd42-f606fba81ae7`
    - `parAssigneeObjectId` with the objectID of your security group. In my example, I use `sg-ictstuff-readers`. (But I won't display the GUID here...)
- Making sure you are logged in to Azure with the Az PowerShell module, create the `inputobject` below:

```powershell
$inputObject = @{
  DeploymentName        = 'ictstuff-RoleAssignmentsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'alz-mg'
  TemplateFile          = "infra-as-code/bicep/modules/roleAssignments/roleAssignmentManagementGroup.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/roleAssignments/parameters/roleAssignmentManagementGroup.securityGroup.parameters.ictstuff.json'
}
```

Next, create the role assignment:

```powershell
New-AzManagementGroupDeployment @inputObject -WhatIf
```

### Subscription Placement

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Copy the bicep file `infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json` and rename it.
  - In mÿ case, I renamed it to `infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.ictstuff.json`
  - Review/change the following parameters
    - `parTopLevelManagementGroupPrefix`
      - I kept mine set to `alz`
    - `parTopLevelManagementGroupSuffix`
      - Changed this to `-mg`
    - Next, I added my subscription ID's under the following management groups:
      - `parIntRootMgSubs`
      - `parDecommissionedMgSubs`
- Making sure you are logged in to Azure with the Az PowerShell module, create the `inputobject` below:

```powershell
$inputObject = @{
  DeploymentName        = 'ictstuff-SubPlacementAll-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'alz-mg'
  TemplateFile          = "infra-as-code/bicep/orchestration/subPlacementAll/subPlacementAll.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/orchestration/subPlacementAll/parameters/subPlacementAll.parameters.ictstuff.json'
}
```

```powershell
New-AzManagementGroupDeployment @inputObject -WhatIf
```

> WhatIf is recommended to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along.

### Built-in and Custom Policy assignments

- On your system, make sure you are in the root of the ALZ-Bicep git repo.
- Open Code in this folder: `code .`
- Copy the bicep file `infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json` and rename it.
  - In mÿ case, I renamed it to `infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.ictstuff.json`

```powershell
$inputObject = @{
  DeploymentName        = 'alz-alzPolicyAssignmentDefaultsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'alz-mg'
  TemplateFile          = "infra-as-code/bicep/modules/policy/assignments/alzDefaults/alzDefaultPolicyAssignments.ictstuff.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/policy/assignments/alzDefaults/parameters/alzDefaultPolicyAssignments.parameters.ictstuff.json'
}
```

Verify the deployment

```powershell
New-AzManagementGroupDeployment @inputObject -WhatIf
```

> WhatIf is recommended parameter to run first, and you could replace `-WhatIf` with `-Verbose` to follow the deployment along when everything looks good.

### Spoke Networking

> Not required at the moment
