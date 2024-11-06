@description('Optional. The location to deploy resources to.')
param location string

@maxLength(7)
@description('Optional. Unique identifier for the deployment. Will appear in resource names. Must be 7 characters or less.')
param identifier string

@description('Mandatory, Private DNS Zone for Private Endpoints')
param privateDNSZoneResourceId string

@description('Mandatory, Subnet id for Private Endppoints')
param subnetResourceId string


module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.2' = {
  name: '${uniqueString(deployment().name)}-mi'
  params: {
    name: '${identifier}-mi'
    location: location
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.5.0' = {
  name: '${uniqueString(deployment().name, location)}-${identifier}'
  params: {
    location: location
    name: '${identifier}saasdsg'
    privateEndpoints: [
      {
        service: 'blob'
        subnetResourceId: subnetResourceId
        privateDnsZoneResourceIds: [
          privateDNSZoneResourceId
        ]
      }
    ]
    blobServices: {
      containers: [
        {
          name: '${identifier}container'
          publicAccess: 'None'
        }
      ]
    }
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.outputs.resourceId
      ]
    }
    customerManagedKey: {
      keyName: 'keyEncryptionKey'
      keyVaultResourceId: keyVault.outputs.resourceId
      userAssignedIdentityResourceId: managedIdentity.outputs.resourceId
    }
  }
}

module keyVault 'br/public:avm/res/key-vault/vault:0.3.4' = {
  name: '${uniqueString(deployment().name)}-kv'
  params: {
    name: '${identifier}-kv-fsdg'
    location: location
    enablePurgeProtection: true
    softDeleteRetentionInDays: 7
    accessPolicies: []
    keys: [
      {
        name: 'keyEncryptionKey'
        kty: 'RSA'
      }
    ]
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424') // Key Vault Crypto User
        principalType: 'ServicePrincipal'
      }
    ]
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDNSZoneResourceId
        ]
        service: 'vault'
        subnetResourceId: subnetResourceId
      }
    ]
  }
}
