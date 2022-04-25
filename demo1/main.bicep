@description('The alias of the application')
param appAlias string = 'app1'

@description('The location that the resource will be provisioned. Default is the current resource group')
param location string = resourceGroup().location

@description('Environment. That will decide the resource details like size, capacity etc')
@allowed([
  'SD'
  'QA'
  'TR'
  'VE'
  'OL'
  'BK'
  'DR'
])
param environment string = 'SD'

@description('Tags that need to attach to the resource. Define the addtinal key value if required')
param tags object = {
    Environment: 'SD'
    CostCenter: '1001201'
    Ower: 'Mike'
}

/*-----------------------------------------------Virtual Network---------------------------------------------------------*/
@description('The name of the Virtual Network')
param vnetName string = '${appAlias}vnet${toLower(environment)}${uniqueString(location)}'

@description('the app subnet name of the Azure Spring Cloud')
param ascAppSubnetName string = 'ascAppSubnet'

@description('the runtime subnet name of the Azure Spring Cloud')
param ascRuntimeSubnetName string = 'ascRuntimeSubnet'

@description('The bastion subnet name in the vnet')
param bastionSubnetName string = 'AzureBastionSubnet'

@description('The virtual machine subnet name in the vnet')
param vmSubnetName string = 'vmSubnet'

@description('The address prefixes of the vnet')
param vnetAddressPrefixes string = '10.4.0.0/16'

@description('The Azure Spring Cloud App subnet address prefixes in the vnet')
param ascAppSubnetAddressPrefixes string = '10.4.0.0/24'

@description('The Azure Spring Cloud Runtime subnet address prefixes in the vnet')
param ascRuntimeSubnetAddressPrefixes string = '10.4.1.0/24'

@description('The bastion subnet address prefixes in the vnet')
param bastionSubnetAddressPrefixes string = '10.4.2.0/26'

@description('The virtual machine subnet address prefixes in the vnet')
param vmSubnetAddressPrefixes string = '10.4.3.0/24'

module virtualNetwork 'modules/vnet.bicep' = {
  name: vnetName
  params:{
    location: location
    ascAppSubnetName: ascAppSubnetName
    ascRuntimeSubnetName: ascRuntimeSubnetName
    vnetName: vnetName
    vnetAddressPrefixes: vnetAddressPrefixes
    ascAppSubnetAddressPrefixes: ascAppSubnetAddressPrefixes
    ascRuntimeSubnetAddressPrefixes: ascRuntimeSubnetAddressPrefixes
    bastionSubnetAddressPrefixes: bastionSubnetAddressPrefixes
    bastionSubnetName: bastionSubnetName
    vmSubnetAddressPrefixes: vmSubnetAddressPrefixes
    vmSubnetName: vmSubnetName
    tags: tags

  }
}

/*-----------------------------------------------------------Key vault---------------------------------------------------------*/
@description('the name of the key vault')
param keyVaultName string = '${appAlias}kv${toLower(environment)}${uniqueString(location)}'

module keyVault 'modules/keyVault.bicep' = {
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
  }
}

/*-----------------------------------------------------------Storage Account---------------------------------------------------------*/
@description('the name of the storage account')
param storageAccountName string = take('${appAlias}sa${toLower(environment)}${uniqueString(location)}', 24)

@description('the name of the blob container')
param containerName string = 'container1'

@description('the name of the file share')
param fileServiceName string = 'fileshare1'

@description('the name of the queue service')
param queueServiceName string = 'queueservice1'

@description('the name of the table service')
param tableServiceName string = 'tableservice1'

@description('the secret name in the key vault for the storage account primary key ')
param storageAccountPrimaryKeySecretName string = 'storage-account-primary-key'

var storageAccountSkuName = (environment == 'OL' || environment == 'BK') ? 'Standard_GRS' : 'Standard_LRS'

module storageAccount 'modules/storageAccount.bicep' = {
  name: storageAccountName
  dependsOn: [
    keyVault
  ]
  params:{
    location: location
    tags: tags
    storageAccountName: storageAccountName
    storageAccountSkuName: storageAccountSkuName
    containerName: containerName
    fileServiceName: fileServiceName
    queueServiceName: queueServiceName
    tableServiceName: tableServiceName
    storageAccountPrimaryKeySecretName: storageAccountPrimaryKeySecretName
    keyVaultName: keyVaultName
  }
}

/*-----------------------------------------------------------Azure Spring Cloud---------------------------------------------------------*/
@description('The name of Azure Spring Cloud')
param springCloudInstanceName string = '${appAlias}asc${toLower(environment)}${uniqueString(location)}'

@description('The name of the Application Insights instance for Azure Spring Cloud')
param appInsightsName string = '${appAlias}ai${toLower(environment)}${uniqueString(location)}'

@description('Comma-separated list of IP address ranges in CIDR format. The IP ranges are reserved to host underlying Azure Spring Cloud infrastructure, which should be 3 at least /16 unused IP ranges, must not overlap with any Subnet IP ranges')
param springCloudServiceCidrs string = '10.1.0.0/16,10.2.0.0/16,10.3.0.1/16'

@description('The name of log analytics that Azure Spring Cloud will use')
param logAnalyticsWorkspaceName string = '${appAlias}la${toLower(environment)}${uniqueString(location)}'

module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace.bicep' = {
  name: logAnalyticsWorkspaceName
  params:{
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    tags: tags
  }
}

module springCloudInstance 'modules/azureSpringCloud.bicep' = {
  name: springCloudInstanceName
  dependsOn: [
    virtualNetwork
    logAnalyticsWorkspace
  ]
  params: {
    appInsightsName: appInsightsName
    laWorkspaceResourceId: logAnalyticsWorkspace.outputs.id
    location: location
    springCloudAppSubnetID: virtualNetwork.outputs.ascAppSubnetId
    springCloudInstanceName: springCloudInstanceName
    springCloudRuntimeSubnetID: virtualNetwork.outputs.ascRuntimeSubetId
    springCloudServiceCidrs: springCloudServiceCidrs
    tags: tags
  }
}

/*-----------------------------------------------------------AKS Cluster ---------------------------------------------------------*/
@description('The name of the Managed Cluster resource.')
param clusterName string = '${appAlias}aks${toLower(environment)}${uniqueString(location)}'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string = 'dev1'

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = appAlias

module aksCluster 'modules/aks.bicep' = {
  name: clusterName
  params: {
    location: location
    sshRSAPublicKey: sshRSAPublicKey
    linuxAdminUsername: linuxAdminUsername
    dnsPrefix: dnsPrefix
    clusterName: clusterName
    tags: tags
  }
}

output controlPlaneFQDN string = aksCluster.outputs.controlPlaneFQDN

/*-----------------------------------------------------------Virtual Machine ---------------------------------------------------------*/
@description('The name of you Virtual Machine.')
param vmName string = '${appAlias}vm1${toLower(environment)}${uniqueString(location)}'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The name of the Bastion host')
param bastionHostName string = '${appAlias}bastion${toLower(environment)}${uniqueString(location)}'

@description('The name of the Bastion public IP address')
param publicIpName string = '${appAlias}bastion${toLower(environment)}${uniqueString(location)}'

module vm 'modules/vm.bicep' = {
  name: vmName
  dependsOn: [
    virtualNetwork
  ]
  params: {
    location: location
    tags: tags
    vmName: vmName
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    bastionSubnetId: virtualNetwork.outputs.bastionSubnetId
    vmSubnetId: virtualNetwork.outputs.vmSubnetId
    bastionHostName: bastionHostName
    publicIpName: publicIpName
  }
}
