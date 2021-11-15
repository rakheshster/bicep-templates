// === Parameters ===
@description('Size of VM. If you want different sizes select from https://docs.microsoft.com/en-us/azure/virtual-machines/av2-series')
param vmSize string = 'Standard_A4_v2'

@description('Name of the VM')
param vmName string

@description('Virtual Network to place the VM into **this must exist already**')
param existingVnetName string

@description('Subnet to place the VM into **this must exist already and be able to talk to the Domain Controllers**')
param existingSubnetName string

@description('Resource Group of the Virtual Network; defaults to the current one')
param vnetResourceGroup string = resourceGroup().name

@description('The AD domain name')
param domainToJoin string

@description('Domain Join account username')
param domainUsername string

@description('Domain Join account password')
@secure()
param domainPassword string

@description('OU to put VM into')
param ouPath string

@description('Local Admin username of the VM')
param adminUsername string = '${vmName}admin'

@description('Local Admin password of the VM')
@secure()
param adminPassword string

@description('Image Publisher - get via Get-AzVMImagePublisher -Location <location>')
param imagePublisher string

@description('Image Offer - get via Get-AzVMImageOffer -PublisherName <publisher> -Location <location>')
param imageOffer string

@description('Image Sku - get via Get-AzVMImageSku -PublisherName <publisher> -Offer <offer> -Location <location>')
param windowsOSVersion string

// === Variables ===
var location = resourceGroup().location
var nicName = '${vmName}-nic'
var osDisk = '${vmName}-osDisk'
var dataDisk = '${vmName}-dataDisk'
var domainJoinOptions = 3 // Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx'

// === Deployments ===
resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: existingVnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  parent: existingVirtualNetwork
  name: existingSubnetName
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: existingSubnet.id
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: osDisk
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: 127
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        osType: 'Windows'
      }
      dataDisks: [
        {
          name: dataDisk
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
          lun: 0
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        // skipping storageUri so it uses managed storage instead
        // https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?tabs=bicep#bootdiagnostics
      }
    }
  }
}

resource virtualMachineExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: '${domainToJoin}\\${domainUsername}'
      restart: true
      options: domainJoinOptions
    }
    protectedSettings: {
      Password: domainPassword
    }
  }
}
