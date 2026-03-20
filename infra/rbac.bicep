targetScope = 'subscription'

param automationPrincipalId string

resource reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationPrincipalId, 'reader')
  scope: subscription()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
    )
    principalId: automationPrincipalId
  }
}

resource tagContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationPrincipalId, 'tag-contributor')
  scope: subscription()
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4a9ae827-6dc8-4573-8ac7-8239d42aa03f' // Tag Contributor
    )
    principalId: automationPrincipalId
  }
}
