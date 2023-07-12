param clusterName string = 'esearch'
param location string = resourceGroup().location
@secure()
param adminUserName string 
@secure()
param adminPassword string

///resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//  name: '${clusterName}-rg'
//  location: location
//}

resource vm 'Microsoft.Compute/virtualMachines@2021-06-01' = {
  name: '${clusterName}-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: '${clusterName}-vm'
      adminUsername: adminUserName
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '20.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        diskSizeGB: 5
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: '${clusterName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${clusterName}-subnet'
  dependsOn: [vnet]
  properties: {
    addressPrefix: '10.0.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: []
      }
    ]
    delegations: []
    routeTable: null
    serviceEndpointPolicies: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${clusterName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: []
            }
          ]
          delegations: []
          routeTable: null
          serviceEndpointPolicies: []
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${clusterName}-publicip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: clusterName
    }
  }
}

#disable-next-line BCP081
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2021-06-01' = {
  name: '${clusterName}-extension'
  location: location
  dependsOn: [vm]
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://path/to/elasticsearch-script.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash elasticsearch-script.sh'
    }
  }
}

output vmPublicIP string = publicIP.properties.ipAddress
//output elasticsearchEndpoint string = '${vmPublicIP}:9200'
