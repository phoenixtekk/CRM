<#
.SYNOPSIS
    ENTB2B-Discovery.ps1 — External Identities posture: cross-tenant access settings, guests, guest CA, access packages.
.DESCRIPTION
    PURPOSE
        Reports the current External Identities posture: the default cross-tenant access policy
        (inbound/outbound B2B collaboration, direct connect, trust settings), any per-partner
        (organizational) settings, the guest (#EXT#) user count, Conditional Access policies that target
        guest/external users, and entitlement-management access packages and access reviews. Read-only —
        it changes nothing. Use it to capture the before-state and confirm prerequisites.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTB2B-Discovery.ps1
        Connects to Microsoft Graph with read-only scopes:
        Policy.Read.All, CrossTenantInformation.ReadBasic.All, User.Read.All,
        EntitlementManagement.Read.All, AccessReview.Read.All.
    EXPECTED RESULTS
        A printed summary of default trust settings, named partner organizations, guest count,
        guest-scoped CA policies, access packages, and access reviews. Pass = summary prints; fail = a
        connection/consent error (install the Graph SDK / grant the read scopes).
.NOTES
    White-label. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','CrossTenantInformation.ReadBasic.All','User.Read.All','EntitlementManagement.Read.All','AccessReview.Read.All' -NoWelcome

Write-Host "`n=== Entra External Identities (B2B) — discovery ===" -ForegroundColor Cyan

# 1) Default cross-tenant access policy
try {
    $def = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/default'
    $inMfa = $def.inboundTrust.isMfaAccepted
    $inDev = $def.inboundTrust.isCompliantDeviceAccepted
    $inHyb = $def.inboundTrust.isHybridAzureADJoinedDeviceAccepted
    Write-Host "`n[Default cross-tenant access — inbound trust]" -ForegroundColor Yellow
    Write-Host ("  Trust partner MFA           : {0}" -f $inMfa)  -ForegroundColor ($(if($inMfa){'Yellow'}else{'Green'}))
    Write-Host ("  Trust compliant device      : {0}" -f $inDev)  -ForegroundColor ($(if($inDev){'Yellow'}else{'Green'}))
    Write-Host ("  Trust hybrid-joined device  : {0}" -f $inHyb)  -ForegroundColor ($(if($inHyb){'Yellow'}else{'Green'}))
    Write-Host "  (Trusting claims in the DEFAULT policy applies to ALL unknown tenants — prefer per-partner trust.)"
} catch { Write-Host "  Could not read default cross-tenant policy: $($_.Exception.Message)" -ForegroundColor Yellow }

# 2) Named partner (organizational) settings
try {
    $partners = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/partners').value)
    Write-Host ("`n[Named partner organizations]  : {0}" -f $partners.Count) -ForegroundColor Yellow
    $partners | Select-Object -First 25 | ForEach-Object { Write-Host ("  - tenantId {0}" -f $_.tenantId) }
} catch { Write-Host "  Could not read partner settings: $($_.Exception.Message)" -ForegroundColor Yellow }

# 3) Guest inventory
try {
    $guests = @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userType eq 'Guest'&`$select=displayName,userPrincipalName,accountEnabled,createdDateTime,signInActivity&`$top=999").value)
    Write-Host ("`n[Guest (#EXT#) users]          : {0}" -f $guests.Count) -ForegroundColor Yellow
    $never = @($guests | Where-Object { -not $_.signInActivity -or -not $_.signInActivity.lastSignInDateTime })
    Write-Host ("  Never signed in              : {0}" -f $never.Count) -ForegroundColor ($(if($never.Count -gt 0){'Yellow'}else{'Green'}))
} catch { Write-Host "  Could not read guests: $($_.Exception.Message)" -ForegroundColor Yellow }

# 4) Guest-scoped Conditional Access policies
try {
    $ca = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
    $guestCa = @($ca | Where-Object { $_.conditions.users.includeGuestsOrExternalUsers -or ($_.conditions.users.includeUsers -contains 'GuestsOrExternalUsers') })
    Write-Host ("`n[Conditional Access policies]  : {0} total, {1} target guest/external users" -f $ca.Count, $guestCa.Count) -ForegroundColor Yellow
    $guestCa | ForEach-Object { Write-Host ("  - {0} [{1}]" -f $_.displayName, $_.state) }
} catch { Write-Host "  Could not read Conditional Access policies (needs Policy.Read.All): $($_.Exception.Message)" -ForegroundColor Yellow }

# 5) Entitlement management — access packages + reviews
try {
    $pkgs = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/entitlementManagement/accessPackages').value)
    Write-Host ("`n[Access packages]              : {0}" -f $pkgs.Count) -ForegroundColor Yellow
    $pkgs | Select-Object -First 25 | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }
    $reviews = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/accessReviews/definitions').value)
    Write-Host ("[Access review definitions]    : {0}" -f $reviews.Count) -ForegroundColor Yellow
} catch { Write-Host "  Could not read entitlement management / access reviews (P2/Governance + scopes): $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`nDone. Read-only — no changes were made." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
