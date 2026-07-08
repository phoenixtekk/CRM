<#
.SYNOPSIS
    ITSTART-Enrollment-Readiness.ps1 — checks whether a specific user can enroll a device.
.DESCRIPTION
    PURPOSE
        Read-only readiness check for one user before they attempt enrollment: account enabled, an
        Intune-bearing service plan assigned, and membership in the pilot group. Catches the #1
        enrollment failure (unlicensed user) before it happens.
    HOW TO RUN
        Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","Group.Read.All"
        .\ITSTART-Enrollment-Readiness.ps1 -UserPrincipalName pilot01@contoso.com
    EXPECTED RESULTS
        PASS/FAIL per readiness item for that user. Nothing is changed.
.NOTES
    White-label — Intune Solutions. Read-only. Intune service-plan id 'c1ec4a95-1f05-45b3-a911-aa3fa01094f5'.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName,
    [string]$PilotGroup = 'INTUNE - QuickStart - Pilot'
)
if (-not (Get-MgContext)) { Write-Host 'Not connected. Run Connect-MgGraph first (see .SYNOPSIS).' -ForegroundColor Yellow; return }
function C($n,$ok,$d){ [pscustomobject]@{ Check=$n; Result=$(if($ok){'PASS'}else{'FAIL'}); Detail=$d } }
$INTUNE_PLAN = 'c1ec4a95-1f05-45b3-a911-aa3fa01094f5'  # Microsoft Intune service plan id

$res = New-Object System.Collections.Generic.List[object]
try {
    $u = Invoke-MgGraphRequest -Method GET -Uri ("v1.0/users/{0}?`$select=id,displayName,accountEnabled,userPrincipalName" -f [uri]::EscapeDataString($UserPrincipalName))
} catch { Write-Host "User '$UserPrincipalName' not found." -ForegroundColor Red; return }

$res.Add( (C 'Account enabled' ([bool]$u.accountEnabled) "enabled=$($u.accountEnabled)") )

# Intune-bearing license via assigned service plans
$hasIntune = $false; $planDetail = 'none'
try {
    $lic = (Invoke-MgGraphRequest -Method GET -Uri ("v1.0/users/{0}/licenseDetails" -f $u.id)).value
    foreach ($l in $lic) {
        $enabled = $l.servicePlans | Where-Object { $_.servicePlanId -eq $INTUNE_PLAN -and $_.provisioningStatus -eq 'Success' }
        if ($enabled) { $hasIntune = $true; $planDetail = $l.skuPartNumber; break }
    }
    if (-not $hasIntune -and $lic) { $planDetail = ($lic.skuPartNumber -join ', ') }
} catch {}
$res.Add( (C 'Intune license assigned' $hasIntune "Intune service plan enabled via: $planDetail") )

# pilot group membership
$inGroup = $false
try {
    $grp = (Invoke-MgGraphRequest -Method GET -Uri ("v1.0/groups?`$filter=displayName eq '{0}'" -f ($PilotGroup -replace "'","''"))).value | Select-Object -First 1
    if ($grp) {
        $members = (Invoke-MgGraphRequest -Method GET -Uri ("v1.0/groups/{0}/members?`$select=id" -f $grp.id)).value
        $inGroup = [bool]($members.id -contains $u.id)
    }
} catch {}
$res.Add( (C "Member of '$PilotGroup'" $inGroup $(if($grp){''}else{'group not found (optional if scope=All)'})) )

Write-Host "`n=== Enrollment Readiness — $($u.displayName) <$($u.userPrincipalName)> ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$fail = ($res | Where-Object Result -eq 'FAIL')
if ($fail | Where-Object Check -eq 'Intune license assigned') {
    Write-Host 'BLOCKER: user has no enabled Intune license — assign one before enrolling (Requirements #3).' -ForegroundColor Red
} elseif (-not $fail) {
    Write-Host 'Ready to enroll.' -ForegroundColor Green
}
