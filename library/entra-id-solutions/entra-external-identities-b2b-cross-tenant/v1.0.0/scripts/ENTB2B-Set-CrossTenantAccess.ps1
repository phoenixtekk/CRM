<#
.SYNOPSIS
    ENTB2B-Set-CrossTenantAccess.ps1 — safely configure per-partner cross-tenant access + trust (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates or updates the ORGANIZATIONAL (per-partner) cross-tenant access configuration for one named
        partner tenant, and optionally enables inbound trust of that partner's MFA and/or device claims so
        their guests satisfy your Conditional Access without re-registering. This is a CHANGE script: it
        runs in -WhatIf (preview) mode BY DEFAULT and only writes when you pass -WhatIf:$false. It never
        touches the DEFAULT policy and never trusts unknown tenants — trust is scoped to the partner you
        name. Apply trust ONLY for a partner whose posture you have vetted.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\ENTB2B-Set-CrossTenantAccess.ps1 `
                               -PartnerTenantId "<partner-guid>" -TrustPartnerMfa -TrustCompliantDevice
        Apply:             add -WhatIf:$false to the same command after reviewing the preview.
        Connects to Microsoft Graph with change scope: Policy.ReadWrite.CrossTenantAccess.
    EXPECTED RESULTS
        In preview: prints the partner entry and trust changes it WOULD make. On apply: creates the partner
        entry if missing and sets the requested inbound trust flags. Re-run ENTB2B-Validate.ps1 afterward.
.NOTES
    White-label. Change script — default -WhatIf. Scopes trust to a named, vetted partner only.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$PartnerTenantId,
    [switch]$TrustPartnerMfa,
    [switch]$TrustCompliantDevice,
    [switch]$TrustHybridJoinedDevice
)
# Default to preview unless the caller explicitly turns -WhatIf off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.ReadWrite.CrossTenantAccess' -NoWelcome

Write-Host "`n=== ENTB2B — configure cross-tenant access for partner $PartnerTenantId ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf). No changes will be written. Add -WhatIf:`$false to apply." -ForegroundColor Yellow }

# 1) Ensure the partner (organizational) entry exists
$existing = $null
try { $existing = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/partners').value) | Where-Object { $_.tenantId -eq $PartnerTenantId } | Select-Object -First 1 } catch {}

if (-not $existing) {
    if ($PSCmdlet.ShouldProcess("partner $PartnerTenantId", "Create organizational cross-tenant access entry")) {
        Invoke-MgGraphRequest -Method POST -Uri '/v1.0/policies/crossTenantAccessPolicy/partners' -Body (@{ tenantId = $PartnerTenantId } | ConvertTo-Json) | Out-Null
        Write-Host "  CREATED partner entry $PartnerTenantId" -ForegroundColor Green
    } else { Write-Host "  WHATIF would CREATE partner entry $PartnerTenantId" -ForegroundColor Yellow }
} else { Write-Host "  Partner entry already exists." -ForegroundColor DarkGray }

# 2) Set inbound trust flags (scoped to THIS partner only)
$inboundTrust = @{}
if ($TrustPartnerMfa)         { $inboundTrust.isMfaAccepted = $true }
if ($TrustCompliantDevice)    { $inboundTrust.isCompliantDeviceAccepted = $true }
if ($TrustHybridJoinedDevice) { $inboundTrust.isHybridAzureADJoinedDeviceAccepted = $true }

if ($inboundTrust.Count -gt 0) {
    $body = @{ inboundTrust = $inboundTrust } | ConvertTo-Json -Depth 5
    if ($PSCmdlet.ShouldProcess("partner $PartnerTenantId", "Set inbound trust: $($inboundTrust.Keys -join ', ')")) {
        Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/policies/crossTenantAccessPolicy/partners/$PartnerTenantId" -Body $body | Out-Null
        Write-Host "  SET inbound trust: $($inboundTrust.Keys -join ', ')" -ForegroundColor Green
    } else { Write-Host "  WHATIF would SET inbound trust: $($inboundTrust.Keys -join ', ')" -ForegroundColor Yellow }
} else { Write-Host "  No trust flags requested (collaboration allowed without trusting partner claims)." -ForegroundColor DarkGray }

Write-Host "`nRe-run ENTB2B-Validate.ps1 to confirm." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
