# Azure Landingzone Bicep notes

## Introduction

These are some personal notes during deployment of the Azure Landing Zone on my personal Azure tenant

## Prerequisite steps

1. Forked the [Azure/ALZ-Bicep](https://github.com/Azure/ALZ-Bicep) repo to my own repo [MarcoJanse/ALZ-Bicep](https://github.com/MarcoJanse/ALZ-Bicep).
2. Created a branch [ictstuff-landingzone-test](https://github.com/MarcoJanse/ALZ-Bicep/tree/ictstuff-landingzone-test).
3. In Azure, elevated my account in Azure AD.
4. Added myself as an owner on the root management group.
5. Wasn't working via the portal, so I did the following:

```powershell
Connect-AZAccount

$user = Get-AzADUser -UserPrincipalName (Get-AzContext).Account
New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id
```

6. After that, removed the elevation in Azure AD
7. Signed in again

## Steps

### Management Groups

1. Log in using `Connect-AzAccount`
2. Navigate to locally cloned git repo of (forked) ALZ-Bicep: `ALZ-Bicep\infra-as-code\bicep\modules\managementGroups`.
3. Open VScode here: `code .`.
4. Switch to the `ictstuff-landingzone-test`-branch.
5. Modify the `ALZ-Bicep\infra-as-code\bicep\modules\managementGroups\parameters\managementGroups.parameters.all.json`.
6. Update the parameters below with your own, for example:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "parTopLevelManagementGroupPrefix": {
      "value": "ictstuff"
    },
    "parTopLevelManagementGroupDisplayName": {
      "value": "ICTStuff"
    },
    "parTopLevelManagementGroupParentId": {
      "value": ""
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

7. Deploy the bicep file to create the management group structure.

```powershell
New-AzTenantDeployment -TemplateFile .\managementGroups.bicep -TemplateParameterFile .\parameters\managementGroups.parameters.all.json -Location westeurope -Verbose
```

### Policies

1. On your system, make sure you are in the root of the ALZ-Bicep git repo.
2. Open Code in this folder: `code .`.
3. Modify the parameter file `\infra-as-code\bicep\modules\policy\definitions\parameters\customPolicyDefinitions.parameters.all.json`.
   1. Change `parTargetManagementGroupId` value to `ICTStuff`.
4. Create the below variable that will make a hastable of al the cmdlet parameters and values:

```powershell
$inputObject = @{                                                                                                                                         ❮  1m 23s 303ms      
  DeploymentName        = 'ictstuff-PolicyDefsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'ictstuff'
  TemplateFile          = "infra-as-code/bicep/modules/policy/definitions/customPolicyDefinitions.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/policy/definitions/parameters/customPolicyDefinitions.parameters.all.json'
}
```

5. After that, run the `New-AzManagementGroupDeployment` using the created variable for all parameters

```powershell
New-AzManagementGroupDeployment @inputObject -Verbose
```

The `-Verbose` parameter in optional

### Custom Role Definitions

1. On your system, make sure you are in the root of the ALZ-Bicep git repo.
2. Open Code in this folder: `code .`.
3. Modify the parameter file `\infra-as-code\bicep\modules\customRoleDefinitions\parameters\customRoleDefinitions.parameters.all.json`.
   1. Change `parTargetManagementGroupId` value to `ICTStuff`.
4. Create the below variable that will make a hastable of al the cmdlet parameters and values:

```powershell
$inputObject = @{                                                                                                                               ❮  24s 926ms      
  DeploymentName        = 'alz-CustomRoleDefsDeployment-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location              = 'westeurope'
  ManagementGroupId     = 'ictstuff'
  TemplateFile          = "infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep"
  TemplateParameterFile = 'infra-as-code/bicep/modules/customRoleDefinitions/parameters/customRoleDefinitions.parameters.all.json'
}
```

5. After that, run the `New-AzManagementGroupDeployment` using the created variable for all parameters

### Logging, Automation and Sentinel

1. On your system, make sure you are in the root of the ALZ-Bicep git repo.
2. Open Code in this folder: `code .`
3. Modify the parameter file `\infra-as-code\bicep\modules\logging\parameters\logging.parameters.all.json`.
   1. Change `parLogAnalyticsWorkspaceName` value to `ictstuff-log-analytics`.
   2. Change `parLogAnalyticsWorkspaceLocation` value to `westeurope`.
   3. Change `parAutomationAccountLocation` value to `westeurope`.
4. Use the below scripts to define required parameters and create the necessary resource group:

```powershell
# For Azure Global regions
# Set Platform management subscripion ID as the the current subscription
$ManagementSubscriptionId = Get-AzSubscription -SubscriptionName 'Azure Subscription 1'| Select-Object -ExpandProperty Id

# Set the top level MG Prefix in accordance to your environment. This example assumes default 'alz'.
$TopLevelMGPrefix = "ictstuff"

# Parameters necessary for deployment
$inputObject = @{
  DeploymentName        = 'ictstuff-LoggingDeploy-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  ResourceGroupName     = "rg-$TopLevelMGPrefix-logging-001"
  TemplateFile          = "infra-as-code/bicep/modules/logging/logging.bicep"
  TemplateParameterFile = "infra-as-code/bicep/modules/logging/parameters/logging.parameters.all.json"
}
```

Once you have the variables defined, use the blocks below to create the required resource group and after that, deploy the logging Bicep module:

```powershell
Select-AzSubscription -SubscriptionId $ManagementSubscriptionId

# Create Resource Group - optional when using an existing resource group
New-AzResourceGroup `
  -Name $inputObject.ResourceGroupName `
  -Location westeurope
```

```powershell
New-AzResourceGroupDeployment @inputObject -Verbose
```

### Management Groups Diagnostic Settings

1. On your system, make sure you are in the root of the ALZ-Bicep git repo.
2. Open Code in this folder: `code .`
3. Modify the parameter file  `/infra-as-code\bicep\orchestration\mgDiagSettingsAll\parameters\mgDiagSettingsAll.parameters.all.json` 
   1. Change `parTopLevelManagementGroupPrefix` to `ictstuff`
   2. Change `parLogAnalyticsWorkspaceResourceId` to include your subscription ID. (HINT: get it with this cmdlet: 

```powershell
Get-AzSubscription -SubscriptionName 'Azure Subscription 1'| Select-Object -ExpandProperty Id
```

4. Next, create a hashtable with the parameters and deploy the bicep template.

```powershell

$inputObject = @{
  TemplateFile          = "infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep"
  TemplateParameterFile = "infra-as-code/bicep/orchestration/mgDiagSettingsAll/parameters/mgDiagSettingsAll.parameters.all.json"
  Location              = "westeurope"
  ManagementGroupId     = "ictstuff"
}

 New-AzManagementGroupDeployment @InputObject -Verbose
 ```