# Bicep notes

## To try

- Export resource definitions and convert to Bicep
- Try the insert resource command in VSCode

## What-If

### What-If parameters

#### WhatIfResultFormat

You can control the amount of text output of the what-if operation by using one of these result formats:

- **FullResourcePayloads**. By including this parameter, you get a verbose output that consists of a list of resources that will change. The output also shows details about all the properties that will change in accordance with the template.
- **ResourceIdOnly**. This mode returns a list of resources that will change, but not all the details.

#### WhatIfExcludeChangeType

You can then exclude these types:

- Create
- Delete
- Ignore
- NoChange
- Modify
- Deploy

### Use what-if results in a script

You might want to use the output from the what-if operation within a script or as part of an automated deployment process.

You can get the results by using the `Get-AzResourceGroupDeploymentWhatIfResult` cmdlet. Then, your script can parse the results and perform any custom logic you might need.

