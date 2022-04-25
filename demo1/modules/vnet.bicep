@description('The name of the Virtual Network')
param vnetName string

@description('the app subnet name of the Azure Spring Cloud')
param ascAppSubnetName string

@description('the runtime subnet name of the Azure Spring Cloud')
param ascRuntimeSubnetName string

@description('The bastion subnet name in the vnet')
param bastionSubnetName string

@description('The virtual machine subnet name in the vnet')
param vmSubnetName string

@description('The address prefixes of the vnet')
param vnetAddressPrefixes string 

@description('The Azure Spring Cloud App subnet address prefixes in the vnet')
param ascAppSubnetAddressPrefixes string

@description('The Azure Spring Cloud Runtime subnet address prefixes in the vnet')
param ascRuntimeSubnetAddressPrefixes string

@description('The bastion subnet address prefixes in the vnet')
param bastionSubnetAddressPrefixes string

@description('The virtual machine subnet address prefixes in the vnet')
param vmSubnetAddressPrefixes string

@description('The location of the resource')
param location string

@description('The tags that will be associated to the Resources')
param tags object

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefixes
      ]
    }
    subnets: [
      {
        name: ascAppSubnetName
        properties: {
          addressPrefix: ascAppSubnetAddressPrefixes
        }
      }
      {
        name: ascRuntimeSubnetName
        properties: {
          addressPrefix: ascRuntimeSubnetAddressPrefixes
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefixes
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefixes
        }
      }
    ]
  }

  resource ascAppSubnet 'subnets' existing = {
    name: ascAppSubnetName
  }

  resource ascRuntimeSubnet 'subnets' existing = {
    name: ascRuntimeSubnetName
  }

  resource bastionSubnet 'subnets' existing = {
    name: bastionSubnetName
  }

  resource vmSubnet 'subnets' existing = {
    name: vmSubnetName
  }
  
  tags: tags
}

//Grant the access for the vnet to Azure Spring Cloud
resource ascRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id)
  scope: virtualNetwork
  properties: {
    principalId: 'd2531223-68f9-459e-b225-5592f90d145e'
    roleDefinitionId: '/subscriptions/50144203-25d7-4aa0-8c7b-3e0d936b07f0/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Grant Owner permission
  }
}

output ascAppSubnetId string = virtualNetwork::ascAppSubnet.id
output ascRuntimeSubetId string = virtualNetwork::ascRuntimeSubnet.id
output bastionSubnetId string = virtualNetwork::bastionSubnet.id
output vmSubnetId string = virtualNetwork::vmSubnet.id
