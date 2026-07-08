<#
.SYNOPSIS
    OPSAUTO-Health.ps1 — Purview automation readiness / scope helper (read-only).
.DESCRIPTION
    PURPOSE
        Reports whether the workstation and account are ready to run the Purview automation framework, with
        no changes: ExchangeOnlineManagement / Microsoft.Graph module presence + versions, Security &
        Compliance PowerShell (Connect-IPPSSession) and Graph reachability, a per-policy-type READ
        permission probe (DLP / sensitivity labels / retention), and whether an E5 / E5-Compliance-bearing
        plan is present. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSAUTO-Health.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and, for the licensing section,
        Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All. Interactive modern-auth /
        MFA sign-in; no secrets in code.
    EXPECTED RESULTS
        A readiness summary: modules present Y/N + version, IPPS + Graph reachable Y/N, each policy type
        readable Y/N, and an E5/E5-Compliance plan present Y/N. Any licensing/tenant-dependent item is
        flagged "verify your licensing/tenant", not asserted. Green across the board = ready to run
        Discovery/Deploy.
.NOTES
    Purview category — Automation Framework. Read-only. Feature/parameter availability is licensing-/tenant-
    dependent and evolving; confirm against your entitlements and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,     # optional admin UPN passed to Connect-* prompts
    [switch]$SkipGraphLicensing     # skip the Graph licensing section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  [PASS] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [CHECK] $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "  [FAIL] $m" -ForegroundColor Red }

Write-Section "PowerShell modules"
foreach ($m in 'ExchangeOnlineManagement','Microsoft.Graph') {
    $mod = Get-Module -ListAvailable -Name $m | Sort-Object Version -Descending | Select-Object -First 1
    if ($mod) { Ok ("{0} present (v{1})" -f $m, $mod.Version) }
    else { Fail ("{0} NOT installed. Install-Module {0} -Scope CurrentUser" -f $m) }
}

Write-Section "Security & Compliance PowerShell connectivity"
$ippsReady = $false
if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $cp = @{ ShowBanner = $false }
    if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
    try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; $ippsReady = $true; Ok "Connect-IPPSSession succeeded." }
    catch { Fail "Connect-IPPSSession failed: $($_.Exception.Message)" }
}

if ($ippsReady) {
    Write-Section "Per-policy-type READ permission probe"
    # Each probe is a benign, bounded read. A permissions error means the account lacks the view role for that type.
    $probes = @(
        @{ Name = 'DLP policies';        Cmd = { Get-DlpCompliancePolicy -ErrorAction Stop | Select-Object -First 1 } },
        @{ Name = 'Sensitivity labels';  Cmd = { Get-Label -ErrorAction Stop | Select-Object -First 1 } },
        @{ Name = 'Label policies';      Cmd = { Get-LabelPolicy -ErrorAction Stop | Select-Object -First 1 } },
        @{ Name = 'Retention policies';  Cmd = { Get-RetentionCompliancePolicy -ErrorAction Stop | Select-Object -First 1 } }
    )
    foreach ($p in $probes) {
        try { $null = & $p.Cmd; Ok ("Readable: {0}" -f $p.Name) }
        catch { Warn ("Cannot read {0} — check the least-privilege role for this type (Requirement 2.2): {1}" -f $p.Name, $_.Exception.Message) }
    }
}

if (-not $SkipGraphLicensing) {
    Write-Section "Licensing (Microsoft Graph — verify your tenant)"
    if (Get-Module -ListAvailable -Name Microsoft.Graph) {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop
            $skus = Get-MgSubscribedSku -All -ErrorAction Stop
            # SkuPartNumbers are indicative only; plan naming varies by tenant/agreement — verify your licensing.
            $e5Like = $skus | Where-Object { $_.SkuPartNumber -match 'ENTERPRISEPREMIUM|SPE_E5|Microsoft_365_E5|INFORMATION_PROTECTION_COMPLIANCE|IDENTITY_THREAT_PROTECTION' }
            if ($e5Like) {
                Ok ("An E5 / E5-Compliance-bearing plan appears present: {0}. VERIFY the specific capabilities in your tenant." -f (($e5Like.SkuPartNumber) -join ', '))
            } else {
                Warn "No obvious E5 / E5-Compliance plan detected by SKU name. Advanced DLP / auto-labeling / some retention features may be unavailable — verify your licensing/tenant."
            }
        } catch { Warn "Graph licensing read skipped/failed: $($_.Exception.Message)" }
    } else { Warn "Microsoft.Graph not installed — skipping licensing check." }
}

Write-Section "Summary"
Write-Host "  Resolve any [FAIL] before running OPSAUTO-Deploy.ps1. [CHECK] items are licensing-/role-/tenant-dependent — verify in your tenant." -ForegroundColor Gray
