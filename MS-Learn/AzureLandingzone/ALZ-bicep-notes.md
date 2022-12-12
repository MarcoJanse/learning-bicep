# Azure Landingzone Bicep notes

## Introduction

These are some personal notes during deployment of the Azure Landing Zone on my personal Azure tenant

## Prerequisite steps

1. Forked the [Azure/ALZ-Bicep](https://github.com/Azure/ALZ-Bicep) repo to my own repo [MarcoJanse/ALZ-Bicep](https://github.com/MarcoJanse/ALZ-Bicep)
2. Created a branch [ictstuff-landingzone-test](https://github.com/MarcoJanse/ALZ-Bicep/tree/ictstuff-landingzone-test)
3. In Azure, elevated my account in Azure AD
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
2. Navigate to locally cloned git repo of (forked) ALZ-Bicep: `ALZ-Bicep\infra-as-code\bicep\modules\managementGroups`
3. Open VScode here: `code .`
4. Switch to the `ictstuff-landingzone-test`-branch
5. Modify the `ALZ-Bicep\infra-as-code\bicep\modules\managementGroups\parameters\managementGroups.parameters.all.json`
6. Update the parameters below with your own, for example

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

