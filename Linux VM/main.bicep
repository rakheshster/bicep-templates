param virtualMachines_ca1devintunemstunnel01_name string = 'ca1devintunemstunnel01'
param availabilitySets_CA1INTUNEMSTUNNEL_externalid string = '/subscriptions/13ccaf89-ddcd-4be1-9fc6-c9d65761d512/resourceGroups/ca1-mobility/providers/Microsoft.Compute/availabilitySets/CA1INTUNEMSTUNNEL'
param disks_ca1devintunemstunnel01_OsDisk_1_40e78aea69c7404cbee879d38ed25bc3_externalid string = '/subscriptions/13ccaf89-ddcd-4be1-9fc6-c9d65761d512/resourceGroups/CA1-MOBILITY/providers/Microsoft.Compute/disks/ca1devintunemstunnel01_OsDisk_1_40e78aea69c7404cbee879d38ed25bc3'
param networkInterfaces_ca1devintunemstunnel0193_externalid string = '/subscriptions/13ccaf89-ddcd-4be1-9fc6-c9d65761d512/resourceGroups/ca1-mobility/providers/Microsoft.Network/networkInterfaces/ca1devintunemstunnel0193'

resource virtualMachines_ca1devintunemstunnel01_name_resource 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachines_ca1devintunemstunnel01_name
  location: 'canadacentral'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/13ccaf89-ddcd-4be1-9fc6-c9d65761d512/resourceGroups/Built-In-Identity-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/Built-In-Identity-canadacentral': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    availabilitySet: {
      id: availabilitySets_CA1INTUNEMSTUNNEL_externalid
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachines_ca1devintunemstunnel01_name}_OsDisk_1_40e78aea69c7404cbee879d38ed25bc3'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
          id: disks_ca1devintunemstunnel01_OsDisk_1_40e78aea69c7404cbee879d38ed25bc3_externalid
        }
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: virtualMachines_ca1devintunemstunnel01_name
      adminUsername: 'denadmin'
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_ca1devintunemstunnel0193_externalid
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
