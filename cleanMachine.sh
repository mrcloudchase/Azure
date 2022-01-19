#!/bin/bash


# Excluded resource groups array
excludedResourceGroupArray=("cloud-chase-main-rg" "NetworkWatcherRG")

# # For loop to iterate through existing resource groups
for resource in $(az group list --query "[].{Name:name}" -o json | jq -r '.[].Name'); do
    echo "Resource group: $resource"
#  If statement to ignore the cloud-chase-main-rg and NetworkWatcherRG resource group from operations
    for exclude in "${excludedResourceGroupArray[@]}"; do
        if [ "$resource" == "$exclude" ]; then
            echo "Excluded resource group: $resource"
            continue 2
        fi
    done

# Export all resources in the resource group
    az group export --name $resource -o json > $resource.json
    echo "Exported resources in $resource to $resource.json"
    
# Destroy all resources in the resource group and the resource group itself
    echo "Deleting $resource"
    az group delete --name $resource --yes

done

echo
az group list -o json | jq -r '.[].name' | xargs -I {} echo "Existing resource group: {}"