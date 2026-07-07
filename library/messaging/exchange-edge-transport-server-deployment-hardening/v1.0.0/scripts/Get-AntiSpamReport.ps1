<#
.SYNOPSIS
  Read-only anti-spam / connection-filter posture report for the Edge Transport server.
.DESCRIPTION
  Reports the perimeter hygiene posture: installed/enabled transport (anti-spam) agents and their
  priority, IP Allow/Block lists and any IP Block List providers, and the Content/Sender/Recipient
  filtering configuration where those cmdlets are available. Read-only: it changes nothing.
  Run in the Exchange Management Shell ON THE EDGE server (anti-spam agents live on the Edge).
  Optionally writes a CSV/JSON snapshot for change-tracking.
.EXAMPLE
  .\Get-AntiSpamReport.ps1
  # Console report of agents, IP allow/block lists, and filtering config on the Edge.
.EXAMPLE
  .\Get-AntiSpamReport.ps1 -ExportPath .\edge-hygiene-baseline.json
  # Also save a JSON snapshot of the 'Hygiene - Edge Baseline - Prod' posture.
  (Exchange Management Shell on the Edge Transport server.)
.NOTES
  Expected results: a posture report matching your designed 'Hygiene - Edge Baseline - Prod'. Flag any
  agent unexpectedly enabled/disabled or any over-broad block that could drop legitimate mail.
  The exact anti-spam agent set is version-dependent — verify for your Exchange version/CU.
#>
[CmdletBinding()]
param(
    [string]$ExportPath
)

if (-not (Get-Command Get-TransportAgent -ErrorAction SilentlyContinue)) {
    Write-Error 'Exchange Management Shell not detected. Run this on the Edge Transport server.'
    return
}

$snapshot = [ordered]@{}

Write-Host 'Anti-spam / connection-filter posture (read-only)`n' -ForegroundColor Cyan

# --- Transport (anti-spam) agents ---
Write-Host '== Transport agents ==' -ForegroundColor Cyan
try {
    $agents = Get-TransportAgent -ErrorAction Stop
    $agents | Format-Table Identity, Enabled, Priority -AutoSize
    $snapshot.Agents = $agents | Select-Object Identity, Enabled, Priority
    $disabled = $agents | Where-Object { -not $_.Enabled }
    if ($disabled) { Write-Host ("Note: {0} agent(s) disabled — confirm this matches design." -f $disabled.Count) -ForegroundColor Yellow }
} catch { Write-Warning "Get-TransportAgent: $($_.Exception.Message)" }

# --- Connection filtering: IP Allow / Block lists + providers ---
Write-Host "`n== IP Allow list ==" -ForegroundColor Cyan
try { $allow = Get-IPAllowListEntry -ErrorAction Stop; $allow | Format-Table Identity, IPRange -AutoSize; $snapshot.IPAllow = $allow | Select-Object Identity, IPRange }
catch { Write-Host '  (Get-IPAllowListEntry unavailable — verify Connection Filtering agent is installed for your version.)' -ForegroundColor DarkGray }

Write-Host '== IP Block list ==' -ForegroundColor Cyan
try {
    $block = Get-IPBlockListEntry -ErrorAction Stop
    $block | Format-Table Identity, IPRange -AutoSize
    $snapshot.IPBlock = $block | Select-Object Identity, IPRange
    $broad = $block | Where-Object { "$($_.IPRange)" -match '/(0|8|1[0-6])$' }
    if ($broad) { Write-Host '  WARNING: broad CIDR block(s) detected — confirm they will not drop legitimate mail.' -ForegroundColor Red }
} catch { Write-Host '  (Get-IPBlockListEntry unavailable for this version.)' -ForegroundColor DarkGray }

Write-Host '== IP Block List providers ==' -ForegroundColor Cyan
try { $prov = Get-IPBlockListProvider -ErrorAction Stop; $prov | Format-Table Name, Enabled, LookupDomain -AutoSize; $snapshot.Providers = $prov | Select-Object Name, Enabled, LookupDomain }
catch { Write-Host '  (No providers cmdlet / none configured.)' -ForegroundColor DarkGray }

# --- Filtering configs (best-effort; cmdlet availability is version-dependent) ---
Write-Host "`n== Filtering configuration ==" -ForegroundColor Cyan
foreach ($cfg in 'ContentFilterConfig','SenderFilterConfig','RecipientFilterConfig','SenderIDConfig','SenderReputationConfig') {
    $cmd = "Get-$cfg"
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        try {
            $obj = & $cmd -ErrorAction Stop
            Write-Host ("  {0}: Enabled={1}" -f $cfg, $obj.Enabled) -ForegroundColor Gray
            $snapshot[$cfg] = ($obj | Select-Object -Property * -First 1)
            if ($cfg -eq 'RecipientFilterConfig' -and $obj.RecipientValidationEnabled) {
                Write-Host '    WARNING: Recipient validation/tarpitting on — ensure design accounts for valid-address disclosure.' -ForegroundColor Red
            }
        } catch { Write-Host "  ${cfg}: (query failed) $($_.Exception.Message)" -ForegroundColor DarkGray }
    } else {
        Write-Host "  ${cfg}: cmdlet not available (verify agent installed for your version)." -ForegroundColor DarkGray
    }
}

if ($ExportPath) {
    try {
        $snapshot | ConvertTo-Json -Depth 5 | Out-File -FilePath $ExportPath -Encoding UTF8
        Write-Host "`nSnapshot written to $ExportPath (Hygiene - Edge Baseline - Prod)." -ForegroundColor Green
    } catch { Write-Warning "Export failed: $($_.Exception.Message)" }
}

Write-Host "`nCompare against your designed 'Hygiene - Edge Baseline - Prod'. In a hybrid, keep Edge hygiene narrow and let EOP do content/anti-phish. Verify the agent set for your Exchange version/CU." -ForegroundColor DarkGray
