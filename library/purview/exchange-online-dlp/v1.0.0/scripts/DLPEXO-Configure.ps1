<#
.SYNOPSIS
    DLPEXO-Configure.ps1 — build the Exchange Online DLP policy + five scenario rules IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Creates (or updates) an Exchange Online DLP compliance policy scoped to the Exchange (email) location,
        in SIMULATION/TEST mode, plus five rules — sensitive-info-to-external (high & low volume), labeled-mail-
        to-external (encrypt), sensitive-info-to-internal (audit), and a high-count escalation — each conditioned
        on sensitive content and recipient scope, with policy tips. SAFE BY DEFAULT: previews with -WhatIf and
        writes NOTHING unless you pass -Commit. It never enforces (never sets Enable/BlockAccess); moving to
        enforce is a deliberate portal/PowerShell step in Phase 4 of the implementation guide.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPEXO-Configure.ps1 -WhatIf                      # preview only (default is preview)
          .\DLPEXO-Configure.ps1 -Commit                      # create the policy + rules in SIMULATION
          .\DLPEXO-Configure.ps1 -Commit -PilotGroup "SG-DLPEXO-Pilot" -LabelName "Confidential" -PartnerDomain "partner.contoso.com"
    EXPECTED RESULTS
        With -Commit: policy 'DLPEXO-Pilot' exists in a Test/simulation mode, Exchange location, with five rules
        scoped to the pilot senders and enforcing actions OFF. Validate with DLPEXO-Validate.ps1 (expect Gate A
        PASS). Without -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No credentials
    stored. Uses standard New-/Set-DlpCompliancePolicy and New-/Set-DlpComplianceRule; NO invented cmdlets. The
    exact condition/action parameter names (e.g. -SentToScope, -NotifyAllowOverride, the encryption action) and
    the simulation Mode value EVOLVE — the script uses documented names, PRINTS the plan for you to verify with
    `Get-Help New-DlpComplianceRule -Full` against your tenant, and wraps each write in try/catch so a parameter
    that differs in your tenant WARNS rather than aborting. It does NOT enforce (no Enable / BlockAccess=$true).
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName    = "DLPEXO-Pilot",
    [string]$PilotGroup    = "SG-DLPEXO-Pilot",              # pilot sender group (rule-level -FromMemberOf scope)
    [string]$LabelName     = "Confidential",                 # sensitivity label the encrypt rule keys on
    [string]$PartnerDomain = "partner.contoso.com",          # trusted-partner exception domain
    [string]$NotifyMailbox = "dlp-alerts@contoso.com",       # compliance mailbox for incident reports
    [string[]]$SitNames    = @("Credit Card Number","U.S. Social Security Number (SSN)"),
    [int]$LowCount         = 1,                               # low-volume threshold (warn/notify)
    [int]$HighCount        = 10,                              # high-volume threshold (block)
    [int]$EscalateCount    = 50,                              # very-high threshold (block + escalate)
    [string]$SimMode       = "TestWithNotifications"          # simulation + policy tips; verify exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPEXO Configure — Exchange Online DLP policy + rules (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

# --- The plan: five scenario rules. Enforcing actions are DESCRIBED but NOT applied in simulation. ---
# NOTE: -SentToScope / -NotifyAllowOverride / the encrypt action names below are the documented names. VERIFY
# them for your tenant (Get-Help New-DlpComplianceRule -Full) before -Commit; they evolve.
$plan = @(
    @{ Rule = "DLPEXO-Rule-Ext-Block";     Scope = "NotInOrganization"; Count = $HighCount;     Encrypt = $false; Note = "SIT >= $HighCount to EXTERNAL (except $PartnerDomain) -> ENFORCE: Block + policy tip + incident report" }
    @{ Rule = "DLPEXO-Rule-Ext-Notify";    Scope = "NotInOrganization"; Count = $LowCount;      Encrypt = $false; Note = "SIT $LowCount-$([math]::Max($LowCount,$HighCount-1)) to EXTERNAL (except $PartnerDomain) -> ENFORCE: policy tip, allow override w/ justification" }
    @{ Rule = "DLPEXO-Rule-Label-Encrypt"; Scope = "NotInOrganization"; Count = 0;              Encrypt = $true;  Note = "Label '$LabelName' to EXTERNAL -> ENFORCE: Encrypt (Purview Message Encryption; confirm enabled)" }
    @{ Rule = "DLPEXO-Rule-Internal-Audit";Scope = "InOrganization";    Count = $LowCount;      Encrypt = $false; Note = "SIT to INTERNAL -> ENFORCE: notify / incident report only (no block)" }
    @{ Rule = "DLPEXO-Rule-Ext-Escalate";  Scope = "NotInOrganization"; Count = $EscalateCount; Encrypt = $false; Note = "SIT >= $EscalateCount to EXTERNAL -> ENFORCE: Block + escalate incident report to $NotifyMailbox" }
)

Write-Host "`nPlanned policy: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Location : Exchange (email); rules scoped to pilot group '{0}' (-FromMemberOf)" -f $PilotGroup)
Write-Host ("  Mode     : {0}  (SIMULATION — nothing is blocked or encrypted)" -f $SimMode)
Write-Host ("  Content  : SITs [{0}] and/or label '{1}'" -f ($SitNames -join ', '), $LabelName)
Write-Host ("  Exception: recipient domain '{0}' (trusted partner)" -f $PartnerDomain)
Write-Host "  Rules (enforcing actions are configured but INERT while in simulation):"
foreach ($p in $plan) { Write-Host ("    - {0,-24} scope={1,-18} {2}" -f $p.Rule, $p.Scope, $p.Note) }

if (-not $Commit -or $WhatIf) {
    Write-Host "`nPreview complete. No changes made. Verify the parameter names above against your tenant, then re-run with -Commit." -ForegroundColor Yellow
    return
}

# --- Commit: create/ensure the policy in SIMULATION on the Exchange location ---
try {
    $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        Write-Host "`nCreating policy '$PolicyName' (Exchange location, $SimMode)..." -ForegroundColor Green
        New-DlpCompliancePolicy -Name $PolicyName `
            -Mode $SimMode `
            -ExchangeLocation "All" `
            -Comment "Exchange Online DLP pilot — SIMULATION. Rules scoped to pilot senders; move to enforce only after validation (Phase 4)." | Out-Null
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Verify the -ExchangeLocation value and simulation Mode name for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create each scenario rule (conditions only; enforcing actions LEFT OFF in simulation) ---
foreach ($p in $plan) {
    try {
        $exists = Get-DlpComplianceRule -Identity $p.Rule -ErrorAction SilentlyContinue
        if ($null -ne $exists) { Write-Host ("  Rule '{0}' already exists — leaving as-is." -f $p.Rule) -ForegroundColor Yellow; continue }

        # Build the sensitive-information condition (skipped for the label-only encrypt rule).
        $sitCondition = @()
        if ($p.Count -gt 0) {
            foreach ($s in $SitNames) { $sitCondition += @{ Name = $s; minCount = $p.Count } }
        }

        Write-Host ("  Creating rule '{0}' (scope {1}, count {2}) in SIMULATION..." -f $p.Rule, $p.Scope, $p.Count) -ForegroundColor Green

        # Common parameters. NotifyUser drives the policy tip; enforcing actions (BlockAccess/Encrypt) are
        # deliberately NOT set here — they are applied in Phase 4 when the policy Mode becomes Enable.
        $params = @{
            Name       = $p.Rule
            Policy     = $PolicyName
            SentToScope= $p.Scope            # NotInOrganization / InOrganization — VERIFY for your tenant
            NotifyUser = "Owner"             # sender policy tip
            Comment    = ("Exchange DLP — {0}. Simulation: conditions only. {1}" -f $p.Rule, $p.Note)
            ErrorAction= "Stop"
        }
        if ($sitCondition.Count -gt 0) { $params["ContentContainsSensitiveInformation"] = $sitCondition }
        if ($p.Scope -eq "NotInOrganization") { $params["ExceptIfRecipientDomainIs"] = @($PartnerDomain) }  # partner exception; VERIFY
        # Scope the rule to pilot senders during the pilot; widen in Phase 5.
        $params["FromMemberOf"] = @($PilotGroup)                                                            # VERIFY parameter for your tenant

        New-DlpComplianceRule @params | Out-Null

        if ($p.Encrypt) {
            Write-Host ("    NOTE: '{0}' is the ENCRYPT scenario — attach the '{1}' label condition and set the encryption action in the portal (verify the exact action/parameter and that Purview Message Encryption is enabled)." -f $p.Rule, $LabelName) -ForegroundColor DarkYellow
        }
        Write-Host ("    NOTE: enforcing action for '{0}' is applied in Phase 4 (Set policy Mode=Enable + set the Block/Encrypt action). It is INERT now." -f $p.Rule) -ForegroundColor DarkYellow
    } catch {
        Write-Host ("  WARN: could not create rule '{0}': {1}" -f $p.Rule, $_.Exception.Message) -ForegroundColor Yellow
        Write-Host  "        Verify -SentToScope / -ContentContainsSensitiveInformation / -ExceptIfRecipientDomainIs / -FromMemberOf for your tenant, or build this rule in the portal and read it back with DLPEXO-Discovery.ps1." -ForegroundColor Yellow
    }
}

Write-Host "`nDone (SIMULATION). Nothing is enforced." -ForegroundColor Green
Write-Host "Next: DLPEXO-Validate.ps1 (expect Gate A PASS), then pilot per 05-testing.md before any enforce." -ForegroundColor Cyan
