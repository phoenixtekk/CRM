<#
.SYNOPSIS
    IPRMS-Readiness.ps1 — rights-protection readiness/health: RMS activated, super-user set, Exchange IRM enabled, licensing signal, pilot-scope sanity (read-only).
.DESCRIPTION
    A pre-flight and cadence health check for label-based rights protection. It reports PASS/WARN/FAIL for:
    the Rights Management (RMS) service being Activated; a super-user group being configured (required so
    encrypted content is recoverable); Exchange Online IRM being enabled (for Do Not Forward / Encrypt-Only);
    a licensing signal for information protection (from Graph subscribed SKUs); and pilot-scope sanity - a
    protection (encrypting) label left published ONLY to a pilot-named policy after expansion, or configured
    but never published. Read-only - makes no changes.
.EXAMPLE
    .\IPRMS-Readiness.ps1
    Reports RMS activation, super-user, IRM, licensing signal, and pilot-scope sanity.
.EXAMPLE
    .\IPRMS-Readiness.ps1 -PilotPolicyPattern 'Pilot'
    Treats label policies whose name matches 'Pilot' as pilot policies for the stale-pilot check.
.NOTES
    Requires PowerShell 5.1+/7+. Modules: AIPService (Connect-AipService), ExchangeOnlineManagement
    (Connect-IPPSSession), optionally the Exchange Online module (Get-IRMConfiguration) and Microsoft Graph
    (Get-MgSubscribedSku). Role: Information Protection Admin (read) + RMS/Global Admin for AIPService reads.
    Expected results: PASS (green) = RMS Activated, super-user set, IRM enabled, licensing signal present,
    no stale pilot. WARN/FAIL (yellow/red) = a prerequisite missing - resolve before relying on encryption.
    Verify your licensing/tenant where flagged.
#>
[CmdletBinding()]
param(
    [string]$PilotPolicyPattern = 'Pilot'
)

function Say([string]$tag, [string]$name, [string]$col, [string]$detail) {
    Write-Host ("  [{0}] {1} {2}" -f $tag, $name, $detail) -ForegroundColor $col
}

Write-Host "`n=== IPRMS rights-protection readiness (read-only) ===" -ForegroundColor Cyan

# --- 1. RMS activated + super-user ---
Write-Host "`n-- Rights Management service --" -ForegroundColor Cyan
try {
    if (-not (Get-Command Get-AipServiceConfiguration -ErrorAction SilentlyContinue)) { Import-Module AIPService -ErrorAction Stop }
    try { Get-AipServiceConfiguration -ErrorAction Stop | Out-Null } catch { Connect-AipService -ErrorAction Stop | Out-Null }
    $state = "$((Get-AipServiceConfiguration).FunctionalState)"
    if ($state -match 'Activ') { Say 'PASS' 'RMS activated' 'Green' "(state=$state)" }
    else { Say 'FAIL' 'RMS activated' 'Red' "(state=$state - Enable-AipService before configuring encryption)" }

    $su = $null; try { $su = Get-AipServiceSuperUserGroup -ErrorAction SilentlyContinue } catch {}
    if ($su) { Say 'PASS' 'Super-user group set' 'Green' "($su - encrypted content is recoverable)" }
    else { Say 'WARN' 'Super-user group set' 'Yellow' '(none - encrypted content is NOT recoverable; set before broad publish)' }
} catch {
    Say 'SKIP' 'RMS state' 'Yellow' "(AIPService not available - $($_.Exception.Message). Verify RMS in the M365 admin center.)"
}

# --- 2. Exchange IRM ---
Write-Host "`n-- Exchange Online IRM (for DNF / Encrypt-Only) --" -ForegroundColor Cyan
try {
    if (Get-Command Get-IRMConfiguration -ErrorAction SilentlyContinue) {
        $irm = Get-IRMConfiguration -ErrorAction Stop
        $ok = [bool]$irm.AzureRMSLicensingEnabled -or [bool]$irm.InternalLicensingEnabled
        if ($ok) { Say 'PASS' 'IRM enabled' 'Green' "(AzureRMSLicensingEnabled=$($irm.AzureRMSLicensingEnabled))" }
        else { Say 'WARN' 'IRM enabled' 'Yellow' '(IRM licensing not enabled - DNF/Encrypt-Only in Outlook will not work)' }
    } else {
        Say 'SKIP' 'IRM check' 'Yellow' '(Get-IRMConfiguration not in session - connect the Exchange Online module to verify)'
    }
} catch { Say 'SKIP' 'IRM check' 'Yellow' "($($_.Exception.Message))" }

# --- 3. Licensing signal (Graph) ---
Write-Host "`n-- Licensing signal --" -ForegroundColor Cyan
try {
    if (-not (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue)) { Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop }
    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) { Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop }
    $plans = @()
    foreach ($s in (Get-MgSubscribedSku -ErrorAction Stop)) { foreach ($p in $s.ServicePlans) { $plans += "$($p.ServicePlanName)" } }
    $signals = $plans | Where-Object { $_ -match 'RMS_S_ENTERPRISE|RMS_S_PREMIUM|INFORMATION_PROTECTION|MIP_S_CLP|E5' } | Sort-Object -Unique
    if ($signals) { Say 'PASS' 'Information-protection licensing signal' 'Green' "(plans: $((@($signals) | Select-Object -First 5) -join ', ')…)" }
    else { Say 'WARN' 'Information-protection licensing signal' 'Yellow' '(no obvious RMS/MIP plan matched - VERIFY YOUR LICENSING/TENANT)' }
} catch {
    Say 'SKIP' 'Licensing signal' 'Yellow' "(Graph not available - verify AIP/MIP entitlement in the M365 admin center)"
}

# --- 4. Pilot-scope sanity: encrypting label only in a pilot policy, or configured-but-unpublished ---
Write-Host "`n-- Pilot-scope sanity --" -ForegroundColor Cyan
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null }
    $encLabels = @(Get-Label -ErrorAction Stop | Where-Object { $_.EncryptionEnabled -eq $true })
    $policies  = @(Get-LabelPolicy -ErrorAction Stop)

    # Map label -> policies that publish it (ScopedLabels holds label GUIDs/names depending on tenant/version).
    $issues = 0
    foreach ($l in $encLabels) {
        $inPolicies = @($policies | Where-Object {
            ($_.ScopedLabels -join ';') -match [regex]::Escape($l.Guid) -or ($_.ScopedLabels -join ';') -match [regex]::Escape($l.Name)
        })
        if ($inPolicies.Count -eq 0) {
            Say 'WARN' "Label '$($l.DisplayName)'" 'Yellow' '(encryption configured but not published in any policy - verify intended)'
            $issues++
        } else {
            $nonPilot = @($inPolicies | Where-Object { $_.Name -notmatch $PilotPolicyPattern })
            if ($nonPilot.Count -eq 0) {
                Say 'WARN' "Label '$($l.DisplayName)'" 'Yellow' "(published ONLY to pilot-named policy - confirm expansion to a broad policy)"
                $issues++
            } else {
                Say 'PASS' "Label '$($l.DisplayName)'" 'Green' "(published in $($inPolicies.Count) policy(ies), incl. non-pilot)"
            }
        }
    }
    if ($encLabels.Count -eq 0) { Say 'INFO' 'Encrypting labels' 'Gray' '(none configured yet)' }
    Write-Host ("`n  Pilot-scope items to review: {0}" -f $issues) -ForegroundColor $(if ($issues -eq 0) { 'Green' } else { 'Yellow' })
} catch {
    Say 'SKIP' 'Pilot-scope check' 'Yellow' "($($_.Exception.Message))"
}

Write-Host "`n=== Readiness summary ===" -ForegroundColor Cyan
Write-Host "Encryption is safe to rely on only when: RMS is Activated, a super-user group is set, IRM is" -ForegroundColor Gray
Write-Host "enabled for the workloads you use, and no protection label is stranded in a pilot policy." -ForegroundColor Gray
