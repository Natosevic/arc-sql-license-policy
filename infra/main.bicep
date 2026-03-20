module automation './automation.bicep' = {
  name: 'automation'
}

module rbac './rbac.bicep' = {
  name: 'rbac'
  scope: subscription()
  params: {
    automationPrincipalId: automation.outputs.principalId
    policyAssignmentPrincipalId: policyAssign.outputs.policyAssignmentPrincipalId
  }
}

module policyDef './policy-definition.bicep' = {
  name: 'policyDefinition'
  scope: subscription()
}

module policyAssign './policy-assignment.bicep' = {
  name: 'policyAssign'
  scope: subscription()
  params: {
    policyDefinitionId: policyDef.outputs.policyDefinitionId
  }
}
