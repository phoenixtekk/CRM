<#
.SYNOPSIS
    MDEPROXY-Report.ps1 — compiles the read-only telemetry-impact assessment report from the saved
    measurement outputs (obfuscation baseline + feature enumeration).
.DESCRIPTION
    PURPOSE
        Assembles 'MDEPROXY Assessment Report - Tenant - Validate' — the measurement summary
        (obfuscation %, completeness, table population), the feature-impact matrix scaffold (with the
        'Confirm with Microsoft' column left OPEN), the XFF clarification, and the open questions for
        the Microsoft advisory case. It only READS the JSON that MDEPROXY-Validate.ps1 and
        MDEPROXY-FeatureImpact.ps1 produced — it queries nothing and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEPROXY-Report.ps1 `
          -BaselinePath .\MDEPROXY-telemetry-baseline.json `
          -FeaturePath  .\MDEPROXY-feature-impact.json
        Writes a Markdown report (and a JSON sidecar). No tenant connection required.
    EXPECTED RESULTS
        MDEPROXY-assessment-report.md — a decision-ready evidence package that keeps every
        Microsoft-authoritative item as an OPEN question for the advisory case (never invented).
.NOTES
    White-label. Read-only (reads local JSON only). Keeps the 'Confirm with Microsoft' framing intact.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath = ".\MDEPROXY-telemetry-baseline.json",
    [string]$FeaturePath  = ".\MDEPROXY-feature-impact.json",
    [string]$OutputPath   = ".\MDEPROXY-assessment-report.md"
)

function Read-JsonSafe([string]$p) {
    if (Test-Path $p) { try { return (Get-Content $p -Raw | ConvertFrom-Json) } catch { Write-Host "   Could not parse $p" -ForegroundColor Yellow } }
    else { Write-Host "   Not found: $p (run the measurement first)" -ForegroundColor Yellow }
    return $null
}

Write-Host "`n=== MDEPROXY — assessment report compiler (read-only) ===" -ForegroundColor Cyan
$base = Read-JsonSafe $BaselinePath
$feat = Read-JsonSafe $FeaturePath

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("# MDEPROXY Assessment Report — Tenant — Validate")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("_Read-only telemetry-impact assessment. Nothing in this engagement changed the proxy, the SWG agent, the endpoints, or the tenant._")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("- Generated: $((Get-Date).ToString('u'))")
if ($base) {
    $null = $sb.AppendLine("- Window: last $($base.WindowDays) day(s)")
    $null = $sb.AppendLine("- Sample: $((@($base.Sample)) -join ', ')")
    $null = $sb.AppendLine("- Proxy address set (classification basis — review): $((@($base.ProxyAddressSet)) -join ', ')")
}
$null = $sb.AppendLine("")

$null = $sb.AppendLine("## 1. Measurement summary (observed in this tenant)")
if ($base -and $base.Obfuscation) {
    $o = $base.Obfuscation
    $null = $sb.AppendLine("- Total outbound connections sampled: **$($o.Total)**")
    $null = $sb.AppendLine("- Obscured to proxy/loopback: **$($o.Obscured) ($($o.ObscuredPct)%)**")
    $null = $sb.AppendLine("- Recorded as true remote: **$($o.TrueRemote)**")
    $null = $sb.AppendLine("- Missing RemoteUrl: **$($o.MissingRemoteUrl) ($($o.MissingUrlPct)%)**")
    if ([double]$o.ObscuredPct -eq 0) { $null = $sb.AppendLine("- _Finding: no obfuscation observed for this sample/window — a valid result, report as-is._") }
} else { $null = $sb.AppendLine("- _No obfuscation measurement found — run MDEPROXY-Validate.ps1 first._") }
$null = $sb.AppendLine("")
if ($base -and $base.Completeness) {
    $null = $sb.AppendLine("### DeviceNetworkEvents completeness (per device)")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("| Device | Net events | Proc events | Net/Proc ratio |")
    $null = $sb.AppendLine("|---|---|---|---|")
    foreach ($c in $base.Completeness) { $null = $sb.AppendLine("| $($c.DeviceName) | $($c.NetEvents) | $($c.ProcEvents) | $($c.NetToProcRatio) |") }
    $null = $sb.AppendLine("")
}

$null = $sb.AppendLine("## 2. Feature-impact matrix (Confirm-with-Microsoft column stays OPEN)")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| Feature / signal | True-remote dependent? | Observed effect (this tenant) | Confirm with Microsoft |")
$null = $sb.AppendLine("|---|---|---|---|")
$obsCell = if ($base -and $base.Obfuscation) { "$($base.Obfuscation.ObscuredPct)% obscured; $($base.Obfuscation.MissingRemoteUrl) missing RemoteUrl" } else { "run measurement" }
$null = $sb.AppendLine("| DeviceNetworkEvents (RemoteIP/RemoteUrl/RemotePort) | Yes — directly | $obsCell | Authoritative RemoteIP/RemoteUrl semantics with a local proxy |")
$detCell = if ($feat -and $feat.ExposedDetectionRules) { "$(@($feat.ExposedDetectionRules).Count) custom detection(s) pivot on remote dest" } else { "review custom detections manually" }
$null = $sb.AppendLine("| Hunts / custom detections on remote destination | Yes — inherited | $detCell | Which built-in detections read endpoint remote-destination |")
$null = $sb.AppendLine("| SmartScreen (URL/download reputation) | Reputation on destination | Config state recorded (portal) | **OPEN** — does loopback-forward steering change SmartScreen evaluation? |")
$null = $sb.AppendLine("| Network Protection (IP/URL/domain block, web filter, indicators) | Yes — evaluates destination | Config + indicator inventory recorded | **OPEN** — does NP evaluate true remote or loopback under this topology? |")
$tiCell = if ($feat -and $feat.NetworkIndicatorCount) { "$($feat.NetworkIndicatorCount) IP/URL/domain indicator(s) may not match" } else { "inventory IP/URL/domain indicators" }
$null = $sb.AppendLine("| Threat-intelligence indicator matching (IP/URL/domain) | Yes — endpoint-layer match | $tiCell | **OPEN** — endpoint-layer TI matching behavior with a local proxy |")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("> The **Observed effect** column is measured. The **Confirm with Microsoft** column is the open question carried into the advisory case — **do not invent Microsoft's answer**; fill it only when the case returns.")
$null = $sb.AppendLine("")

$null = $sb.AppendLine("## 3. X-Forwarded-For (XFF) clarification")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("XFF is a **server-side HTTP request header**: a proxy adds it so the **destination server** learns the original client IP. It flows forward (proxy -> server) and aids **server-side** attribution — the destination's logs, a WAF, and the SWG's own logs. It is carried **inside the outbound request**, not fed back into the endpoint's network-stack records.")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("Because of that direction, XFF is **not expected to repopulate the true remote destination into the endpoint's DeviceNetworkEvents** (RemoteIP/RemoteUrl): it helps the *server* know the *client*, not the *endpoint* record the *true server*. **This is our reasoning about the mechanism, not Microsoft's definitive statement — confirm the current behavior with Microsoft (advisory ask #3). Do not present it as Microsoft-confirmed until the case returns.**")
$null = $sb.AppendLine("")

$null = $sb.AppendLine("## 4. Open questions for the Microsoft advisory case (Severity C)")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("1. **Validate telemetry impact** — which tables/fields are affected by loopback-forward steering, and is it expected?")
$null = $sb.AppendLine("2. **Document feature impact** — SmartScreen / Network Protection / TI matching under this topology (true remote vs loopback?).")
$null = $sb.AppendLine("3. **XFF applicability** — does XFF (or any mechanism) restore true remote into endpoint telemetry, or is it server-side only?")
$null = $sb.AppendLine("4. **Architecture review** — the supported MDE + SWG coexistence topology (modes / exclusions / connector).")
$null = $sb.AppendLine("5. **Advanced-hunting schema** — authoritative RemoteIP/RemoteUrl semantics with a local proxy present.")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("_Remediation options are documented separately in 'MDEPROXY Remediation Plan - Tenant - Expand' — a plan for the customer's network/security/architecture owners, every option flagged 'verify against current Microsoft guidance'. Nothing was applied by this assessment._")

Set-Content -Path $OutputPath -Value $sb.ToString() -Encoding UTF8
$sidecar = [ordered]@{ Timestamp=(Get-Date).ToString('s'); ReadOnly=$true; Baseline=$base; Feature=$feat }
$sidecar | ConvertTo-Json -Depth 8 | Set-Content -Path ($OutputPath -replace '\.md$','.json') -Encoding UTF8

Write-Host ("`nReport compiled (read-only): {0}" -f $OutputPath) -ForegroundColor Green
Write-Host  "Keep the 'Confirm with Microsoft' cells OPEN until the advisory case returns." -ForegroundColor DarkGray
