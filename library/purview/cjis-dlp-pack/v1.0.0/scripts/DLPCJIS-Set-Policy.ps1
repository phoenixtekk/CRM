<#
.SYNOPSIS
    DLPCJIS-Set-Policy.ps1 — SIMULATION-FIRST CJI DLP policy tool: creates the policy + rule in TEST mode; -PromoteToEnforce to enable; -Disable to roll back. -WhatIf by DEFAULT; writes only with -Commit.
.DESCRIPTION
    PURPOSE
        The one write-capable tool in the pack, safe by default. Creates the CJI DLP policy
        'CJIS CJI Protection - AllWorkloads - Pilot' and its rule 'CJI Detection Rule - Identifiers+CHRI - v1'
        across the in-scope M365 workloads, ALWAYS starting in a TEST mode (TestWithNotifications /
        TestWithoutNotifications) so nothing blocks. -PromoteToEnforce moves an already-piloted policy to
        Mode=Enable; -Disable rolls it back to non-enforcing. With no -Commit it PREVIEWS and writes NOTHING;
        on -Commit it applies and appends a row to the change record CSV. No credentials or secrets in code.
    HOW TO RUN
        Connect-IPPSSession                                   # modern-auth admin sign-in (no secrets in code)
        # 1) Preview the pilot policy (default, no change):
        .\DLPCJIS-Set-Policy.ps1 -SitName "CJI Sensitive Info Type - CHRI - Custom" -WhatIf
        # 2) Create it in SIMULATION/TEST:
        .\DLPCJIS-Set-Policy.ps1 -SitName "CJI Sensitive Info Type - CHRI - Custom" -Mode TestWithNotifications -Commit
        # 3) After a clean pilot + approval, promote to ENFORCE inside a change window:
        .\DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -Commit
        # Rollback at any time:
        .\DLPCJIS-Set-Policy.ps1 -Disable -Commit
        PowerShell 5.1+/7+; requires Security & Compliance PowerShell
        (New/Set-DlpCompliancePolicy, New-DlpComplianceRule).
    EXPECTED RESULTS
        Create: policy exists with Mode=<a Test* mode>, rule present, NO user is blocked.
        -PromoteToEnforce: policy Mode=Enable (configured action now applies). -Disable: policy Mode=Disable.
        -WhatIf (default): prints the intended change and makes NONE.
.NOTES
    CJIS DLP Pack — HIGH-IMPACT. Only PROMOTE a policy whose simulation results are clean, in a change
    window, with approval. The enforcement ACTION (block / block-with-override / restrict-external) and the
    CJI detection definition are set to your design; whether data IS CJI and CJI retention are DEFERRED to
    your CSO/TAC / compliance / legal. Verify licensing/tenant (Endpoint DLP requires E5 / E5 Compliance).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$PolicyName = 'CJIS CJI Protection - AllWorkloads - Pilot',
    [string]$RuleName   = 'CJI Detection Rule - Identifiers+CHRI - v1',
    [string]$SitName    = 'CJI Sensitive Info Type - CHRI - Custom',
    [ValidateSet('TestWithNotifications','TestWithoutNotifications','Disable')]
    [string]$Mode = 'TestWithNotifications',
    [ValidateSet('Low','Medium','High')][string]$Confidence = 'Medium',
    [int]$MinCount = 1,
    [ValidateSet('BlockAccess','RestrictAccess','NotifyOnly')][string]$EnforceAction = 'BlockAccess',
    [switch]$IncludeEndpoint,          # only if Endpoint DLP is licensed + devices onboarded (E5)
    [switch]$PromoteToEnforce,         # move an existing piloted policy to Mode=Enable
    [switch]$Disable,                  # roll back an existing policy to Mode=Disable
    [switch]$Commit,
    [string]$ChangeRecordCsv = '.\Change-Record-CJISDLP.csv'
)

# Safe by default: unless -Commit, force -WhatIf behavior (no writes).
if (-not $Commit) { $WhatIfPreference = $true }

if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Error "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first."
    return
}

function Write-ChangeRecord {
    param([string]$Action, [string]$From, [string]$To)
    $record = [pscustomobject]@{
        TimestampUtc = (Get-Date).ToUniversalTime().ToString('s')
        Operator     = $(try { (Get-ConnectionInformation | Select-Object -First 1).UserPrincipalName } catch { $env:USERNAME })
        Action       = $Action
        PolicyName   = $PolicyName
        FromMode     = $From
        ToMode       = $To
    }
    $record | Export-Csv -Path $ChangeRecordCsv -NoTypeInformation -Append
    Write-Host ("Change recorded in {0}." -f $ChangeRecordCsv) -ForegroundColor Green
}

$existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue

# --- Mode 1: PROMOTE existing pilot policy to ENFORCE (Mode=Enable) ---
if ($PromoteToEnforce) {
    if (-not $existing) { Write-Error "Policy '$PolicyName' not found — create it in test mode first."; return }
    $from = [string]$existing.Mode
    if ($from -notmatch 'Test|Disable') { Write-Warning "Policy is not currently in a test/disabled mode — confirm this is an intended (re-)enforce." }
    Write-Host ("=== PROMOTE TO ENFORCE: '{0}'  ({1} -> Enable) ===" -f $PolicyName, $from) -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("DLP policy '$PolicyName'", "set Mode $from -> Enable (ENFORCE)")) {
        try {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode Enable -ErrorAction Stop
            Write-Host "APPLIED: policy is now ENFORCING (Mode=Enable)." -ForegroundColor Green
            Write-ChangeRecord -Action 'PromoteToEnforce' -From $from -To 'Enable'
        } catch { Write-Error ("Promote FAILED: {0}" -f $_.Exception.Message) }
    } else {
        Write-Host "WHATIF (default): no change. Re-run with -Commit inside a change window to enforce." -ForegroundColor Yellow
    }
    return
}

# --- Mode 2: ROLL BACK existing policy to Disable ---
if ($Disable) {
    if (-not $existing) { Write-Error "Policy '$PolicyName' not found."; return }
    $from = [string]$existing.Mode
    Write-Host ("=== ROLLBACK: '{0}'  ({1} -> Disable) ===" -f $PolicyName, $from) -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("DLP policy '$PolicyName'", "set Mode $from -> Disable")) {
        try {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode Disable -ErrorAction Stop
            Write-Host "APPLIED: policy DISABLED (no user impact)." -ForegroundColor Green
            Write-ChangeRecord -Action 'Disable' -From $from -To 'Disable'
        } catch { Write-Error ("Disable FAILED: {0}" -f $_.Exception.Message) }
    } else {
        Write-Host "WHATIF (default): no change. Re-run with -Commit to disable." -ForegroundColor Yellow
    }
    return
}

# --- Mode 3: CREATE the pilot policy + rule in TEST/SIMULATION ---
if ($Mode -notmatch 'Test|Disable') {
    Write-Error "Create must use a TEST mode (simulation-first). Use -PromoteToEnforce to enable later."
    return
}
if ($existing) {
    Write-Warning ("Policy '{0}' already exists (Mode={1}). To change its mode use -PromoteToEnforce / -Disable, or tune the rule in the portal." -f $PolicyName, $existing.Mode)
    return
}

# Build the workload scope. 'All' targets Exchange/SP/OneDrive/Teams; endpoints added only when requested + licensed.
Write-Host ("=== CREATE (SIMULATION): '{0}' in Mode={1} ===" -f $PolicyName, $Mode) -ForegroundColor Cyan
Write-Host ("Detection: SIT='{0}' Confidence={1} MinCount={2}  |  Staged enforce action (applied only after promote): {3}" -f $SitName, $Confidence, $MinCount, $EnforceAction) -ForegroundColor Cyan
if ($IncludeEndpoint) { Write-Host "Endpoint DLP requested — requires E5/E5 Compliance + onboarded devices; verify before relying on it." -ForegroundColor Yellow }

if ($PSCmdlet.ShouldProcess("DLP policy '$PolicyName' + rule '$RuleName'", "create in $Mode (simulation)")) {
    try {
        # Create the policy across the M365 workloads in a TEST mode (nothing blocks yet).
        $polParams = @{
            Name             = $PolicyName
            Comment          = 'CJI Data Loss Prevention — piloted in simulation before enforcement. See CJIS DLP Pack.'
            Mode             = $Mode
            ExchangeLocation = 'All'
            SharePointLocation = 'All'
            OneDriveLocation = 'All'
            TeamsLocation    = 'All'
            ErrorAction      = 'Stop'
        }
        if ($IncludeEndpoint) { $polParams['EndpointDlpLocation'] = 'All' }
        New-DlpCompliancePolicy @polParams | Out-Null

        # Content-match: the CJI classification (a named sensitive info type) with confidence + instance count.
        $sitMatch = @(@{ Name = $SitName; minconfidence = $Confidence; mincount = $MinCount })

        $ruleParams = @{
            Name                            = $RuleName
            Policy                          = $PolicyName
            ContentContainsSensitiveInformation = $sitMatch
            # In TEST mode the action is staged, surfaced as policy tips/alerts, and applied only after promote.
            BlockAccess                     = ($EnforceAction -eq 'BlockAccess')
            GenerateAlert                   = $true
            ErrorAction                     = 'Stop'
        }
        New-DlpComplianceRule @ruleParams | Out-Null

        Write-Host "CREATED: policy + rule in SIMULATION. No user is blocked in a Test* mode." -ForegroundColor Green
        Write-Host "Next: pilot on your ring, review matches with DLPCJIS-Report.ps1, tune, validate, then -PromoteToEnforce." -ForegroundColor Green
        Write-ChangeRecord -Action 'CreatePilot' -From '' -To $Mode
    } catch {
        Write-Error ("Create FAILED: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Host "WHATIF (default): no change made. Re-run with -Commit to create the SIMULATION policy." -ForegroundColor Yellow
}
