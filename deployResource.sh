#!/bin/bash

# Check if user wants to deploy a template to the resource group
echo
read -p "Do you want to deploy a template to the resource group? (y/n) " -n 1 -r

# If user wants to deploy a template, then deploy it
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    
    # Get the resource group name and location from the user for where to deploy the template
    read -p "Enter the name of the resource group: " resourceGroupName
    read -p "Enter the location of the resource group: " resourceGroupLocation
    
    # Get the template file name from the user
    read -p "Enter the file path of the template file: " templateFileName

    # Check if template file exists
    if [ -f $templateFileName ] ; then
        echo
        echo "Template file exists. Deploying..."
        az deployment group create --name $resourceGroupName --resource-group $resourceGroupName --template-file $templateFileName
        echo "Deployed $templateFileName to $resourceGroupName"
        # Show the deployment output summary
        echo
        az deployment group show --name $resourceGroupName --resource-group $resourceGroupName -o table
    
        # List out resources in the resource group
        az resource list --resource-group $resourceGroupName -o table
    else
        echo
        echo "Template file does not exist. Exiting..."
        exit 1
    fi    
elif [[ $REPLY =~ ^[Nn]$ ]]; then
    exit
else
    echo "Invalid input. Exiting..."
fi