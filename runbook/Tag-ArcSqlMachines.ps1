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
$machinesByEditionQuery = @"
Resources
| where type =~ 'microsoft.azurearcdata/sqlserverinstances'
| where tostring(properties.edition) == '$TargetSqlEdition'
| extend machineId = tolower(tostring(properties.containerResourceId))
| summarize by machineId
"@

$machinesByEdition = Search-AzGraph -Subscription $SubscriptionId -Query $machinesByEditionQuery -First 1000
$eligibleMachineIds = $machinesByEdition.machineId

# -------------------------------
# 2. All Arc SQL extensions
# -------------------------------
$extensionsQuery = @"
Resources
| where type =~ 'microsoft.hybridcompute/machines/extensions'
| where tostring(properties.type) in~ ('WindowsAgent.SqlServer','LinuxAgent.SqlServer')
| extend machineId = tolower(substring(id, 0, indexof(id, '/extensions/')))
| project id, machineId, tags
"@

$extensions = Search-AzGraph -Subscription $SubscriptionId -Query $extensionsQuery -First 1000

# -------------------------------
# 3. Reconcile
# -------------------------------
foreach ($ext in $extensions) {

    if ($eligibleMachineIds -contains $ext.machineId) {
        # SHOULD be tagged
        if ($ext.tags[$TagName] -ne $TagValue) {
            Write-Output "Tagging extension: $($ext.id)"
            Update-AzTag -ResourceId $ext.id -Operation Merge -Tag @{
                $TagName = $TagValue
            } | Out-Null
        }
    }
    else {
        # SHOULD NOT be tagged
        if ($ext.tags.ContainsKey($TagName)) {
            Write-Output "Removing tag from extension: $($ext.id)"
            Update-AzTag -ResourceId $ext.id -Operation Delete -Tag @{
                $TagName = ""
            } | Out-Null
        }
    }
}

Write-Output "Reconcile completed."