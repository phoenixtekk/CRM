<#
.SYNOPSIS
    MDCAFULL-PoC.ps1 — guided, -WhatIf-gated proof-of-concept helper for Microsoft Defender for Cloud
    Apps: enable an audit-mode policy, generate BENIGN test signal, score, and cleanly tear down.
.DESCRIPTION
    PURPOSE
        Phase C of the complete "Microsoft Defender for Cloud Apps" solution. One -Action runs each
        PoC step, pilot-scoped and audit-mode only:
          Enable   — preview readiness (plan/roles/discovery source/pilot group) and guide the
                     audit-mode activity policy 'MDCA PoC Activity Policy - Pilot Users - Audit'
                     scoped to the pilot group. Governance actions = NONE. -WhatIf previews.
          Signal   — guide BENIGN signal: upload Microsoft's SAMPLE Cloud Discovery log and perform
                     benign policy-matching activity as a test account (tag MDCA-PoC-TESTSIGNAL).
                     No real exfiltration, ever.
          Score    — map observations (discovery populated, policy matched, alert surfaced, activity
                     visible) against your criteria.json and write the scorecard.
          Teardown — DESTRUCTIVE: delete the audit policy + discovery report + PoC connector and
                     resolve test alerts. -WhatIf-gated; previews by default.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-PoC.ps1 -Action Enable -WhatIf
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-PoC.ps1 -Action Signal
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-PoC.ps1 -Action Score -CriteriaPath .\criteria.json
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-PoC.ps1 -Action Teardown -WhatIf   # then without -WhatIf
        Requires Microsoft.Graph.Authentication; Security Administrator for Enable/Teardown.
    EXPECTED RESULTS
        A guided, reversible PoC — readiness + audit policy, benign signal, a scorecard file, and a
        clean teardown. No enforcement is ever enabled; the teardown is -WhatIf-gated.
.NOTES
    White-label. Preview-first (-WhatIf) for Enable/Teardown. BENIGN signal only (sample log + benign
    policy-matching activity). Never real exfiltration. Pilot-scoped, audit-mode only.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Enable','Signal','Score','Teardown')] [string]$Action = 'Enable',
    [string]$PilotGroup = 'MDCA Pilot Users - Pilot Ring - Pilot',
    [string]$PolicyName = 'MDCA PoC Activity Policy - Pilot Users - Audit',
    [string]$DiscoveryReport = 'MDCA PoC Discovery - Pilot - Report',
    [string]$Tag = 'MDCA-PoC-TESTSIGNAL',
    [string]$CriteriaPath = '.\criteria.json',
    [string]$OutFile = 'MDCA PoC Scorecard - Pilot Users - Validate.json'
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
function Get-Json($Uri) { try { return Invoke-MgGraphRequest -Method GET -Uri $Uri } catch { return $null } }

switch ($Action) {

'Enable' {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Directory.Read.All' -NoWelcome | Out-Null }
    Write-Host "`n=== POC: pilot enable (preview by default, audit-mode only) ===" -ForegroundColor Cyan
    Write-Host "Pilot group: $PilotGroup" -ForegroundColor Gray
    Write-Host "Policy     : $PolicyName" -ForegroundColor Gray
    Write-Host "`n[1] Readiness (read-only):" -ForegroundColor Cyan
    $grp = Get-Json "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$PilotGroup'"
    if ($grp -and $grp.value.Count -gt 0) { Write-Host "  Pilot group found ($($grp.value[0].id))." -ForegroundColor Green }
    else { Write-Host "  Pilot group '$PilotGroup' NOT found — create it with test users first." -ForegroundColor Yellow }
    Write-Host "  Verify: Defender for Cloud Apps licensed and activated (security.microsoft.com -> Cloud apps)." -ForegroundColor Gray
    Write-Host "  Verify: a discovery source (MDE integration) OR plan to upload Microsoft's sample discovery log." -ForegroundColor Gray
    Write-Host "`n[2] Enable discovery + an AUDIT-mode activity policy (guided, no enforcement):" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess($PolicyName, "Create audit-mode activity policy scoped to $PilotGroup")) {
        Write-Host "  a) Cloud apps -> Cloud discovery -> Settings: confirm a discovery source (or use the sample log)." -ForegroundColor Gray
        Write-Host "  b) Cloud apps -> Policies -> Create policy -> Activity policy:" -ForegroundColor Gray
        Write-Host "       Name = '$PolicyName'; filter scoped to '$PilotGroup'; benign repeatable trigger;" -ForegroundColor Gray
        Write-Host "       Governance actions = NONE (audit only). Do NOT enable blocking or session control." -ForegroundColor Green
    } else {
        Write-Host "  [WhatIf] Would guide creation of the audit-mode policy '$PolicyName' scoped to '$PilotGroup'. No change made." -ForegroundColor Yellow
    }
    Write-Host "`nNext: -Action Signal -> -Action Score. Validate with MDCAFULL-Validate.ps1 -Check PoC." -ForegroundColor Cyan
}

'Signal' {
    Write-Host "`n=== POC: benign test signal ($Tag) ===" -ForegroundColor Cyan
    Write-Host "SAFE ONLY: Microsoft sample discovery log + benign policy-matching activity. No real exfiltration." -ForegroundColor Yellow
    Write-Host "`n[1] Populate Cloud Discovery from Microsoft's SAMPLE log:" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess('Cloud Discovery snapshot report', 'Guide sample-log upload')) {
        Write-Host "  security.microsoft.com -> Cloud apps -> Cloud discovery -> Actions -> Create Cloud Discovery snapshot report." -ForegroundColor Gray
        Write-Host "  Name it '$DiscoveryReport', pick the matching data source, and upload Microsoft's SAMPLE discovery log" -ForegroundColor Gray
        Write-Host "  (documented, benign). This produces a Shadow IT report from safe sample data." -ForegroundColor Green
    } else { Write-Host "  [WhatIf] Would guide the sample-log upload to create the discovery report." -ForegroundColor Yellow }
    Write-Host "`n[2] Perform BENIGN policy-matching activity (as the test account):" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess('audit policy trigger', 'Guide benign policy-matching activity')) {
        Write-Host "  Sign in as a test account in '$PilotGroup' and perform the benign action the audit policy watches for —" -ForegroundColor Gray
        Write-Host "  e.g. download a few NON-SENSITIVE files from a monitored app. Nothing is exfiltrated." -ForegroundColor Green
    } else { Write-Host "  [WhatIf] Would guide benign policy-matching activity by the test account." -ForegroundColor Yellow }
    Write-Host ("`nSignal generated at: {0}  (record this for scorecard latency)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
    Write-Host "Next: validate with MDCAFULL-Validate.ps1 -Check PoC, then -Action Score." -ForegroundColor Cyan
}

'Score' {
    Write-Host "`n=== POC: scorecard ===" -ForegroundColor Cyan
    $criteria = $null
    if (Test-Path $CriteriaPath) { try { $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json } catch {} }
    if (-not $criteria) {
        Write-Host "  No criteria.json found — using the default capability checklist." -ForegroundColor Yellow
        $criteria = [pscustomobject]@{ criteria = @('DiscoveryPopulated','PolicyMatched','AlertSurfaced','ActivityVisible') }
    }
    $items = @()
    foreach ($c in $criteria.criteria) {
        Write-Host ("  [ ] {0} — mark pass/fail from the portal + MDCAFULL-Validate.ps1 -Check PoC observations." -f $c) -ForegroundColor Gray
        $items += [pscustomobject]@{ Criterion = $c; Result = 'REVIEW'; Evidence = '' }
    }
    $card = [ordered]@{ Timestamp = (Get-Date).ToString('s'); Policy = $PolicyName; PilotGroup = $PilotGroup; Items = $items }
    $card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host ("`nScorecard template written: {0}. Fill in Result/Evidence with stakeholders." -f $OutFile) -ForegroundColor Green
}

'Teardown' {
    Write-Host "`n=== POC: teardown (DESTRUCTIVE — -WhatIf-gated) ===" -ForegroundColor Cyan
    Write-Host "Removes the PoC artifacts and rolls the scope back. Preview first; run without -WhatIf to action." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("$PolicyName / $DiscoveryReport / PoC connector / $Tag alerts", 'Delete PoC artifacts and resolve test alerts')) {
        Write-Host "  1) Delete the audit policy '$PolicyName' (Cloud apps -> Policies -> Policy management)." -ForegroundColor Gray
        Write-Host "  2) Delete the discovery report '$DiscoveryReport' (Cloud apps -> Cloud discovery)." -ForegroundColor Gray
        Write-Host "  3) Remove any PoC-only connector; resolve the '$Tag' alerts (Incidents & alerts)." -ForegroundColor Gray
        Write-Host "  4) Optionally remove test users from '$PilotGroup'. Keep the scorecard as the record." -ForegroundColor Green
    } else {
        Write-Host "  [WhatIf] Would delete the audit policy, the discovery report, and the PoC connector, and resolve '$Tag' alerts. No change made." -ForegroundColor Yellow
    }
    Write-Host "`nConfirm removal with MDCAFULL-Validate.ps1 -Check PoC (policy/report should be gone)." -ForegroundColor Cyan
}

}
