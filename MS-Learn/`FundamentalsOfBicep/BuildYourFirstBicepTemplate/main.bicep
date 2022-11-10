resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: 'mcjbiceptoylaunchstorage'
  location: 'westeurope'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource appServicePlan 'Microsoft.Web/serverFarms@2022-03-01' = {
  name: 'toy-product-launch-plan-starter'
  location: 'westeurope'
  sku: {
    name: 'F1'
  }
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'mjcbicep-toy-product-launch-1'
  location: 'westeurope'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}
