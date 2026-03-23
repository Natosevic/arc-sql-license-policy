param (
    [string]$TagName  = "EnableLicenseChange",
    [string]$TagValue = "true",
    [string]$TargetSqlEdition = "Standard"
)

# Module imports
Import-Module Az.ResourceGraph -Force

# Get context from managed identity
Connect-AzAccount -Identity | Out-Null
$Context = Get-AzContext
$SubscriptionId = $Context.Subscription.Id
$TenantId = $Context.Tenant.Id
Write-Output "Subscription: $SubscriptionId"
Write-Output "Tenant: $TenantId"

# -------------------------------
# 1. Machines with Standard SQL
# -------------------------------
$machinesQuery = @"
Resources
| where type =~ 'microsoft.hybridcompute/machines'
| extend machineId = tolower(id)
| project machineId
| join kind=leftouter (
    Resources
    | where type =~ 'microsoft.azurearcdata/sqlserverinstances'
    | where tostring(properties.edition) == '$TargetSqlEdition'
    | extend machineId = tolower(tostring(properties.containerResourceId))
    | where isnotempty(machineId)
    | project machineId
) on machineId
| join kind=leftouter (
    Resources
    | where type =~ 'microsoft.hybridcompute/machines/extensions'
    | where properties.type in ('WindowsAgent.SqlServer','LinuxAgent.SqlServer')
    | extend machineId = tolower(substring(id, 0, indexof(id, '/extensions/')))
    | project machineId
) on machineId
| extend shouldBeTagged = iff(
    isnotnull(machineId1) and isnotnull(machineId2),
    true,
    false
)
| project machineId, shouldBeTagged
"@

$results = Search-AzGraph -Subscription $SubscriptionId -Query $machinesQuery -First 1000

# -------------------------------
# 3. Reconcile
# -------------------------------
Write-Output "Reconciling tags...`r`n`r`n"


foreach ($row in $results) {

    $machineId = $row.machineId
    $shouldBeTagged = [bool]$row.shouldBeTagged

    if ($shouldBeTagged) {
        Write-Output "Ensuring tag on $machineId"
        Update-AzTag `
            -ResourceId $machineId `
            -Operation Merge `
            -Tag @{ $tagName = $tagValue } `
            -Force
    }
    else {
        Write-Output "Ensuring tag removed from $machineId"
        Update-AzTag `
            -ResourceId $machineId `
            -Operation Delete `
            -Tag @{ $tagName = '' } `
            -Force
    }
}

Write-Output "Reconcile completed."