// Azure AI Foundry Infrastructure
// This template deploys Azure AI Foundry Hub, Project, and GPT-4o model
// WITH managed identity for secure authentication

targetScope = 'resourceGroup'

@description('Name of the Azure AI Hub')
param aiHubName string = 'aihub-${uniqueString(subscription().id, resourceGroup().id, environmentName)}'

@description('Name of the Azure AI Project')
param aiProjectName string = 'aiproject-${uniqueString(subscription().id, resourceGroup().id, environmentName)}'

@description('Name of the Azure OpenAI service')
param openAiName string = 'openai-${uniqueString(subscription().id, resourceGroup().id, environmentName)}'

@description('Name of the storage account')
param storageAccountName string = 'st${toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))}'

@description('Name of the Key Vault')
param keyVaultName string = 'kv-${uniqueString(subscription().id, resourceGroup().id, environmentName)}'

@description('Name of the Application Insights')
param appInsightsName string = 'ai-${uniqueString(subscription().id, resourceGroup().id, environmentName)}'

@description('Name of the user-assigned managed identity')
param userManagedIdentityName string = 'id-${uniqueString(subscription().id, resourceGroup().id, environmentName)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name for AZD')
param environmentName string

// Variables
var tags = {
  'azd-env-name': environmentName
}

// User-assigned managed identity for secure authentication
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userManagedIdentityName
  location: location
  tags: tags
}

// Storage Account - Required for Azure ML Hub
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Key Vault - Required for Azure ML Hub
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
    accessPolicies: [] // Using RBAC instead of access policies
  }
}

// Application Insights - Required for Azure ML Hub
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: false
    DisableLocalAuth: false
    ForceCustomerStorageForProfiler: false
    ImmediatePurgeDataOn30Days: true
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Azure OpenAI Service
resource openAiService 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true  // Disable API key authentication
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4o Model Deployment
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAiService
  name: 'gpt-4o'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
  sku: {
    name: 'Standard'
    capacity: 10
  }
}

// RBAC Role Assignment: Grant Cognitive Services OpenAI User role to managed identity
resource openAiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAiService.id, userManagedIdentity.id, 'Cognitive Services OpenAI User')
  scope: openAiService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: userManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC Role Assignment: Grant Key Vault Secrets User role to managed identity
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, userManagedIdentity.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: userManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Hub (Machine Learning Workspace configured as Hub)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiHubName
    description: 'Azure AI Foundry Hub for AI project development'
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    hbiWorkspace: false
    publicNetworkAccess: 'Enabled'
    v1LegacyMode: false
    // Hub-specific configuration
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: resourceGroup().id
    }
  }
}

// Azure AI Project (Machine Learning Workspace configured as Project)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiProjectName
    description: 'Azure AI Foundry Project connected to Hub'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
    v1LegacyMode: false
  }
}

// OpenAI Connection for AI Project using Managed Identity
resource openAiConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = {
  parent: aiProject
  name: 'openai-connection'
  properties: {
    category: 'AzureOpenAI'
    target: openAiService.properties.endpoint
    authType: 'AAD'  // Use Azure AD authentication
    metadata: {
      ApiType: 'Azure'
      ApiVersion: '2024-02-01'
      ResourceId: openAiService.id
    }
  }
}

// Outputs
output RESOURCE_GROUP_ID string = resourceGroup().id
output aiHubName string = aiHub.name
output aiHubId string = aiHub.id
output aiProjectName string = aiProject.name
output aiProjectId string = aiProject.id
output openAiServiceName string = openAiService.name
output openAiServiceId string = openAiService.id
output openAiEndpoint string = openAiService.properties.endpoint
output gpt4oDeploymentName string = gpt4oDeployment.name
output openAiConnectionName string = openAiConnection.name
output storageAccountName string = storageAccount.name
output keyVaultName string = keyVault.name
output appInsightsName string = appInsights.name
output resourceGroupName string = resourceGroup().name
output location string = location
output userManagedIdentityName string = userManagedIdentity.name
output userManagedIdentityId string = userManagedIdentity.id
output userManagedIdentityClientId string = userManagedIdentity.properties.clientId
output userManagedIdentityPrincipalId string = userManagedIdentity.properties.principalId
