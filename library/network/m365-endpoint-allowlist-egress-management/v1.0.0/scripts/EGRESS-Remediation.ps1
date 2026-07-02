<#
.SYNOPSIS
    EGRESS-Remediation.ps1 — generate allow-list update entries (and drift deltas) for import into the proxy/firewall.
.DESCRIPTION
    PURPOSE
        Turns the required-set file (EGRESS-Discovery.ps1) into a human-readable allow-list update
        that you import into your proxy or firewall. If a baseline version is supplied it reports the
        added/removed endpoints (drift delta) instead of the full list. Runs in preview by default and
        writes a proposal file only; it never contacts or changes any proxy/firewall device.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESS-Remediation.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -Format generic
        Preview is the default. Add -Commit only to acknowledge the proposal is final; even with
        -Commit this script only writes the proposal file (the actual device import is vendor-specific).
    EXPECTED RESULTS
        Writes egress-allowlist-update.txt (URLs + IP/CIDR + ports to allow) and prints a summary.
        PASS = proposal file written for review; you then import it into the device per its documentation.
.NOTES
    White-label — the repeatable way. Preview/-WhatIf by default for any change-generating action.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredSetPath,

    [ValidateSet('generic', 'urls', 'cidr')]
    [string]$Format = 'generic',

    [string]$BaselineRequiredSetPath,

    [string]$OutputPath = '.\EGRESS-Output',

    [switch]$Commit
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $RequiredSetPath)) { throw "Required-set file not found: $RequiredSetPath. Run EGRESS-Discovery.ps1 first." }
if (-not (Test-Path -LiteralPath $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# Preview unless -Commit; when -Commit is NOT passed we still write the proposal but label it PREVIEW.
$mode = if ($Commit) { 'COMMIT' } else { 'PREVIEW (-WhatIf default; re-run with -Commit to finalize)' }

$requiredSet = Get-Content -LiteralPath $RequiredSetPath -Raw | ConvertFrom-Json

function Get-AllowEntries {
    param($set)
    # Emit normalized allow entries {kind, value, ports} from a required set object.
    $entries = New-Object System.Collections.Generic.List[object]

    $m365 = $set.m365Endpoints | Where-Object { $_.required -or $_.category -in @('Optimize', 'Allow') }
    foreach ($e in $m365) {
        $ports = if ($e.tcpPorts) { "$($e.tcpPorts)" } else { '443' }
        foreach ($u in $e.urls) { $entries.Add([pscustomobject]@{ kind = 'url';  value = $u; ports = $ports; area = $e.serviceArea; category = $e.category }) }
        foreach ($ip in $e.ips) { $entries.Add([pscustomobject]@{ kind = 'cidr'; value = $ip; ports = $ports; area = $e.serviceArea; category = $e.category }) }
    }
    foreach ($d in $set.deviceManagementEndpoints) {
        $ports = if ($d.tcpPorts) { "$($d.tcpPorts)" } else { '443' }
        foreach ($u in $d.urls) { $entries.Add([pscustomobject]@{ kind = 'url'; value = $u; ports = $ports; area = $d.area; category = 'device-management' }) }
    }
    return $entries
}

$entries = Get-AllowEntries $requiredSet

# --- Drift delta if a baseline required set is provided ----------------------
$deltaMode = $false
$added = @(); $removed = @()
if ($BaselineRequiredSetPath -and (Test-Path -LiteralPath $BaselineRequiredSetPath)) {
    $deltaMode = $true
    $baselineSet = Get-Content -LiteralPath $BaselineRequiredSetPath -Raw | ConvertFrom-Json
    $baselineEntries = Get-AllowEntries $baselineSet
    $key = { param($x) "$($x.kind)|$($x.value)|$($x.ports)" }
    $currentKeys  = $entries | ForEach-Object { & $key $_ }
    $baselineKeys = $baselineEntries | ForEach-Object { & $key $_ }
    $added   = $entries        | Where-Object { (& $key $_) -notin $baselineKeys }
    $removed = $baselineEntries | Where-Object { (& $key $_) -notin $currentKeys }
}

# --- Format the proposal ----------------------------------------------------
function Format-Entry {
    param($e, [string]$fmt)
    switch ($fmt) {
        'urls' { if ($e.kind -eq 'url') { return "$($e.value)" } else { return $null } }
        'cidr' { if ($e.kind -eq 'cidr') { return "$($e.value)" } else { return $null } }
        default { return "{0,-5} {1,-45} ports={2,-8} area={3} category={4}" -f $e.kind, $e.value, $e.ports, $e.area, $e.category }
    }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Egress allow-list update proposal")
$lines.Add("# Mode        : $mode")
$lines.Add("# Instance    : $($requiredSet.instance)")
$lines.Add("# Web version : $($requiredSet.webServiceVersion)")
$lines.Add("# Generated   : $(Get-Date -Format 'u')")
$lines.Add("# Object group: M365-Required-Endpoints    Allow rule: AllowList-M365-Endpoints")
$lines.Add("# Import these into your proxy/firewall per the vendor's documentation (this file makes no changes).")
$lines.Add("")

if ($deltaMode) {
    $lines.Add("## DRIFT DELTA vs baseline")
    $lines.Add("## ADDED (create these):")
    foreach ($e in $added) { $f = Format-Entry $e $Format; if ($f) { $lines.Add("  + $f") } }
    if ($added.Count -eq 0) { $lines.Add("  (none)") }
    $lines.Add("")
    $lines.Add("## REMOVED (retire these):")
    foreach ($e in $removed) { $f = Format-Entry $e $Format; if ($f) { $lines.Add("  - $f") } }
    if ($removed.Count -eq 0) { $lines.Add("  (none)") }
}
else {
    $lines.Add("## FULL ALLOW-LIST (required + Optimize + Allow + device-management)")
    foreach ($e in $entries) { $f = Format-Entry $e $Format; if ($f) { $lines.Add("  $f") } }
}

$updatePath = Join-Path $OutputPath 'egress-allowlist-update.txt'

if ($PSCmdlet.ShouldProcess($updatePath, "Write allow-list proposal ($mode)")) {
    $lines | Set-Content -LiteralPath $updatePath -Encoding UTF8
}

Write-Host ''
Write-Host "EGRESS Remediation — $mode" -ForegroundColor Cyan
Write-Host ('-' * 60)
if ($deltaMode) {
    Write-Host "Drift delta: ADDED=$($added.Count)  REMOVED=$($removed.Count)" -ForegroundColor Yellow
}
else {
    Write-Host "Full allow-list entries: $($entries.Count)  (format: $Format)" -ForegroundColor Green
}
Write-Host "Proposal written: $updatePath" -ForegroundColor Gray
Write-Host ''
Write-Host "This script generates a proposal only. Review it, then create/update the named objects" -ForegroundColor Gray
Write-Host "(M365-Required-Endpoints / AllowList-M365-Endpoints) on your device per the vendor docs," -ForegroundColor Gray
Write-Host "pilot, and validate with EGRESS-Validation.ps1 before expanding." -ForegroundColor Gray
