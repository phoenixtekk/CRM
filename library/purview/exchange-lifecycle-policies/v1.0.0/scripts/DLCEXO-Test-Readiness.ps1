<#
.SYNOPSIS
    DLCEXO-Test-Readiness.ps1 — consolidated PASS/GAP pilot gate for the Exchange lifecycle deployment (read-only).
.DESCRIPTION
    PURPOSE
        One read-only gate that checks the pilot is safe to run and safe to expand: the two toolchain
        connections work, the Purview retention policy is scoped to the PILOT ONLY (blast-radius), the rule
        matches the approved schedule, the MRM cleanup policy is assigned to pilot mailboxes, holds are visible
        (so held mail is preserved), and — critically — a sample of NON-pilot mailboxes is NOT carrying the
        policy. Prints PASS / GAP per check. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement. Connect BOTH endpoints first:
          Connect-IPPSSession
          Connect-ExchangeOnline
          .\DLCEXO-Test-Readiness.ps1 -PilotGroup "SG-DLCEXO-Pilot"
    EXPECTED RESULTS
        A PASS/GAP line per check and an overall verdict. Overall PASS (or every GAP documented and accepted
        by records/legal) is the exit criterion before expanding scope or adding a delete action.
.NOTES
    White-label tooling. Read-only. No credentials stored. Standard S&C / Exchange Online cmdlets; none
    invented. This gate does not make records/legal determinations — it verifies technical readiness only.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup    = "SG-DLCEXO-Pilot",
    [string]$PolicyName    = "DLCEXO-Retention-Exchange-Pilot",
    [string]$RuleName      = "DLCEXO-Rule-Exchange-Keep7yrThenDelete",
    [string]$MrmPolicyName = "DLCEXO-MRM-Cleanup-Standard",
    [int]$NonPilotSample   = 5
)

$ErrorActionPreference = "Continue"
Write-Host "=== DLCEXO Test-Readiness — pilot gate (read-only) ===" -ForegroundColor Cyan
$results = [System.Collections.Generic.List[object]]::new()
function Gate($name, $ok, $detail) {
    $status = if ($ok) { "PASS" } else { "GAP" }
    $color  = if ($ok) { "Green" } else { "Yellow" }
    Write-Host ("  [{0}] {1} — {2}" -f $status, $name, $detail) -ForegroundColor $color
    $results.Add([pscustomobject]@{ Check = $name; Status = $status; Detail = $detail })
}

# --- C1: toolchain connections ---
$ipps = $false; $exo = $false
try { Get-RetentionCompliancePolicy -ErrorAction Stop | Out-Null; $ipps = $true } catch {}
try { Get-RetentionPolicy -ErrorAction Stop | Out-Null; $exo = $true } catch {}
Gate "S&C PowerShell connection" $ipps ("Connect-IPPSSession {0}" -f ($(if($ipps){"OK"}else{"NOT connected"})))
Gate "Exchange Online connection" $exo  ("Connect-ExchangeOnline {0}" -f ($(if($exo){"OK"}else{"NOT connected"})))

# --- Resolve pilot membership ---
$pilot = @()
try { $pilot = Get-DistributionGroupMember -Identity $PilotGroup -ResultSize Unlimited -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress } catch {}
Gate "Pilot group resolves" ($pilot.Count -gt 0) ("'{0}' -> {1} mailbox(es)" -f $PilotGroup, $pilot.Count)

# --- C2: Purview policy scoped to pilot ONLY (blast radius) ---
if ($ipps) {
    try {
        $pol = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction Stop
        $loc = @($pol.ExchangeLocation | ForEach-Object { "$_" })
        $extra = @($loc | Where-Object { $_ -and $_ -notmatch '^All$' -and ($pilot -notcontains $_) })
        $scopedToAll = ($loc -contains 'All')
        Gate "Retention policy scope = pilot only" (($pilot.Count -gt 0) -and (-not $scopedToAll) -and ($extra.Count -eq 0)) `
            ("ExchangeLocation entries={0}; ScopedToAll={1}; out-of-pilot entries={2}" -f $loc.Count, $scopedToAll, $extra.Count)
        Gate "Retention policy enabled" ([bool]$pol.Enabled) ("Enabled={0}" -f $pol.Enabled)
    } catch { Gate "Retention policy present" $false ("'{0}' not found: {1}" -f $PolicyName, $_.Exception.Message) }

    # --- C3: rule matches the approved schedule (surface values, don't judge the schedule) ---
    try {
        $rule = Get-RetentionComplianceRule -Identity $RuleName -ErrorAction Stop
        $isDelete = ($rule.RetentionComplianceAction -match 'Delete')
        Gate "Retention rule present" $true ("Duration={0}d; Action={1}; Basis={2}" -f $rule.RetentionDuration, $rule.RetentionComplianceAction, $rule.ExpirationDateOption)
        if ($isDelete) { Write-Host "      NOTE: rule includes DELETE — confirm records-approved schedule (R4) before expanding." -ForegroundColor Yellow }
    } catch { Gate "Retention rule present" $false ("'{0}' not found: {1}" -f $RuleName, $_.Exception.Message) }
}

# --- C4: MRM assigned to pilot mailboxes ---
if ($exo -and $pilot.Count -gt 0) {
    $assigned = 0; $held = 0
    foreach ($mb in $pilot) {
        try {
            $m = Get-Mailbox -Identity $mb -ErrorAction Stop
            if ($m.RetentionPolicy -eq $MrmPolicyName) { $assigned++ }
            if ($m.LitigationHoldEnabled) { $held++ }
        } catch {}
    }
    Gate "MRM policy assigned to pilot" ($assigned -eq $pilot.Count) ("{0}/{1} pilot mailbox(es) carry '{2}'" -f $assigned, $pilot.Count, $MrmPolicyName)
    Gate "Holds visible (preserved regardless of delete)" $true ("{0}/{1} pilot mailbox(es) on litigation hold — reconcile with legal (R5)" -f $held, $pilot.Count)
}

# --- C5: blast radius — NON-pilot mailboxes NOT carrying the MRM policy ---
if ($exo) {
    try {
        $others = Get-Mailbox -ResultSize $NonPilotSample -ErrorAction Stop |
            Where-Object { $pilot -notcontains ([string]$_.PrimarySmtpAddress) }
        $leak = @($others | Where-Object { $_.RetentionPolicy -eq $MrmPolicyName })
        Gate "No out-of-pilot mailbox carries the MRM policy" ($leak.Count -eq 0) `
            ("checked {0} non-pilot mailbox(es); leaks={1}" -f @($others).Count, $leak.Count)
    } catch { Gate "Blast-radius sample" $false ("could not sample non-pilot mailboxes: {0}" -f $_.Exception.Message) }
}

$gaps = @($results | Where-Object { $_.Status -eq "GAP" }).Count
Write-Host ("`n=== Overall: {0} ({1} GAP) ===" -f ($(if($gaps -eq 0){"PASS"}else{"REVIEW"})), $gaps) -ForegroundColor $(if($gaps -eq 0){"Green"}else{"Yellow"})
Write-Host "Exit criterion: overall PASS, or every GAP documented and accepted by records/legal, before expanding scope or adding a delete action." -ForegroundColor Cyan
