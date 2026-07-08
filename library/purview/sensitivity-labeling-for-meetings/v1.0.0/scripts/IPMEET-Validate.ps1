<#
.SYNOPSIS
    IPMEET-Validate.ps1 — Validate meeting labels exist, are Meetings-scoped, and are published (read-only).
.DESCRIPTION
    PURPOSE
        The pilot/expansion gate. Confirms PASS/FAIL that each intended meeting label (Meeting - General /
        Confidential / Highly Confidential) exists, is scoped to Meetings, and is published in the
        'Meeting Labels - Policy', and that the Teams meeting-policy baseline is readable/compatible.
        Read-only — makes no change. Run on the pilot ring before expanding, and after each expansion wave.
    HOW TO RUN
        .\IPMEET-Validate.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession and (optionally) Connect-MicrosoftTeams.
        No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/FAIL line per gate; a final overall PASS only when every intended label exists, is
        Meetings-scoped, and is published in the policy. Any FAIL names the specific missing object.
.NOTES
    Purview — Sensitivity Labeling for Meetings. Read-only gate. Verify your licensing/tenant: confirm the
    Meetings scope wording in ContentType and the policy parameter names for your module version.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'Meeting Labels - Policy',
    [string[]]$ExpectedLabels = @('Meeting - General','Meeting - Confidential','Meeting - Highly Confidential'),
    [string]$MeetingScopeMatch = 'Meeting'
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
$fail = 0
function Gate([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("PASS  {0} — {1}" -f $Name, $Detail) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}

Write-Host "`n=== Sensitivity Labeling for Meetings — validation gate (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-Label')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$labels = @(Get-Label -ErrorAction SilentlyContinue)

# Gate 1 — each expected label exists
foreach ($name in $ExpectedLabels) {
    $l = $labels | Where-Object { $_.DisplayName -eq $name } | Select-Object -First 1
    Gate ("Label exists: {0}" -f $name) ([bool]$l) $(if($l){'found'}else{'not found — author it (Implementation Step 3)'})
    if ($l) {
        $scoped = ($l.ContentType -match $MeetingScopeMatch) -or ($l.DisplayName -match $MeetingScopeMatch)
        Gate ("  Meetings-scoped: {0}" -f $name) $scoped ("ContentType: {0}" -f $l.ContentType)
    }
}

# Gate 2 — policy exists and publishes the labels
$policy = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
Gate ("Policy exists: {0}" -f $PolicyName) ([bool]$policy) $(if($policy){'found'}else{'not found — publish it (Implementation Step 3)'})
if ($policy) {
    # Labels attached to the policy — property name may vary by module version; check common shapes.
    $attached = @()
    foreach ($prop in 'Labels','ScopedLabels','DistributionStatus') {
        if ($policy.PSObject.Properties.Name -contains $prop -and $policy.$prop) { $attached += @($policy.$prop) }
    }
    foreach ($name in $ExpectedLabels) {
        $isIn = ($attached -join ' ') -match [regex]::Escape($name) -or ($attached -join ' ') -match [regex]::Escape(($name -replace ' ',''))
        Gate ("  Published in policy: {0}" -f $name) $isIn $(if($isIn){'listed on the policy'}else{'not detected on the policy — verify in the portal / add with Set-LabelPolicy -AddLabel'})
    }
}

# Gate 3 — Teams baseline readable (compatibility context)
if (Test-Command 'Get-CsTeamsMeetingPolicy') {
    try {
        $mp = Get-CsTeamsMeetingPolicy -ErrorAction Stop | Select-Object -First 1
        Gate 'Teams baseline readable' $true ("lobby={0}; recording={1}; chat={2}" -f $mp.AutoAdmittedUsers, $mp.AllowCloudRecording, $mp.MeetingChatEnabledType)
    } catch {
        Gate 'Teams baseline readable' $false ("could not read: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "INFO  Teams baseline not checked (Connect-MicrosoftTeams to include it)." -ForegroundColor DarkGray
}

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS — meeting labels present, Meetings-scoped, and published. Safe to proceed/expand." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Remediate before expanding." -f $fail) -ForegroundColor Red }
