<#
.SYNOPSIS
    AGBGOV-Export-ApprovalEvidence.ps1 — Assemble an audit-ready approval evidence pack. READ-ONLY.

.DESCRIPTION
    Purpose:
        Assembles a timestamped evidence pack proving that agents were governed: the ARB decision
        records, and - where available - the tenant audit trail of agent approve/publish/block
        actions. Give this to an auditor to show the operating model actually ran. It is READ-ONLY
        and never changes the tenant.

        It gathers:
          1. The "AGBGOV - Agent Decision Record" export you supply (-DecisionCsv).
          2. (Optional) Directory audit events related to agent/app publish/block actions, pulled
             from Microsoft Graph auditLogs when the read scope is granted. If the audit query is
             unavailable, the script degrades gracefully and records that the unified audit log for
             Copilot/agent actions is retrieved via Microsoft Purview Audit (see notes).
          3. A manifest describing the pack.

    How to run:
        # Evidence pack from the decision record only (no tenant connection):
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Export-ApprovalEvidence.ps1 -DecisionCsv .\decisions.csv -OutDir .\EvidencePacks

        # Also attempt to pull the directory audit trail (Commercial):
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Export-ApprovalEvidence.ps1 -DecisionCsv .\decisions.csv -OutDir .\EvidencePacks -IncludeAudit

        # Government tenant:
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Export-ApprovalEvidence.ps1 -DecisionCsv .\decisions.csv -OutDir .\EvidencePacks -IncludeAudit -Environment USGov

    Expected results:
        A folder EvidencePacks\AGBGOV-Evidence-<timestamp>\ containing the decision record copy, an
        optional audit CSV, and a manifest.txt. Console prints the pack path.

.NOTES
    Copilot category - governance - READ-ONLY. The richest audit trail for Copilot/agent actions is
    in Microsoft Purview Audit (Search-UnifiedAuditLog / Purview portal) - which this script points
    you to when the directory-audit path returns nothing. Verify current audit record availability
    for agent actions against Microsoft documentation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DecisionCsv,

    [string]$OutDir = '.\EvidencePacks',

    [switch]$IncludeAudit,

    [int]$LookbackDays = 90,

    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $DecisionCsv)) { throw "Decision record CSV not found: $DecisionCsv" }

$graphEnv = switch ($Environment) { 'USGov' {'USGov'} 'USGovDoD' {'USGovDoD'} default {'Global'} }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$packDir = Join-Path $OutDir "AGBGOV-Evidence-$stamp"
New-Item -ItemType Directory -Path $packDir -Force | Out-Null

# 1. Copy the decision record (the primary governance evidence).
Copy-Item -Path $DecisionCsv -Destination (Join-Path $packDir 'AGBGOV-Agent-Decision-Record.csv') -Force
$decisions = Import-Csv -Path $DecisionCsv
Write-Host ("Decision records included: {0}" -f @($decisions).Count) -ForegroundColor Green

# 2. Optional directory audit trail.
$auditNote = 'Directory audit not requested (-IncludeAudit not set).'
if ($IncludeAudit) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null
        Write-Host "Connecting to Microsoft Graph ($graphEnv) with AuditLog.Read.All ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $graphEnv -Scopes 'AuditLog.Read.All' -NoWelcome -ErrorAction Stop

        $since = (Get-Date).AddDays(-1 * $LookbackDays).ToString('yyyy-MM-ddT00:00:00Z')
        # Directory audit logs; filter to app/agent management activity in the window. Activity
        # display names for agent publish/block vary by tenant and evolve - we capture broadly and
        # let the reviewer filter. NEVER fabricate a record shape.
        $uri = "/v1.0/auditLogs/directoryAudits?`$filter=activityDateTime ge $since&`$top=200"
        $events = @()
        do {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($resp.value) { $events += $resp.value }
            $uri = $resp.'@odata.nextLink'
        } while ($uri -and $events.Count -lt 5000)

        $agentish = $events | Where-Object {
            "$($_.category) $($_.activityDisplayName) $($_.loggedByService)" -match 'agent|copilot|app|package'
        }
        if (@($agentish).Count -gt 0) {
            $agentish |
                Select-Object activityDateTime, activityDisplayName, category, loggedByService,
                              @{n='initiatedBy';e={ $_.initiatedBy.user.userPrincipalName }},
                              result |
                Export-Csv -Path (Join-Path $packDir 'AGBGOV-DirectoryAudit-AgentActions.csv') -NoTypeInformation -Encoding UTF8
            $auditNote = ("Directory audit events (agent/app/copilot) captured: {0} over {1} days." -f @($agentish).Count, $LookbackDays)
        }
        else {
            $auditNote = "Directory audit returned no agent-related events. The authoritative trail for Copilot/agent approve/publish/block actions is the UNIFIED AUDIT LOG in Microsoft Purview (Purview portal > Audit, or Search-UnifiedAuditLog). Export it there for the pack."
        }
        Write-Host $auditNote -ForegroundColor Yellow
    }
    catch {
        $auditNote = ("Audit query unavailable: {0}. Use Microsoft Purview Audit (Purview portal > Audit) to export Copilot/agent activity for the pack." -f $_.Exception.Message)
        Write-Warning $auditNote
    }
}

# 3. Manifest.
$manifest = @()
$manifest += "AGBGOV Approval Evidence Pack"
$manifest += "Generated: $(Get-Date -Format 's')"
$manifest += "Cloud: $Environment"
$manifest += "Decision record: AGBGOV-Agent-Decision-Record.csv ($(@($decisions).Count) records)"
$manifest += "Audit: $auditNote"
$manifest += ""
$manifest += "Note: This pack is READ-ONLY evidence. The Agent Decision Record is the governance"
$manifest += "system of record; the Microsoft 365 admin center Agent Registry export and Purview"
$manifest += "Audit provide the technical corroboration. Verify current audit availability against"
$manifest += "Microsoft documentation."
$manifest -join "`r`n" | Set-Content -Path (Join-Path $packDir 'manifest.txt') -Encoding UTF8

Write-Host "`nEvidence pack assembled at: $packDir" -ForegroundColor Green
