<#
.SYNOPSIS
    TBMMDC-Discovery.ps1 — read-only signal-chain snapshot to pinpoint a stalled Defender for Cloud
    rollout's blocker.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Technical Blocker Mitigation — Defender for Cloud" solution.
        For each subscription in scope, captures the signal chain: Defender plan states
        (Get-AzSecurityPricing = On/Free per plan), auto-provisioning/agent settings, AWS/GCP security
        connectors and their status (ARM REST), and whether the Microsoft cloud security benchmark
        policy is assigned with assessments present. Makes NO changes.
    HOW TO RUN
        Connect-AzAccount ; then:
        powershell -ExecutionPolicy Bypass -File .\TBMMDC-Discovery.ps1 -SubscriptionIds "sub1,sub2"
        (Omit -SubscriptionIds to use the current context subscription.)
        Requires Az.Accounts, Az.Security, Az.Resources. Read-only (Security Reader / Reader).
    EXPECTED RESULTS
        A JSON snapshot (MDC-blocker-discovery.json) plus a console summary. Read it top-down against
        the signal chain; the earliest broken link is the blocker.
.NOTES
    White-label. Read-only. Uses Get-* / ARM GET only; changes no plan, agent, connector, or policy.
    Plan names/pricing evolve — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionIds = "",
    [string]$OutputPath = ".\MDC-blocker-discovery.json"
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Write-Host "Installing $m (one-time)..." -ForegroundColor Yellow; Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$subs = if ($SubscriptionIds) { $SubscriptionIds.Split(',') | ForEach-Object { $_.Trim() } } else { @((Get-AzContext).Subscription.Id) }

Write-Host "`n=== TBMMDC — Defender for Cloud blocker discovery (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp=(Get-Date).ToString('s'); Subscriptions=@() }

foreach ($sid in $subs) {
    Write-Host ("`n### Subscription: {0}" -f $sid) -ForegroundColor Cyan
    try { Set-AzContext -Subscription $sid -ErrorAction Stop | Out-Null } catch { Write-Host ("   Cannot set context: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; continue }
    $subOut = [ordered]@{ SubscriptionId=$sid }

    # --- Link 1: Defender plan states ---
    Write-Host "-- Link 1: Defender plan states --" -ForegroundColor Cyan
    try {
        $pricing = Get-AzSecurityPricing -ErrorAction Stop
        $plans = @()
        foreach ($p in $pricing) {
            $color = if ($p.PricingTier -eq 'Standard') { 'Green' } else { 'Yellow' }
            Write-Host ("   {0,-24} {1}" -f $p.Name, $p.PricingTier) -ForegroundColor $color
            $plans += @{ Name=$p.Name; Tier="$($p.PricingTier)" }
        }
        $subOut.Plans = $plans
    } catch { Write-Host ("   Could not read pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # --- Link 2: auto-provisioning / agent ---
    Write-Host "-- Link 2: auto-provisioning (agent) --" -ForegroundColor Cyan
    try {
        $ap = Get-AzSecurityAutoProvisioningSetting -ErrorAction SilentlyContinue
        $ap | ForEach-Object { Write-Host ("   {0}: {1}" -f $_.Name, $_.AutoProvision) }
        $subOut.AutoProvisioning = @($ap | ForEach-Object { @{ Name=$_.Name; AutoProvision="$($_.AutoProvision)" } })
    } catch { Write-Host ("   Could not read auto-provisioning: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # --- Link 3: security connectors (AWS/GCP) via ARM REST ---
    Write-Host "-- Link 3: multicloud security connectors --" -ForegroundColor Cyan
    try {
        $uri = "/subscriptions/$sid/providers/Microsoft.Security/securityConnectors?api-version=2023-10-01-preview"
        $resp = Invoke-AzRestMethod -Method GET -Path $uri -ErrorAction Stop
        $conns = @()
        if ($resp.StatusCode -eq 200) {
            $body = $resp.Content | ConvertFrom-Json
            foreach ($c in $body.value) {
                $env = $c.properties.environmentName
                Write-Host ("   {0,-30} cloud={1}" -f $c.name, $env) -ForegroundColor Green
                $conns += @{ Name=$c.name; Cloud="$env" }
            }
            if (-not $conns) { Write-Host "   (no AWS/GCP connectors on this subscription)" -ForegroundColor DarkGray }
        } else { Write-Host ("   Connector API returned {0} (verify api-version / permissions)." -f $resp.StatusCode) -ForegroundColor Yellow }
        $subOut.SecurityConnectors = $conns
    } catch { Write-Host ("   Could not read security connectors: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # --- Link 4: benchmark policy assignment + assessments presence ---
    Write-Host "-- Link 4: benchmark policy + assessments --" -ForegroundColor Cyan
    try {
        $assign = Get-AzPolicyAssignment -Scope "/subscriptions/$sid" -ErrorAction SilentlyContinue |
                  Where-Object { $_.Properties.DisplayName -match 'cloud security benchmark|Azure Security Benchmark|ASC Default|Microsoft cloud security' }
        $hasBench = [bool]$assign
        Write-Host ("   Microsoft cloud security benchmark assigned: {0}" -f $hasBench) -ForegroundColor ($(if($hasBench){'Green'}else{'Yellow'}))
        $assess = Get-AzSecurityAssessment -ErrorAction SilentlyContinue
        $assessCount = ($assess | Measure-Object).Count
        Write-Host ("   Assessments present: {0}" -f $assessCount)
        $subOut.BenchmarkAssigned = $hasBench
        $subOut.AssessmentCount = $assessCount
    } catch { Write-Host ("   Could not read policy/assessments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    $result.Subscriptions += $subOut
}

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Earliest broken link (plan -> coverage -> connector -> policy/assessment) is your blocker." -ForegroundColor Green
