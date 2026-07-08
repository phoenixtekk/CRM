<#
.SYNOPSIS
    IPTAX-ScopeHealth.ps1 — preview publish scope + group membership, confirm the protection service, surface orphaned policies / label sprawl (read-only).
.DESCRIPTION
    PURPOSE
        Pre-publish/health helper. Reports each sensitivity-label policy and the labels it publishes; checks
        a named pilot/broad group's membership so you publish to the intended scope; confirms the protection
        (Azure Rights Management) service is active for encrypting labels; and surfaces health issues —
        policies that publish no labels (orphaned) and labels in no policy (sprawl / never surfaced to users).
        Read-only: makes no changes and publishes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPTAX-ScopeHealth.ps1
        powershell -ExecutionPolicy Bypass -File .\IPTAX-ScopeHealth.ps1 -Group grp-purview-pilot@contoso.com
        Requires ExchangeOnlineManagement (Connect-IPPSSession); -Group membership + protection-service check
        also use Connect-ExchangeOnline. PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        Per policy: enabled state + labels published; the named group's member count; protection-service
        state (or "verify your licensing/tenant"); and lists of orphaned policies and unpublished (sprawl)
        labels. Resolve orphans/sprawl and confirm scope before broad publish.
.NOTES
    Purview — Sensitivity Label Taxonomy Design. Read-only. The protection-service and group checks are
    licensing-/tenant-dependent — items that cannot be confirmed are flagged "verify your licensing/tenant".
#>
[CmdletBinding()]
param(
    [string]$Group,                      # a pilot/broad group to check membership for (e.g. grp-purview-pilot@contoso.com)
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Info($m){ Write-Host "  $m" -ForegroundColor White }

Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession @connectParams | Out-Null }

$labels = @(Get-Label -ErrorAction SilentlyContinue)
$policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)

# --- Policies and the labels they publish ---
Write-Section "Label policies and published labels"
if ($policies.Count -eq 0) { Warn "No label policies exist — nothing is published to users yet." }
$publishedLabelNames = @()
foreach ($p in $policies) {
    $lbls = @($p.Labels)
    $publishedLabelNames += $lbls
    if ($lbls.Count -eq 0) { Warn ("Policy '{0}': publishes NO labels (orphaned) — remove it or attach labels." -f $p.Name) }
    else { Info ("Policy '{0}' (Enabled={1}): {2} label(s) — {3}" -f $p.Name, $p.Enabled, $lbls.Count, ($lbls -join ', ')) }
}
$publishedLabelNames = $publishedLabelNames | Sort-Object -Unique

# --- Label sprawl: labels not in any policy ---
Write-Section "Label sprawl (built but never published)"
$unpublished = @($labels | Where-Object { $publishedLabelNames -notcontains $_.Name -and $publishedLabelNames -notcontains $_.DisplayName })
# Parent grouping labels are intentionally not selectable — note, don't over-flag.
if ($unpublished.Count -eq 0) { Ok "Every label is referenced by at least one policy." }
else {
    Warn ("{0} label(s) are in no policy (unpublished/sprawl — expected for parent groupings, review the rest):" -f $unpublished.Count)
    $unpublished | ForEach-Object { Info ("   - {0} ({1})" -f $_.DisplayName, $_.Name) }
}

# --- Named group membership (scope confirmation) ---
if ($Group) {
    Write-Section "Publish-scope group membership: $Group"
    try {
        Connect-ExchangeOnline @connectParams -ErrorAction Stop
        $members = @()
        try { $members = @(Get-DistributionGroupMember -Identity $Group -ErrorAction Stop) }
        catch {
            try { $members = @(Get-UnifiedGroupLinks -Identity $Group -LinkType Members -ErrorAction Stop) }
            catch { Warn "Could not enumerate '$Group' as a distribution or Microsoft 365 group — verify the group exists and is mail-enabled. $($_.Exception.Message)" }
        }
        if ($members.Count -gt 0) { Ok ("'{0}' has {1} member(s) — confirm this is the intended publish scope." -f $Group, $members.Count) }
    } catch { Warn "Could not connect Exchange Online to read group membership: $($_.Exception.Message)" }
}

# --- Protection (Azure Rights Management) service state ---
Write-Section "Protection service (encrypting labels need it active)"
$hasEncrypting = @($labels | Where-Object { $_.EncryptionEnabled }).Count -gt 0
try {
    Connect-ExchangeOnline @connectParams -ErrorAction Stop | Out-Null
    $irm = Get-IRMConfiguration -ErrorAction Stop
    if ($irm.AzureRMSLicensingEnabled -or $irm.InternalLicensingEnabled) { Ok ("Rights Management appears active (AzureRMSLicensingEnabled={0}, InternalLicensingEnabled={1})." -f $irm.AzureRMSLicensingEnabled, $irm.InternalLicensingEnabled) }
    else { Warn "Rights Management licensing appears OFF — encrypting labels will not protect content until it is enabled. Verify your licensing/tenant." }
} catch {
    Warn "Could not read Get-IRMConfiguration — verify the protection service state in the portal (Rights Management). Verify your licensing/tenant."
}
if ($hasEncrypting) { Info "Encrypting labels exist — the protection service MUST be active before publishing them." }
else { Info "No encrypting labels yet — protection service state is informational until you build one." }

Write-Section "Health summary"
Info "Resolve orphaned policies and unexpected sprawl, confirm the publish-scope group, and confirm the protection service before broad publish."
