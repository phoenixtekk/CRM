<#
.SYNOPSIS
  Retention policy + retention label config helper (-WhatIf/dry-run by default).
.DESCRIPTION
  Creates/verifies retention LABELS (New-ComplianceTag) and a tenant/pilot retention POLICY + rule
  (New-RetentionCompliancePolicy / -Rule) from a config object or JSON. Reports intended changes by
  default; only writes when -Commit is passed. Policies are created DISABLED; label publish/auto-apply
  is scoped to the supplied pilot locations. Refuses regulatory labels unless -AllowRegulatory is set.
.EXAMPLE
  .\Set-RetentionPolicyAndLabels.ps1 -ConfigPath .\lifecycle-design.json
  # Dry-run: prints every label/policy it WOULD create. Add -Commit to apply.
.EXAMPLE
  .\Set-RetentionPolicyAndLabels.ps1 -ConfigPath .\lifecycle-design.json -Commit -AllowRegulatory -SignOffRef "CR-1234"
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: each designed label exists with correct action/duration/trigger/record status, and
  the pilot retention policy exists DISABLED with its rule. Dry-run prints intent only; no credentials in code.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    # Apply changes. Without this, the script only reports intended changes.
    [switch]$Commit,

    # Required to create/modify one-way regulatory-record labels (must also pass -SignOffRef).
    [switch]$AllowRegulatory,

    # Records/legal change-control reference recorded alongside any regulatory action.
    [string]$SignOffRef
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$apply = $Commit.IsPresent
$mode  = if ($apply) { "COMMIT" } else { "DRY-RUN (-WhatIf)" }
Write-Host "== Set-RetentionPolicyAndLabels — $mode ==" -ForegroundColor Cyan
Write-Host "Config: $ConfigPath" -ForegroundColor Cyan
Write-Host ""

# ---------------- Labels ----------------
foreach ($l in @($cfg.labels)) {
    $isReg = [bool]$l.regulatory
    if ($isReg -and (-not $AllowRegulatory -or [string]::IsNullOrWhiteSpace($SignOffRef))) {
        Write-Warning ("SKIP regulatory label '{0}' — regulatory records are ONE-WAY. Re-run with -AllowRegulatory -SignOffRef <ref>." -f $l.name)
        continue
    }

    $existing = Get-ComplianceTag -Identity $l.name -ErrorAction SilentlyContinue
    $verb = if ($existing) { "VERIFY/UPDATE" } else { "CREATE" }
    Write-Host ("[LABEL] {0}: {1}" -f $verb, $l.name) -ForegroundColor Yellow
    Write-Host ("   action={0} durationDays={1} type={2} record={3} regulatory={4} event={5} reviewers={6}" -f `
        $l.retentionAction, $l.retentionDuration, $l.retentionType, [bool]$l.isRecordLabel, $isReg, $l.eventType, ($l.reviewerEmail -join ';'))

    if (-not $existing) {
        $p = @{
            Name            = $l.name
            RetentionAction = $l.retentionAction
            RetentionType   = $l.retentionType
        }
        if ($l.retentionDuration) { $p.RetentionDuration = $l.retentionDuration }
        if ($l.isRecordLabel)     { $p.IsRecordLabel = $true }
        if ($isReg)               { $p.Regulatory = $true }
        if ($l.eventType)         { $p.EventType = $l.eventType }
        if ($l.reviewerEmail)     { $p.ReviewerEmail = @($l.reviewerEmail) }
        if ($l.comment)           { $p.Comment = $l.comment }

        if ($apply -and $PSCmdlet.ShouldProcess($l.name, "New-ComplianceTag")) {
            if ($isReg) { Write-Host ("   [regulatory sign-off: {0}]" -f $SignOffRef) -ForegroundColor Magenta }
            New-ComplianceTag @p | Out-Null
            Write-Host "   -> created" -ForegroundColor Green
        }
        else { Write-Host "   -> would create (dry-run)" }
    }
    else { Write-Host "   -> exists; review action/duration/record status against design" }
}

# ---------------- Policy + rule ----------------
$pol = $cfg.policy
if ($pol) {
    Write-Host ""
    $existingPol = Get-RetentionCompliancePolicy -Identity $pol.name -ErrorAction SilentlyContinue
    $verb = if ($existingPol) { "VERIFY" } else { "CREATE (DISABLED)" }
    Write-Host ("[POLICY] {0}: {1}" -f $verb, $pol.name) -ForegroundColor Yellow

    $locSummary = @()
    foreach ($k in 'exchangeLocation','sharePointLocation','oneDriveLocation','modernGroupLocation','teamsChannelLocation','teamsChatLocation','adaptiveScopeLocation') {
        if ($pol.$k) { $locSummary += ("{0}={1}" -f $k, ($pol.$k -join ',')) }
    }
    Write-Host ("   locations: {0}" -f ($locSummary -join ' ; '))
    Write-Host ("   rule: action={0} durationDays={1} publishTag={2} applyTag={3}" -f $pol.ruleAction, $pol.ruleDuration, $pol.publishComplianceTag, $pol.applyComplianceTag)

    if (-not $existingPol) {
        if ($apply -and $PSCmdlet.ShouldProcess($pol.name, "New-RetentionCompliancePolicy (Enabled=`$false)")) {
            $pp = @{ Name = $pol.name; Enabled = $false }
            foreach ($map in @(
                @{ j='exchangeLocation';      c='ExchangeLocation' },
                @{ j='sharePointLocation';    c='SharePointLocation' },
                @{ j='oneDriveLocation';      c='OneDriveLocation' },
                @{ j='modernGroupLocation';   c='ModernGroupLocation' },
                @{ j='teamsChannelLocation';  c='TeamsChannelLocation' },
                @{ j='teamsChatLocation';     c='TeamsChatLocation' },
                @{ j='adaptiveScopeLocation'; c='AdaptiveScopeLocation' }
            )) { if ($pol.($map.j)) { $pp[$map.c] = @($pol.($map.j)) } }

            New-RetentionCompliancePolicy @pp | Out-Null
            Write-Host "   -> policy created (DISABLED). Enable only after the pilot gate passes." -ForegroundColor Green

            if ($pol.ruleAction -or $pol.publishComplianceTag -or $pol.applyComplianceTag) {
                if ($PSCmdlet.ShouldProcess($pol.name, "New-RetentionComplianceRule")) {
                    $rp = @{ Policy = $pol.name }
                    if ($pol.ruleAction)           { $rp.RetentionComplianceAction = $pol.ruleAction }
                    if ($pol.ruleDuration)         { $rp.RetentionDuration = $pol.ruleDuration; $rp.RetentionDurationDisplayHint = 'Days' }
                    if ($pol.publishComplianceTag) { $rp.PublishComplianceTag = $pol.publishComplianceTag }
                    if ($pol.applyComplianceTag)   { $rp.ApplyComplianceTag = $pol.applyComplianceTag }
                    if ($pol.contentMatchQuery)    { $rp.ContentMatchQuery = $pol.contentMatchQuery }
                    New-RetentionComplianceRule @rp | Out-Null
                    Write-Host "   -> rule created" -ForegroundColor Green
                }
            }
        }
        else { Write-Host "   -> would create policy DISABLED + rule (dry-run)" }
    }
    else { Write-Host "   -> exists; verify locations/rule and enabled-state against design" }
}

Write-Host ""
if (-not $apply) { Write-Host "DRY-RUN complete — no changes made. Re-run with -Commit to apply." -ForegroundColor Green }
else { Write-Host "COMMIT complete — policy created DISABLED; validate on the pilot before enabling." -ForegroundColor Green }
