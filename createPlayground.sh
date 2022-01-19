#!/bin/bash



# Check if user wants to create a new resource group
read -p "Do you want to create a new resource group? (y/n) " -n 1 -r

# If user wants to create a new resource group, then create it
if [[ -z $REPLY ]]; then
    echo
    echo "No response. Exiting..."
    exit 1
elif [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    read -p "Enter the name of the resource group: " resourceGroupName
    read -p "Enter the location of the resource group: " resourceGroupLocation

    if [ -z $resourceGroupName ] || [ -z $resourceGroupLocation ] ; then
        echo
        echo "No resource group name or location entered. Exiting..."
        exit 1
    fi
    az group create --name $resourceGroupName --location $resourceGroupLocation
else
    echo
    echo "Exiting..."
    exit 0
fi
echo

# Output the resource group name and location of the new resource group(s)
echo "Created resource group $resourceGroupName"
echo "Resource group location: $resourceGroupLocation"

# Output current resource group(s)
echo
az group list -o table

# # Check if user wants to deploy a template to the resource group
# echo
# read -p "Do you want to deploy a template to the resource group? (y/n) " -n 1 -r

# # If user wants to deploy a template to the resource group, then deploy it
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     echo
#     read -p "Enter the file path of the template file: " templateFileName

#     # Check if template file exists
#     if [ -f $templateFileName ] ; then
#         echo
#         echo "Template file exists. Deploying..."
#         az deployment group create --name $resourceGroupName --resource-group $resourceGroupName --template-file $templateFileName
#         echo "Deployed templateFileName to resourceGroupName"
#     else
#         echo
#         echo "Template file does not exist. Exiting..."
#         exit 1
#     fi    
    
#     # Show the deployment output summary
#     echo
#     az deployment group show --name $resourceGroupName --resource-group $resourceGroupName -o table
    
#     # List out resources in the resource group
#     echo
#     az resource list --resource-group $resourceGroupName -o table
# elif [[ $REPLY =~ ^[Nn]$ ]]; then
#     exit
# else
#     echo "Invalid input. Exiting..."
# fi