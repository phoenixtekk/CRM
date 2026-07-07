<#
.SYNOPSIS
  KB / runbook config helper. Generates a starter ticket taxonomy (categories + P1-P4 priorities),
  a KB skeleton, and the named-runbook list as JSON + Markdown to import or copy into your ITSM/KB
  tools. Writes only to a local folder; makes no tenant changes.
.DESCRIPTION
  Produces the messaging support operating-model scaffolding described in the Implementation Guide:
  ticket categories (Ticket Taxonomy - Messaging - Configure), the priority matrix, and a KB stub per
  category (each carrying owner/next-review placeholders). Everything is written under -OutputPath as
  local files only. Supports -WhatIf. No Microsoft 365 connection is required.
.EXAMPLE
  .\New-MessagingRunbookConfig.ps1 -OutputPath .\runbook-config -WhatIf   # dry-run, shows what it would write
.EXAMPLE
  .\New-MessagingRunbookConfig.ps1 -OutputPath .\runbook-config -ReviewInDays 180
  # (PowerShell 5.1+/7+. No tenant access needed - purely local file generation.)
.NOTES
  Expected results: <OutputPath>\taxonomy.json, kb-skeleton\*.md, and runbooks.md are created.
  PASS = you can import/copy the taxonomy + KB skeleton into your ITSM/KB tools.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$KbOwner = 'TBD-owner',
    [int]$ReviewInDays = 90
)

$ErrorActionPreference = 'Stop'
$reviewDate = (Get-Date).AddDays($ReviewInDays).ToString('yyyy-MM-dd')

$categories = @(
    'Mailbox & Permissions', 'Mail Flow (single user)', 'Mail Flow (transport/connector)',
    'Hygiene / Quarantine / Anti-Phish', 'Client Connectivity',
    'Distribution/Shared/Resource', 'Archiving/Retention', 'Service Availability', 'Security Handoff'
)

$priorities = @(
    [pscustomobject]@{ Priority = 'P1'; Name = 'Critical'; Definition = 'Org-wide or domain-wide mail flow down; large-population inbound/outbound failure.' }
    [pscustomobject]@{ Priority = 'P2'; Name = 'High';     Definition = 'Department/site/shared-mailbox affected; connector or transport rule misbehaving for a group; queues building.' }
    [pscustomobject]@{ Priority = 'P3'; Name = 'Medium';   Definition = 'Single-user send/receive; mailbox permission; single-user client connectivity.' }
    [pscustomobject]@{ Priority = 'P4'; Name = 'Low';      Definition = 'Cosmetic / how-to / non-blocking request.' }
)

$runbooks = @(
    'Tier Responsibilities - Messaging - Design', 'Escalation Matrix - Messaging - Design',
    'Priority Matrix - Messaging - Design', 'On-Call Runbook - Messaging - Design',
    'Security Handoff - Messaging - Design', 'Ticket Taxonomy - Messaging - Configure',
    'Incident Lifecycle - Messaging - Configure', 'Problem Lifecycle - Messaging - Configure',
    'KB Structure - Messaging - Configure', 'Coaching Onboarding - Messaging - Configure',
    'Metrics Report - Messaging - Configure', 'Validation Gates - Messaging - Validate'
)

if ($PSCmdlet.ShouldProcess($OutputPath, 'Create runbook-config scaffolding')) {
    $kbDir = Join-Path $OutputPath 'kb-skeleton'
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    New-Item -ItemType Directory -Path $kbDir -Force | Out-Null

    $taxonomy = [pscustomobject]@{
        generated  = (Get-Date).ToString('o')
        categories = $categories
        priorities = $priorities
        assignmentGroups = @('Messaging-L2', 'Messaging-L3')
    }
    $taxonomy | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutputPath 'taxonomy.json') -Encoding UTF8

    foreach ($cat in $categories) {
        $slug = ($cat -replace '[^\w]+', '-').Trim('-').ToLower()
        $md = @"
# KB: $cat

- Owner: $KbOwner
- Next review: $reviewDate
- Version: 0.1 (stub)

## Symptom
<what the user reports>

## Preconditions / scope
<single user? group? domain? org? which mail domain / connector?>

## Diagnostic steps
1. Portal: <EAC / M365 admin center path - verify for your cloud (Commercial vs Government)>
2. EXO PowerShell: <read-only Get-* cmdlet(s)>

## Resolution
<the fix, at the correct tier>

## When to escalate (attach the diagnostic bundle)
<L2 -> L3 criteria; message trace, timestamps, message IDs, recipients, Get-* output>

## Related Known-Errors
<link to Problem / Known-Error records>
"@
        $md | Set-Content -Path (Join-Path $kbDir "$slug.md") -Encoding UTF8
    }

    ("# Named runbooks`n`n" + (($runbooks | ForEach-Object { "- $_" }) -join "`n")) |
        Set-Content -Path (Join-Path $OutputPath 'runbooks.md') -Encoding UTF8

    Write-Host "Wrote taxonomy.json, $($categories.Count) KB stubs, and runbooks.md under $OutputPath" -ForegroundColor Green
} else {
    Write-Host "[WhatIf] Would write taxonomy.json, $($categories.Count) KB stubs, and runbooks.md under $OutputPath" -ForegroundColor Yellow
}
