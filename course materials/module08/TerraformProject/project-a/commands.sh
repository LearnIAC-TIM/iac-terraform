# List resources containing a specific string in the name
az resource list --query "[?contains(name, 'sa')]" --output table

# List resources of a specific type
az resource list --resource-type "Microsoft.Storage/storageAccounts" --output table

# Get the id of a specific resource
az resource show --resource-group rg-demo-project-a --name sademo12364s --resource-type "Microsoft.Storage/storageAccounts" --query id --output tsv

# Creates a json file with the list of resources
az resource list --resource-group rg-demo-project-a --output json > resources.json


# Remove a resource from terraform state
terraform state rm module.storage.azurerm_storage_account.sa-demo 

# Move a resource to another resource group
az resource move --destination-group rg-demo-project-b \
  --ids /subscriptions/5513747a-818d-4f48-83b0-da2b2fd4cb97/resourceGroups/rg-demo-project-a/providers/Microsoft.Storage/storageAccounts/sademo12364s