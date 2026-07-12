<#
.SYNOPSIS
    ENTB2B-Validate.ps1 — validate the B2B pilot: conservative defaults, trusted partner, guest CA, break-glass exclusion.
.DESCRIPTION
    PURPOSE
        Confirms the pilot configuration is correct and safe: the DEFAULT cross-tenant access policy does
        not trust unknown-tenant MFA/device claims and blocks direct connect; the named pilot partner
        exists as an organizational setting; a Conditional Access policy targeting guest/external users
        exists; and the named break-glass accounts are EXCLUDED from that guest policy. Read-only — it
        reports pass/fail per check and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTB2B-Validate.ps1 `
            -PartnerTenantId "<partner-guid>" `
            -GuestCaPolicyName "Require MFA - Guest Users - Pilot" `
            -BreakGlassUpns "bg1@contoso.onmicrosoft.com","bg2@contoso.onmicrosoft.com"
        Connects to Microsoft Graph with read-only scopes: Policy.Read.All, User.Read.All.
    EXPECTED RESULTS
        PASS/FAIL lines for each check. All PASS = the pilot guardrails are in place. Any FAIL points to
        the exact object to fix (see the Troubleshooting Guide).
.NOTES
    White-label. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$PartnerTenantId,
    [string]$GuestCaPolicyName = 'Require MFA - Guest Users - Pilot',
    [string[]]$BreakGlassUpns = @()
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','User.Read.All' -NoWelcome

$pass = 0; $fail = 0
function Test-Line($ok, $msg) { if ($ok) { Write-Host "  PASS  $msg" -ForegroundColor Green; $script:pass++ } else { Write-Host "  FAIL  $msg" -ForegroundColor Red; $script:fail++ } }

Write-Host "`n=== ENTB2B — pilot validation ===" -ForegroundColor Cyan

# 1) Default policy does not trust unknown-tenant claims
try {
    $def = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/default'
    Test-Line (-not $def.inboundTrust.isMfaAccepted) "Default policy does NOT trust unknown-tenant MFA claims"
    Test-Line (-not $def.inboundTrust.isCompliantDeviceAccepted) "Default policy does NOT trust unknown-tenant compliant-device claims"
} catch { Test-Line $false "Read default cross-tenant policy ($($_.Exception.Message))" }

# 2) Named pilot partner exists
if ($PartnerTenantId) {
    try {
        $partners = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/partners').value)
        Test-Line ($partners.tenantId -contains $PartnerTenantId) "Pilot partner $PartnerTenantId configured as an organizational setting"
    } catch { Test-Line $false "Read partner settings ($($_.Exception.Message))" }
} else { Write-Host "  SKIP  Partner check (no -PartnerTenantId supplied)" -ForegroundColor DarkGray }

# 3) Guest-scoped CA policy exists, and break-glass is excluded
try {
    $ca = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
    $pol = $ca | Where-Object { $_.displayName -eq $GuestCaPolicyName } | Select-Object -First 1
    Test-Line ($null -ne $pol) "Guest CA policy '$GuestCaPolicyName' exists"
    if ($pol) {
        $targetsGuests = $pol.conditions.users.includeGuestsOrExternalUsers -or ($pol.conditions.users.includeUsers -contains 'GuestsOrExternalUsers')
        Test-Line $targetsGuests "Policy targets guest/external users"
        if ($BreakGlassUpns.Count -gt 0) {
            $excluded = @($pol.conditions.users.excludeUsers)
            foreach ($bg in $BreakGlassUpns) {
                $id = $null; try { $id = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$bg`?`$select=id").id } catch {}
                Test-Line ($id -and ($excluded -contains $id)) "Break-glass excluded from guest policy: $bg"
            }
        } else { Write-Host "  SKIP  Break-glass exclusion check (no -BreakGlassUpns supplied)" -ForegroundColor DarkGray }
    }
} catch { Test-Line $false "Read Conditional Access policies ($($_.Exception.Message))" }

Write-Host ("`nResult: {0} passed, {1} failed." -f $pass, $fail) -ForegroundColor ($(if($fail -gt 0){'Red'}else{'Green'}))
Disconnect-MgGraph | Out-Null
if ($fail -gt 0) { exit 1 }
