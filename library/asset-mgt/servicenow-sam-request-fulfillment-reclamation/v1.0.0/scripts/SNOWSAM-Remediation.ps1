<#
.SYNOPSIS
    SNOWSAM-Remediation.ps1 — safe remediation of stale entitlement assignments (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Identifies stale software assignments (no recorded usage past a threshold, or belonging to an
        inactive user) and previews releasing them back to the available pool. By DEFAULT it runs in
        -WhatIf mode and changes NOTHING — it only lists what it would reclaim. You must explicitly pass
        -WhatIf:$false to perform updates via the ServiceNow REST Table API.
    HOW TO RUN
        Preview (safe, default):
          powershell -ExecutionPolicy Bypass -File .\SNOWSAM-Remediation.ps1 `
            -InstanceUrl https://<your-instance>.service-now.com -Credential (Get-Credential)
        Apply (after review):
          ... -WhatIf:$false
    EXPECTED RESULTS
        In preview: a list of candidate stale assignments and the action that would be taken.
        In apply mode: each candidate is released and the action is confirmed.
.NOTES
    Defaults to -WhatIf (preview). Assignment table/field names are instance-specific placeholders —
    confirm in ServiceNow's Table API docs and override via parameters. Run SNOWSAM-Report.ps1 first to
    review reclamation candidates; prefer the in-platform "License Reclamation - Unused - Reclamation"
    flow for production reclamation. This script is a manual safety-net for one-off cleanup.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$InstanceUrl,
    [Parameter(Mandatory)] [pscredential]$Credential,
    # INSTANCE-SPECIFIC: confirm/override these table/field names for your instance.
    [string]$AssignmentTable = 'samp_sw_allocation',
    [int]$InactiveDays = 90,
    [switch]$WhatIf = $true   # default ON: preview only
)

$headers = @{ Accept = 'application/json'; 'Content-Type' = 'application/json' }
$base = $InstanceUrl.TrimEnd('/')

Write-Host "`n=== ServiceNow SAM — Remediation ($InstanceUrl) ===" -ForegroundColor Cyan
if ($WhatIf) { Write-Host "MODE: PREVIEW (-WhatIf) — no changes will be made. Pass -WhatIf:`$false to apply." -ForegroundColor Yellow }
else         { Write-Host "MODE: APPLY — stale assignments WILL be released." -ForegroundColor Red }

# Pull active assignments and their last-used date.
$uri = "$base/api/now/table/$AssignmentTable?sysparm_limit=1000&sysparm_fields=sys_id,display_name,assigned_to,last_used,active"
try {
    $rows = (Invoke-RestMethod -Method GET -Uri $uri -Credential $Credential -Headers $headers -ErrorAction Stop).result
} catch {
    Write-Host ("Could not read assignments from '{0}': {1}" -f $AssignmentTable, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm the correct assignment table name for your instance (ServiceNow Table API docs)." -ForegroundColor Yellow
    exit 1
}

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$candidates = foreach ($r in $rows) {
    $lu = $null
    $stale = $false
    if ([string]::IsNullOrWhiteSpace("$($r.last_used)")) { $stale = $true }   # never recorded usage
    elseif ([datetime]::TryParse("$($r.last_used)", [ref]$lu) -and $lu -lt $cutoff) { $stale = $true }
    if ($stale) { $r }
}
$candidates = @($candidates)
Write-Host ("Stale assignment candidates (> {0} days unused): {1}" -f $InactiveDays, $candidates.Count) -ForegroundColor Cyan

foreach ($c in $candidates) {
    $label = "$($c.display_name) (assigned_to=$($c.assigned_to), last_used=$($c.last_used))"
    if ($WhatIf) {
        Write-Host ("  WOULD RELEASE: {0}" -f $label) -ForegroundColor Yellow
    }
    elseif ($PSCmdlet.ShouldProcess($label, 'Release stale assignment')) {
        $patchUri = "$base/api/now/table/$AssignmentTable/$($c.sys_id)"
        $body = @{ active = 'false' } | ConvertTo-Json   # INSTANCE-SPECIFIC: set the field your instance uses to mark a released allocation.
        try {
            Invoke-RestMethod -Method PATCH -Uri $patchUri -Credential $Credential -Headers $headers -Body $body -ErrorAction Stop | Out-Null
            Write-Host ("  RELEASED: {0}" -f $label) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED: {0} — {1}" -f $label, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}
Write-Host "`nRemediation complete." -ForegroundColor Green
if ($WhatIf) { Write-Host "Re-run with -WhatIf:`$false to apply after reviewing the list above." -ForegroundColor Yellow }
