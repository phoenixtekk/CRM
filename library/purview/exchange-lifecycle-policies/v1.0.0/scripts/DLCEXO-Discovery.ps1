<#
.SYNOPSIS
    DLCEXO-Discovery.ps1 — inventory what already governs the mailboxes: Purview retention + MRM cleanup + holds (read-only).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the Exchange Lifecycle Policies solution. Inventories the two lifecycle
        engines already in the tenant: Purview Data Lifecycle Management retention policies/rules scoped to
        Exchange (Connect-IPPSSession), and Exchange MRM retention tags/policies plus the org default MRM
        policy, per-mailbox archive status, and litigation-hold status (Connect-ExchangeOnline). This is the
        "what already keeps/deletes this mail" baseline you must reconcile before adding a new policy.
        Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with ExchangeOnlineManagement. Connect BOTH endpoints first:
          Connect-IPPSSession
          Connect-ExchangeOnline
          .\DLCEXO-Discovery.ps1
          .\DLCEXO-Discovery.ps1 -IncludeMailboxSample -MailboxSampleSize 50
    EXPECTED RESULTS
        A retention/cleanup inventory to .\DLCEXO-Lifecycle-Estate-Discovery.csv and, with
        -IncludeMailboxSample, a per-mailbox archive/hold/policy sample to
        .\DLCEXO-Mailbox-Estate-Discovery.csv. Pre-existing holds or retention that would change what a new
        policy removes are the first finding.
.NOTES
    White-label Microsoft Purview / Exchange Online tooling. Read-only. No credentials stored. Cmdlets are
    standard S&C PowerShell and Exchange Online PowerShell; none are invented. Feature availability is
    licensing-dependent — the script warns where a surface is not readable rather than assuming.
#>
[CmdletBinding()]
param(
    [switch]$IncludeMailboxSample,
    [int]$MailboxSampleSize = 25,
    [string]$OutPath        = ".\DLCEXO-Lifecycle-Estate-Discovery.csv",
    [string]$MailboxOutPath = ".\DLCEXO-Mailbox-Estate-Discovery.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLCEXO Discovery — Exchange lifecycle inventory (read-only) ===" -ForegroundColor Cyan

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}

# --- Purview retention policies + rules scoped to Exchange (Security & Compliance PowerShell) ---
$ippsOk = $false
try { Get-RetentionCompliancePolicy -ErrorAction Stop | Out-Null; $ippsOk = $true }
catch { Write-Host "Not connected to Security & Compliance PowerShell — run Connect-IPPSSession (GR §3). Skipping Purview retention." -ForegroundColor Yellow }

if ($ippsOk) {
    try {
        $pols = Get-RetentionCompliancePolicy -ErrorAction Stop
        foreach ($p in $pols) {
            $exo = $p.ExchangeLocation -join "; "
            Add-Row "PurviewRetentionPolicy" $p.Name ("Enabled={0}; Mode={1}; ExchangeLocation={2}" -f $p.Enabled, $p.Mode, $exo)
        }
        Write-Host ("  Purview retention policies: {0}" -f @($pols).Count) -ForegroundColor Green
        try {
            $rules = Get-RetentionComplianceRule -ErrorAction Stop
            foreach ($r in $rules) {
                Add-Row "PurviewRetentionRule" $r.Name ("Policy={0}; Duration={1}; Action={2}; ExpiryBasis={3}" -f `
                    $r.Policy, $r.RetentionDuration, $r.RetentionComplianceAction, $r.ExpirationDateOption)
            }
            Write-Host ("  Purview retention rules: {0}" -f @($rules).Count) -ForegroundColor Green
        } catch { Write-Host "  WARN: could not read retention rules: $($_.Exception.Message)" -ForegroundColor Yellow }
    } catch { Write-Host "  WARN: could not read retention policies: $($_.Exception.Message)" -ForegroundColor Yellow }
}

# --- Exchange MRM retention tags + policies + org default (Exchange Online PowerShell) ---
$exoOk = $false
try { Get-RetentionPolicy -ErrorAction Stop | Out-Null; $exoOk = $true }
catch { Write-Host "Not connected to Exchange Online — run Connect-ExchangeOnline (GR §3). Skipping MRM." -ForegroundColor Yellow }

if ($exoOk) {
    try {
        $tags = Get-RetentionPolicyTag -ErrorAction Stop
        foreach ($t in $tags) {
            Add-Row "MrmRetentionTag" $t.Name ("Type={0}; Action={1}; AgeLimitDays={2}; Enabled={3}" -f `
                $t.Type, $t.RetentionAction, $t.AgeLimitForRetention, $t.RetentionEnabled)
        }
        Write-Host ("  MRM retention tags: {0}" -f @($tags).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read MRM tags: $($_.Exception.Message)" -ForegroundColor Yellow }
    try {
        $mpols = Get-RetentionPolicy -ErrorAction Stop
        foreach ($m in $mpols) { Add-Row "MrmRetentionPolicy" $m.Name ("Tags={0}" -f ($m.RetentionPolicyTagLinks -join "; ")) }
        Write-Host ("  MRM retention policies: {0}" -f @($mpols).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read MRM policies: $($_.Exception.Message)" -ForegroundColor Yellow }
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nLifecycle inventory written to {0}  (Lifecycle - Estate - Discovery)" -f $OutPath) -ForegroundColor Green

# --- Optional: per-mailbox sample — archive + litigation hold + assigned MRM policy ---
if ($IncludeMailboxSample -and $exoOk) {
    try {
        $mbx = Get-Mailbox -ResultSize $MailboxSampleSize -ErrorAction Stop
        $mrows = foreach ($m in $mbx) {
            [pscustomobject]@{
                Mailbox            = $m.PrimarySmtpAddress
                RetentionPolicy    = $m.RetentionPolicy
                ArchiveState       = $m.ArchiveState
                ArchiveStatus      = $m.ArchiveStatus
                LitigationHold     = $m.LitigationHoldEnabled
                RetentionHold      = $m.RetentionHoldEnabled
            }
        }
        $mrows | Export-Csv -Path $MailboxOutPath -NoTypeInformation -Encoding UTF8
        $held = @($mrows | Where-Object { $_.LitigationHold }).Count
        Write-Host ("Mailbox sample written to {0}  (Mailbox - Estate - Discovery): {1} mailbox(es), {2} on litigation hold." -f `
            $MailboxOutPath, @($mrows).Count, $held) -ForegroundColor Green
        if ($held -gt 0) { Write-Host "  NOTE: held mailboxes' mail is preserved regardless of delete rules — reconcile with legal (R5)." -ForegroundColor Yellow }
    } catch { Write-Host "  WARN: could not read mailbox sample: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "Next: run DLCEXO-Set-Scope.ps1 to record the pilot scope, then DLCEXO-Configure.ps1 -WhatIf." -ForegroundColor Cyan
