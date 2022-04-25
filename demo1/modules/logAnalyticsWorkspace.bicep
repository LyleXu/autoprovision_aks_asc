param logAnalyticsWorkspaceName string

@description('The location of the resource')
param location string

@description('The tags that will be associated to the Resources')
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

output id string = logAnalyticsWorkspace.id
