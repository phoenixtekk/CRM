<#
.SYNOPSIS
    CPLTREADY-AssignLicenses.ps1 — assign the Microsoft 365 Copilot SKU to the cohort/wave group members.
.DESCRIPTION
    PURPOSE
        Assigns the Microsoft 365 Copilot license to each member of the named cohort/wave group via
        Microsoft Graph. Prefers group-based licensing in the portal; this script is for scripted or
        catch-up assignment. Defaults to -WhatIf (reports what it WOULD do, changes nothing).
    HOW TO RUN
        Connect-MgGraph -Scopes "User.ReadWrite.All","Group.Read.All","Organization.Read.All","Directory.Read.All"
        Preview (default, safe):
        powershell -ExecutionPolicy Bypass -File .\CPLTREADY-AssignLicenses.ps1 -GroupId <entra-group-object-id>
        Apply for real (must pass -WhatIf:$false):
        powershell -ExecutionPolicy Bypass -File .\CPLTREADY-AssignLicenses.ps1 -GroupId <id> -WhatIf:$false
        Requires module: Microsoft.Graph.
    EXPECTED RESULTS
        In preview: lists members and the assignment it WOULD make, skipping already-licensed users and
        flagging any without a usage location. When applied: assigns the Copilot SKU to eligible members.
        Note: verify the current Copilot SKU part number and base-plan prerequisite in your tenant.
.NOTES
    Copilot. White-label. Mutating only when -WhatIf:$false is passed. Verify licensing facts in your tenant.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$CopilotSkuPartNumber = 'Microsoft_365_Copilot',
    [bool]$WhatIf = $true
)

if ($WhatIf) { $WhatIfPreference = $true }

Write-Host "=== CPLTREADY Assign Licenses — Microsoft 365 Copilot ===" -ForegroundColor Cyan
if (-not (Get-MgContext)) { Write-Host "Run Connect-MgGraph first (see header)." -ForegroundColor Yellow; return }

$copilot = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -eq $CopilotSkuPartNumber -or $_.SkuPartNumber -match 'Copilot' } | Select-Object -First 1
if (-not $copilot) {
    Write-Host ("No Copilot SKU found matching '{0}'. Confirm the SKU part number in Billing -> Licenses and pass -CopilotSkuPartNumber." -f $CopilotSkuPartNumber) -ForegroundColor Yellow
    return
}
$available = $copilot.PrepaidUnits.Enabled - $copilot.ConsumedUnits
Write-Host ("Copilot SKU : {0}  (available seats: {1})" -f $copilot.SkuPartNumber, $available) -ForegroundColor Green

$members = Get-MgGroupMember -GroupId $GroupId -All -ErrorAction Stop
$toAssign = New-Object System.Collections.Generic.List[object]
foreach ($m in $members) {
    $u = Get-MgUser -UserId $m.Id -Property "userPrincipalName,assignedLicenses,usageLocation" -ErrorAction SilentlyContinue
    if (-not $u) { continue }
    if (@($u.AssignedLicenses.SkuId | Where-Object { $_ -eq $copilot.SkuId }).Count -gt 0) { Write-Host ("  skip (already licensed): {0}" -f $u.UserPrincipalName) -ForegroundColor Gray; continue }
    if (-not $u.UsageLocation) { Write-Host ("  BLOCKED (no usage location): {0} — set usage location first" -f $u.UserPrincipalName) -ForegroundColor Yellow; continue }
    $toAssign.Add($u)
}

Write-Host ("`nWould assign Copilot to {0} member(s)." -f $toAssign.Count) -ForegroundColor Cyan
if ($toAssign.Count -gt $available) { Write-Host ("  WARNING: only {0} seats available for {1} assignments — acquire more seats." -f $available, $toAssign.Count) -ForegroundColor Yellow }

foreach ($u in $toAssign) {
    if ($PSCmdlet.ShouldProcess($u.UserPrincipalName, "Assign Copilot SKU $($copilot.SkuPartNumber)")) {
        try {
            Set-MgUserLicense -UserId $u.Id -AddLicenses @(@{ SkuId = $copilot.SkuId }) -RemoveLicenses @() -ErrorAction Stop | Out-Null
            Write-Host ("  assigned: {0}" -f $u.UserPrincipalName) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED {0}: {1}" -f $u.UserPrincipalName, $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  would assign: {0}" -f $u.UserPrincipalName) -ForegroundColor Yellow
    }
}

if ($WhatIf) { Write-Host "`nPreview only — re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow }
else { Write-Host "`nDone. Verify in Billing -> Licenses and run CPLTREADY-Validate.ps1." -ForegroundColor Green }
