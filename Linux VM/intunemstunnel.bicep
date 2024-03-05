// Thanks to many blog posts and MS examples from which I ~~created~~ copy-pasted this.
// === Parameters === //
@description('The name of you Virtual Machine.')
param vmName string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Size of the virtual machine.')
param vmSize string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the VNET')
param virtualNetworkName string

@description('Name of the subnet in the virtual network')
param subnetName string

@description('Resource Group of the VNET')
param vNetResourceGroup string

@description('Private IP address')
param privateIPaddress string

@description('Availability Set')
param availabilitySetName string

@description('Create Availability Set')
param createAvailabilitySet bool

@description('Use cloud-init file')
param useCloudInit bool

@description('OS Disk Type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param osDiskType string


// === Variables === //
var cloudInit = ((useCloudInit) ? base64(loadTextContent('cloud-init.yaml')) : null)
var osDiskName = '${vmName}-osdisk'
var networkInterface1Name = '${vmName}-nic1'
var networkSecurityGroupName = '${vmName}-nsg'

var imageReferenceLookup = {
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}


// === Resources === //
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(vNetResourceGroup)
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/virtualnetworks/subnets?pivots=deployment-language-bicep
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH-IN'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'HTTPS-IN'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'QUIC-IN'
        properties: {
          priority: 1002
          protocol: 'Udp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'HTTPS-OUT'
        properties: {
          priority: 1003
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterface1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: ((privateIPaddress == null) ? 'Dynamic' : 'Static') 
          privateIPAddress: ((privateIPaddress == null) ? null : privateIPaddress)
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/2023-03-01/availabilitysets?pivots=deployment-language-bicep
resource availabilitysetNew 'Microsoft.Compute/availabilitySets@2023-03-01' = if (createAvailabilitySet) {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource availabilitysetExisting 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (!(createAvailabilitySet)) {
  name: availabilitySetName
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
    name: vmName
    location: location
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: imageReferenceLookup[ubuntuOSVersion]
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          name: osDiskName
          osType: 'Linux'
          managedDisk: {
            storageAccountType: osDiskType
          }
          deleteOption: 'Delete'
          diskSizeGB: 30
        }
        dataDisks: []
        diskControllerType: 'SCSI'      
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: networkInterface.id
          }
        ]
      }
      availabilitySet: ((createAvailabilitySet) ? availabilitysetNew : availabilitysetExisting)
      osProfile: {
        computerName: vmName
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
        customData: cloudInit
      }
      securityProfile: null
    }
}


output sshCommand string = 'ssh ${adminUsername}@${privateIPaddress}'
