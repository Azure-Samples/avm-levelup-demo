@description('Optional. The location to deploy resources to.')
param location string

@maxLength(7)
@description('Optional. Unique identifier for the deployment. Will appear in resource names. Must be 7 characters or less.')
param identifier string

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: '${uniqueString(deployment().name)}-vnet'
  params: {
    name: '${identifier}-vnet'
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        addressPrefix: '10.0.1.0/24'
        name: 'default'
      }
    ]
  }
}

module privateDNSZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: '${uniqueString(deployment().name)}-pdnsz'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    location: 'global'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
      }
    ]
  }
}


@description('The resource ID of the created Virtual Network Subnet.')
output subnetResourceId string = virtualNetwork.outputs.subnetResourceIds[0]

@description('The resource ID of the created Private DNS Zone.')
output privateDNSZoneResourceId string = privateDNSZone.outputs.resourceId
