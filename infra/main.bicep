// Azure AI Foundry Infrastructure
// This template deploys Azure AI Foundry Hub, Project, and GPT-4o model
// WITH managed identity for secure authentication

targetScope = 'subscription'

@description('Name of the resource group')
param resourceGroupName string = 'rg-${environmentName}'

@description('Name of the Azure AI Hub')
param aiHubName string = 'aihub${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the Azure AI Project')
param aiProjectName string = 'aiproject${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the Azure OpenAI service')
param openAiName string = 'openai${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the storage account')
param storageAccountName string = 'st${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the Key Vault')
param keyVaultName string = 'kv${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the Application Insights')
param appInsightsName string = 'ai${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the user-assigned managed identity')
param userManagedIdentityName string = 'id${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the Azure Container Registry')
param containerRegistryName string = 'acr${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the App Service Plan')
param appServicePlanName string = 'asp${toLower(uniqueString(subscription().id, environmentName))}'

@description('Name of the App Service (Web App)')
param appServiceName string = 'app${toLower(uniqueString(subscription().id, environmentName))}'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment name for AZD')
param environmentName string

// Variables
var tags = {
  'azd-env-name': environmentName
}

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy all resources into the resource group using a module
module aiResources 'resources.bicep' = {
  name: 'aiResources'
  scope: resourceGroup
  params: {
    aiHubName: aiHubName
    aiProjectName: aiProjectName
    openAiName: openAiName
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
    appInsightsName: appInsightsName
    userManagedIdentityName: userManagedIdentityName
    containerRegistryName: containerRegistryName
    appServicePlanName: appServicePlanName
    appServiceName: appServiceName
    location: location
    tags: tags
  }
}

// Outputs
output RESOURCE_GROUP_ID string = resourceGroup.id
output resourceGroupName string = resourceGroup.name
output location string = location
output aiHubName string = aiResources.outputs.aiHubName
output aiHubId string = aiResources.outputs.aiHubId
output aiProjectName string = aiResources.outputs.aiProjectName
output aiProjectId string = aiResources.outputs.aiProjectId
output openAiServiceName string = aiResources.outputs.openAiServiceName
output openAiServiceId string = aiResources.outputs.openAiServiceId
output openAiEndpoint string = aiResources.outputs.openAiEndpoint
output gpt4oDeploymentName string = aiResources.outputs.gpt4oDeploymentName
output openAiConnectionName string = aiResources.outputs.openAiConnectionName
output storageAccountName string = aiResources.outputs.storageAccountName
output keyVaultName string = aiResources.outputs.keyVaultName
output appInsightsName string = aiResources.outputs.appInsightsName
output userManagedIdentityName string = aiResources.outputs.userManagedIdentityName
output userManagedIdentityId string = aiResources.outputs.userManagedIdentityId
output userManagedIdentityClientId string = aiResources.outputs.userManagedIdentityClientId
output userManagedIdentityPrincipalId string = aiResources.outputs.userManagedIdentityPrincipalId
output containerRegistryName string = aiResources.outputs.containerRegistryName
output containerRegistryLoginServer string = aiResources.outputs.containerRegistryLoginServer
output appServicePlanName string = aiResources.outputs.appServicePlanName
output appServiceName string = aiResources.outputs.appServiceName
output appServiceDefaultHostName string = aiResources.outputs.appServiceDefaultHostName
