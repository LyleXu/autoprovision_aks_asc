@description('the name of the key vault')
param keyVaultName string

@description('The location of the resource')
param location string

@description('The tags that will be associated to the Resources')
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForTemplateDeployment: true
  }
}

output vaultUri string = keyVault.properties.vaultUri
