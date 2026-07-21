<#
.SYNOPSIS
    PROREM-Remediate-Template.ps1 — REMEDIATION template that DEFAULTS TO A DRY-RUN (preview).

.DESCRIPTION
    PURPOSE
        A copy-and-adapt REMEDIATION script that models the safe pattern: it DEFAULTS TO A DRY-RUN /
        PREVIEW ($DryRun = $true) so that, until you explicitly disable the preview, it LOGS EXACTLY
        WHAT IT WOULD CHANGE WITHOUT CHANGING ANYTHING. This is deliberate: prove the intended, minimal
        change from the log on a pilot device BEFORE you let it act on the fleet. It also demonstrates
        a MINIMAL fix (change the smallest thing that resolves the detected condition), IDEMPOTENCY
        (no further change on an already-fixed device), and LOGGING to a predictable on-device path.
        The worked example sets the Windows Time service (w32time) to Automatic and starts it.

        >>> SAFETY: This template WILL NOT CHANGE THE DEVICE while $DryRun is $true (its default).
        >>> To make it act, set $DryRun = $false (or pass -DryRun:$false) AFTER proving the preview
        >>> log on a pilot device — see Implementation Steps 2 and 8.

    HOW TO RUN
        This script is UPLOADED to Intune as the REMEDIATION script of a remediation package; it runs
        on-device (via the Intune Management Extension) ONLY on devices whose paired detection exited
        non-zero. Package it in the SAME run context as its detection (this example = SYSTEM).
        Pilot flow: upload the DRY-RUN version first, read the preview log, then upload the acting
        version ($DryRun = $false) once proven.

    GRAPH SCOPES
        None — this runs ON THE DEVICE via the Intune Management Extension, not against Graph.

    EXPECTED RESULTS
        DRY-RUN (default): logs "[WHATIF] would set …" and makes NO change; exit 0.
        ACTING ($DryRun=$false): applies the minimal fix, logs the action; exit 0 on success, exit 1
        if it cannot fix (e.g. insufficient rights / target absent). Idempotent: a device already
        healthy is left unchanged and still exits 0.

.NOTES
    White-label — Intune Solutions. REMEDIATION template — the one state-changer.
    DEFAULTS TO DRY-RUN. Minimal, idempotent, logged. Prove in preview + pilot before it acts.
#>
[CmdletBinding()]
param(
    # DEFAULT IS DRY-RUN: no change is made until this is explicitly set to $false.
    [bool]$DryRun = $true
)

$ServiceName   = 'w32time'
$WantStartType = 'Automatic'
$LogDir        = 'C:\ProgramData\Remediations'
$LogFile       = Join-Path $LogDir 'PROREM-ServiceHealth-w32time.log'

function Write-Log([string]$Message) {
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
    $line = "{0}  {1}" -f (Get-Date).ToString('s'), $Message
    Add-Content -Path $LogFile -Value $line
    Write-Output $Message   # also surfaced in the console remediation output column
}

$mode = if ($DryRun) { 'DRY-RUN (preview — no changes)' } else { 'ACTING (applying fix)' }
Write-Log "Remediation start — mode: $mode"

try {
    $svc = Get-Service -Name $ServiceName -ErrorAction Stop
    $startType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction Stop).StartMode
    $startOk  = ($startType -eq 'Auto') -or ($startType -eq $WantStartType)
    $statusOk = ($svc.Status -eq 'Running')

    # IDEMPOTENT: if already healthy, do nothing and succeed.
    if ($startOk -and $statusOk) {
        Write-Log "$ServiceName already healthy (StartMode=$startType, Status=$($svc.Status)) — no change."
        exit 0
    }

    # MINIMAL fix, one change at a time. In DRY-RUN we only LOG what we WOULD do.
    if (-not $startOk) {
        if ($DryRun) { Write-Log "[WHATIF] would set '$ServiceName' start type to $WantStartType (currently $startType)." }
        else         { Set-Service -Name $ServiceName -StartupType $WantStartType -ErrorAction Stop
                       Write-Log "Set '$ServiceName' start type to $WantStartType." }
    }
    if (-not $statusOk) {
        if ($DryRun) { Write-Log "[WHATIF] would start service '$ServiceName' (currently $($svc.Status))." }
        else         { Start-Service -Name $ServiceName -ErrorAction Stop
                       Write-Log "Started service '$ServiceName'." }
    }

    if ($DryRun) {
        Write-Log 'DRY-RUN complete — NO changes were made. Review this log, then deploy with $DryRun = $false to act.'
        exit 0
    }

    # Verify the fix took (post-change idempotent confirmation).
    Start-Sleep -Seconds 2
    $svc2 = Get-Service -Name $ServiceName -ErrorAction Stop
    if ($svc2.Status -eq 'Running') { Write-Log "Remediation succeeded — $ServiceName is $WantStartType/Running."; exit 0 }
    else { Write-Log "Remediation applied but $ServiceName is $($svc2.Status) — needs review."; exit 1 }
}
catch {
    Write-Log "Remediation FAILED for '$ServiceName': $($_.Exception.Message)"
    exit 1   # could not fix (e.g. insufficient rights / target absent)
}
