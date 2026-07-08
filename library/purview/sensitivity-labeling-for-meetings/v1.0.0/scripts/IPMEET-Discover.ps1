<#
.SYNOPSIS
    IPMEET-Discover.ps1 — Meeting sensitivity-label and Teams meeting-baseline discovery (read-only).
.DESCRIPTION
    PURPOSE
        Reports current state so you can assess before configuring meeting labels: every sensitivity
        label and whether any is scoped to Meetings, the label policies that publish them, and the Teams
        meeting-policy baseline (lobby / AutoAdmittedUsers, recording / AllowCloudRecording, chat /
        MeetingChatEnabledType) that meeting labels operate on top of. Read-only — it makes no change to
        any label, policy, or Teams setting. Supports the Assess step.
    HOW TO RUN
        .\IPMEET-Discover.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession (Security & Compliance PowerShell, for
        Get-Label / Get-LabelPolicy) and Connect-MicrosoftTeams (for Get-CsTeamsMeetingPolicy). Sign in
        interactively with a modern-auth/MFA admin; no secret is stored in the script.
    EXPECTED RESULTS
        A summary: labels total and how many are Meetings-scoped (listed), the label policies present,
        and the Teams meeting-policy baseline — each as a PASS/INFO line to record against the
        Requirements checklist.
.NOTES
    Purview — Sensitivity Labeling for Meetings. Read-only. Verify your licensing/tenant: the Meetings
    scope and Teams-Premium meeting protections are evolving; the ContentType wording for the Meetings
    scope may differ in your tenant — confirm in the Purview portal.
#>
[CmdletBinding()]
param(
    [string]$MeetingScopeMatch = 'Meeting'   # substring matched against label ContentType/scope, verify per tenant
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== Sensitivity Labeling for Meetings — discovery (read-only) ===" -ForegroundColor Cyan

# --- 1) Sensitivity labels + which are Meetings-scoped -------------------------------------------------
if (-not (Test-Command 'Get-Label')) {
    Write-Host "Get-Label not available. Run Connect-IPPSSession (ExchangeOnlineManagement) first." -ForegroundColor Yellow
} else {
    try {
        $labels = @(Get-Label -ErrorAction Stop)
        Write-Host ("Labels           : PASS — {0} sensitivity label(s) found" -f $labels.Count) -ForegroundColor Green
        # ContentType typically lists scopes (e.g. 'File, Email, Site, UnifiedGroup, ...'); the meeting
        # scope may surface differently per tenant — match a substring and also flag by name.
        $meeting = @($labels | Where-Object {
            ($_.ContentType -match $MeetingScopeMatch) -or ($_.DisplayName -match $MeetingScopeMatch)
        })
        Write-Host ("Meetings-scoped  : {0} label(s) matched '{1}'" -f $meeting.Count, $MeetingScopeMatch) -ForegroundColor ($(if($meeting.Count -gt 0){'Green'}else{'Yellow'}))
        foreach ($l in $meeting) {
            Write-Host ("    - {0}  [ContentType: {1}]" -f $l.DisplayName, $l.ContentType)
        }
        if ($meeting.Count -eq 0) {
            Write-Host "    (no Meetings-scoped labels detected — author them per the Implementation Guide)" -ForegroundColor DarkGray
            Write-Host "    Note: confirm how the Meetings scope appears in ContentType for your tenant." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host ("Labels           : GAP — could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# --- 2) Label policies --------------------------------------------------------------------------------
if (Test-Command 'Get-LabelPolicy') {
    try {
        $policies = @(Get-LabelPolicy -ErrorAction Stop)
        Write-Host ("Label policies   : {0} policy(ies) found" -f $policies.Count) -ForegroundColor ($(if($policies.Count -gt 0){'Green'}else{'Yellow'}))
        foreach ($p in $policies) { Write-Host ("    - {0}" -f $p.Name) }
        if (-not ($policies | Where-Object { $_.Name -eq 'Meeting Labels - Policy' })) {
            Write-Host "    (Meeting Labels - Policy not found yet — create it in Configure/Step 3)" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host ("Label policies   : GAP — could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host "Get-LabelPolicy not available (Connect-IPPSSession first)." -ForegroundColor Yellow
}

# --- 3) Teams meeting-policy baseline -----------------------------------------------------------------
if (-not (Test-Command 'Get-CsTeamsMeetingPolicy')) {
    Write-Host "Teams baseline   : INFO — Get-CsTeamsMeetingPolicy unavailable. Run Connect-MicrosoftTeams to read it." -ForegroundColor Yellow
} else {
    try {
        $mp = @(Get-CsTeamsMeetingPolicy -ErrorAction Stop)
        $global = $mp | Where-Object { $_.Identity -match 'Global' } | Select-Object -First 1
        if (-not $global) { $global = $mp | Select-Object -First 1 }
        Write-Host ("Teams baseline   : PASS — {0} meeting policy(ies); showing '{1}'" -f $mp.Count, $global.Identity) -ForegroundColor Green
        Write-Host ("    Lobby (AutoAdmittedUsers)   : {0}" -f $global.AutoAdmittedUsers)
        Write-Host ("    Cloud recording allowed     : {0}" -f $global.AllowCloudRecording)
        Write-Host ("    Meeting chat                : {0}" -f $global.MeetingChatEnabledType)
        Write-Host "    (Meeting labels operate on top of this baseline — record it in 'Meeting Scope - Map'.)" -ForegroundColor DarkGray
    } catch {
        Write-Host ("Teams baseline   : GAP — could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`nRecord each signal against the Requirements checklist; remediate any GAP before authoring labels." -ForegroundColor Cyan
Write-Host "Verify your licensing/tenant: the Meetings scope + Teams-Premium meeting protections are evolving." -ForegroundColor DarkGray
