@description('the name of the storage account')
param storageAccountName string

@description('the sku name of the storage account')
param storageAccountSkuName string

@description('the name of the blob container')
param containerName string

@description('the name of the file share')
param fileServiceName string

@description('the name of the queue service')
param queueServiceName string

@description('the name of the table service')
param tableServiceName string

@description('The location of the resource')
param location string

@description('The tags that will be associated to the Resources')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccount.name}/default/${containerName}'
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: '${storageAccount.name}/default/${fileServiceName}'
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-08-01' = {
  name: '${storageAccount.name}/default/${queueServiceName}'
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-08-01' = {
  name: '${storageAccount.name}/default/${tableServiceName}'
}

// Store the storage account primary key to the key vault secret
param keyVaultName string
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

@description('the secret name in the key vault for the storage account primary key ')
param storageAccountPrimaryKeySecretName string
resource secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: storageAccountPrimaryKeySecretName
  parent: keyVault
  properties: {
    value: storageAccount.listKeys().keys[0].value
  }
}
