param storageAccountID string
param principalID string
param roleDefinitionID string


// Allow access from API to storage account using a managed identity and least priv Storage roles
resource queueProcessorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccountID, principalID, roleDefinitionID)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalID
  }
}

output ROLE_ASSIGNMENT_NAME string = queueProcessorRoleAssignment.name
