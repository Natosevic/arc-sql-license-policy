targetScope = 'subscription'

@description('Policy assignment name (resource name)')
param assignmentName string = 'set-arc-sql-license-assignment'

@description('Policy definition resource ID')
param policyDefinitionId string
 
var assignmentPropsFromFile = loadJsonContent('../policy/set-arc-sql-license.assignment.json')

resource policyAssign 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: assignmentName
  identity: {
    type: 'SystemAssigned'
  }
  properties: union(
    assignmentPropsFromFile,
    {
      // override just the policyDefinitionId dynamically
      policyDefinitionId: policyDefinitionId
    }
  )
}

output policyAssignmentId string = policyAssign.id
output policyAssignmentPrincipalId string = policyAssign.identity.principalId
