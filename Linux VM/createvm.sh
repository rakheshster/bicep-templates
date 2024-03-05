# Image names https://canonical-azure.readthedocs-hosted.com/en/latest/azure-how-to/instances/find-ubuntu-images/

az vm create \
  --resource-group ca1-mobility \
  --name ca1mstunnel01 \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --admin-username denadmin \
  --generate-ssh-keys \
  --custom-data cloud-init.yaml

az deployment group create \
  --name ExampleDeployment \
  --resource-group ExampleGroup \
  --parameters storage.bicepparam

New-AzResourceGroupDeployment `
  -Name ExampleDeployment `
  -ResourceGroupName ExampleResourceGroup `
  -TemplateFile C:\MyTemplates\storage.bicep `
  -TemplateParameterFile C:\MyTemplates\storage.bicepparam