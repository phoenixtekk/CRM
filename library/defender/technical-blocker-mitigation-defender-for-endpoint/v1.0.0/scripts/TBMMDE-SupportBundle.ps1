<#
.SYNOPSIS
    TBMMDE-SupportBundle.ps1 — read-only assembly of a support-ready diagnostic bundle for a
    Defender for Endpoint blocker that survives a correct fix.
.DESCRIPTION
    PURPOSE
        Read-only packaging for the "Technical Blocker Mitigation — Defender for Endpoint" solution.
        When discovery, connectivity, and the documented fix all check out but the blocker persists
        (likely a Microsoft service issue), this assembles the bundle
        'MDE Support Bundle - <case> - Escalate': the discovery snapshot, the connectivity results,
        the affected device IDs/names, tenant context, and timestamps — everything to attach to a
        support case. Makes NO changes to the tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDE-SupportBundle.ps1 -Case "MSCASE-12345"
        Point it at the artifacts you already produced:
        .\TBMMDE-SupportBundle.ps1 -Case "MSCASE-12345" -Discovery .\MDE-blocker-discovery.json -Connectivity .\MDE-connectivity.json
        Requires Microsoft.Graph.Authentication for the tenant/context stamp only (read scopes).
    EXPECTED RESULTS
        A single folder 'MDE-Support-Bundle-<case>' containing a manifest and copies of the read-only
        artifacts. ALSO run the Microsoft Defender client analyzer ON the affected device and add its
        output ZIP to the folder — that is the on-device half Microsoft support asks for.
.NOTES
    White-label. Read-only — collects existing read-only artifacts; changes nothing.
    Do not place the bundle in shared/unsecured storage; it contains tenant/device identifiers.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Case,
    [string]$Discovery = ".\MDE-blocker-discovery.json",
    [string]$Connectivity = ".\MDE-connectivity.json",
    [string]$Report = ".\MDE-blocker-report.json"
)

$safeCase = ($Case -replace '[^A-Za-z0-9._-]','_')
$dir = ".\MDE-Support-Bundle-$safeCase"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "`n=== TBMMDE — support bundle assembly (read-only) ===" -ForegroundColor Cyan
Write-Host ("Bundle: {0}" -f $dir)

$tenant = $null; $account = $null
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome | Out-Null }
    $ctx = Get-MgContext; $tenant = $ctx.TenantId; $account = $ctx.Account
} catch { Write-Host "   (context stamp skipped — Graph not connected)" -ForegroundColor DarkGray }

$included = @()
foreach ($f in @($Discovery,$Connectivity,$Report)) {
    if ($f -and (Test-Path $f)) { Copy-Item $f -Destination $dir -Force; $included += (Split-Path $f -Leaf); Write-Host ("   + {0}" -f (Split-Path $f -Leaf)) -ForegroundColor Green }
    else { Write-Host ("   - {0} (missing — generate it first)" -f $f) -ForegroundColor Yellow }
}

$manifest = [ordered]@{
    Case = $Case
    GeneratedAt = (Get-Date).ToString('s')
    TenantId = $tenant
    Account = $account
    IncludedArtifacts = $included
    ManualStepsForSupport = @(
        "Run the Microsoft Defender client analyzer ON an affected device and add its output ZIP to this folder.",
        "Confirm plan assigned + service activated (see discovery snapshot).",
        "Confirm connectivity clean (see connectivity JSON).",
        "Confirm the documented fix was applied and warm-up time elapsed.",
        "Attach this whole folder to the Microsoft support case."
    )
    EscalationCriteria = "Plan assigned, service activated, connector Enabled, policy assigned, endpoints reachable, correct fix applied + warm-up elapsed, blocker persists => service-side issue."
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $dir "manifest.json") -Encoding UTF8

Write-Host "`nBundle assembled (read-only). Add the on-device client-analyzer ZIP, then attach the folder to the case." -ForegroundColor Green
Write-Host "Escalation decision and any incident-response actions remain the SOC/security team's." -ForegroundColor DarkGray
