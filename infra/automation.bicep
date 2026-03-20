param location string = resourceGroup().location
param automationAccountName string = 'arc-sql-automation'
param runbookName string = 'Tag-ArcSqlMachines'

resource automation 'Microsoft.Automation/automationAccounts@2023-05-15-preview' = {
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-05-15-preview' = {
  parent: automation
  name: runbookName
  location: location
  properties: {
    runbookType: 'PowerShell74'
    logProgress: true
    logVerbose: true
    description: 'Tags Arc machines running SQL Server Standard edition'
  }
}

output principalId string = automation.identity.principalId

