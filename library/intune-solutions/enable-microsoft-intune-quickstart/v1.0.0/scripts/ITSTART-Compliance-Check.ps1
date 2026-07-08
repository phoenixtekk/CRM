<#
.SYNOPSIS
    ITSTART-Compliance-Check.ps1 — summarizes baseline compliance-policy assignments and device state.
.DESCRIPTION
    PURPOSE
        Read-only view of the Quick-Start baseline: which compliance policies exist, whether they are
        assigned, and a per-device compliance roll-up. Confirms devices are actually being evaluated,
        not just enrolled.
    HOW TO RUN
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All"
        .\ITSTART-Compliance-Check.ps1
    EXPECTED RESULTS
        Baseline policies listed with assignment counts, plus a compliance summary. Nothing is changed.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
if (-not (Get-MgContext)) { Write-Host 'Not connected. Run Connect-MgGraph first (see .SYNOPSIS).' -ForegroundColor Yellow; return }

# compliance policies + assignments
try {
    $cp = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceManagement/deviceCompliancePolicies?`$expand=assignments").value
} catch { Write-Host "Unable to read compliance policies: $($_.Exception.Message)" -ForegroundColor Red; return }

$polRows = $cp | ForEach-Object {
    [pscustomobject]@{
        Policy      = $_.displayName
        Platform    = ($_.'@odata.type' -replace '#microsoft.graph.','' -replace 'CompliancePolicy','')
        Assignments = @($_.assignments).Count
        Baseline    = if ($_.displayName -match 'Baseline') { 'yes' } else { '' }
    }
}
Write-Host "`n=== Compliance Policies ===" -ForegroundColor Cyan
$polRows | Sort-Object Baseline -Descending | Format-Table -AutoSize

$unassigned = $polRows | Where-Object { $_.Baseline -eq 'yes' -and $_.Assignments -eq 0 }
if ($unassigned) { Write-Host ("! Unassigned baseline policy: {0} — assign to the pilot group (implementation Step 8)." -f ($unassigned.Policy -join ', ')) -ForegroundColor Yellow }

# device compliance roll-up
try {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,complianceState").value
    if ($dev) {
        Write-Host "`n=== Device Compliance Roll-up ===" -ForegroundColor Cyan
        $dev | Group-Object complianceState | ForEach-Object { [pscustomobject]@{ State=$_.Name; Devices=$_.Count } } | Format-Table -AutoSize
        $noncompliant = $dev | Where-Object complianceState -ne 'compliant'
        if ($noncompliant) {
            Write-Host 'Not yet compliant:' -ForegroundColor Yellow
            $noncompliant | Select-Object deviceName,operatingSystem,complianceState | Format-Table -AutoSize
        } else { Write-Host 'All enrolled devices compliant.' -ForegroundColor Green }
    } else { Write-Host 'No enrolled devices yet.' -ForegroundColor Yellow }
} catch { Write-Host "Unable to read managed devices: $($_.Exception.Message)" -ForegroundColor Red }
