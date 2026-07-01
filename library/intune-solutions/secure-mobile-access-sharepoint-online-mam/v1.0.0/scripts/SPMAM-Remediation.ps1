<#
.SYNOPSIS
    SPMAM-Remediation.ps1 — safely fix a common misconfiguration: assign the App Protection Policies
    to the target group so the CA app-protection grant can be satisfied. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        The #1 mobile-access break is CA requiring app protection while the target group has no App
        Protection Policy assigned. This script adds the target group to the assignments of the named
        iOS and Android App Protection Policies (Microsoft Graph). It PREVIEWS by default (-WhatIf);
        pass -WhatIf:$false to apply.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\SPMAM-Remediation.ps1 -TargetGroup "SPO Mobile - Users - Pilot"
        Apply           : powershell -ExecutionPolicy Bypass -File .\SPMAM-Remediation.ps1 -TargetGroup "SPO Mobile - Users - Pilot" -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK. Consented scopes:
        DeviceManagementApps.ReadWrite.All, Group.Read.All.
    EXPECTED RESULTS
        With -WhatIf (default): prints the assignments it WOULD add. With -WhatIf:$false: adds the
        target group to each named App Protection Policy's assignments (idempotent — skips if present).
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Writes only when -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$TargetGroup,
    [string]$IosPolicyName     = 'SPO Mobile – App Protection – iOS',
    [string]$AndroidPolicyName = 'SPO Mobile – App Protection – Android'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All','Group.Read.All' -NoWelcome

$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$TargetGroup'&`$select=id,displayName").value | Select-Object -First 1
if (-not $grp) { Write-Host "Group not found: $TargetGroup" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 1 }

$targets = @(
    @{ Seg='iosManagedAppProtections';     Name=$IosPolicyName },
    @{ Seg='androidManagedAppProtections'; Name=$AndroidPolicyName }
)

foreach ($t in $targets) {
    $pol = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$($t.Seg)`?`$expand=assignments").value | Where-Object { $_.displayName -eq $t.Name } | Select-Object -First 1
    if (-not $pol) { Write-Host ("  SKIP: policy not found — {0}" -f $t.Name) -ForegroundColor Yellow; continue }

    $already = $pol.assignments | ForEach-Object { $_.target.groupId } | Where-Object { $_ -eq $grp.id }
    if ($already) { Write-Host ("  OK: {0} already assigned to {1}" -f $t.Name, $TargetGroup) -ForegroundColor Green; continue }

    if ($PSCmdlet.ShouldProcess("$($t.Name)", "Assign group '$TargetGroup'")) {
        $keep = @($pol.assignments | ForEach-Object { @{ target = $_.target } })
        $keep += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id } }
        $body = @{ assignments = $keep } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/$($t.Seg)/$($pol.id)/assign" -Body $body -ContentType 'application/json'
        Write-Host ("  APPLIED: assigned {0} to {1}" -f $t.Name, $TargetGroup) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would assign {0} to {1}" -f $t.Name, $TargetGroup) -ForegroundColor Cyan
    }
}

Write-Host "`nRe-run SPMAM-Validation.ps1 for a target user after a policy cycle." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
