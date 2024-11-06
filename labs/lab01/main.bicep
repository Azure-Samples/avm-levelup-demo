targetScope = 'subscription'

metadata name = 'Using Customer-Managed-Keys with User-Assigned identity'
metadata description = 'This instance deploys the module using Customer-Managed-Keys using a User-Assigned Identity to access the Customer-Managed-Key secret.'

@maxLength(7)
@description('Optional. Unique identifier for the deployment. Will appear in resource names. Must be 7 characters or less.')
param identifier string

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

resource coreResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${identifier}-core-rg'
  location: location
}

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${identifier}-workload-rg'
  location: location
}

module core 'core.bicep' = {
  scope: coreResourceGroup
  name: '${uniqueString(deployment().name, location)}-core'
  params: {
    location: location
    identifier: identifier
  }
}

module workload 'workload.bicep' = {
  scope: workloadResourceGroup
  name: '${uniqueString(deployment().name, location)}-workload'
  params: {
    location: location
    identifier: identifier
    subnetResourceId: core.outputs.subnetResourceId
    privateDNSZoneResourceId: core.outputs.privateDNSZoneResourceId
  }
  dependsOn: [core] 
}
