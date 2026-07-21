<#
.SYNOPSIS
    PROREM-Detect-Template.ps1 — read-only DETECTION template for an Intune Proactive Remediation.

.DESCRIPTION
    PURPOSE
        A copy-and-adapt DETECTION script that models the safe pattern: it OBSERVES ONLY (makes no
        changes), is IDEMPOTENT (same verdict every run), and reports its result solely through the
        EXIT-CODE CONTRACT — exit 0 = healthy (do nothing), exit 1 = issue found (run the paired
        remediation). The worked example checks that the Windows Time service (w32time) is set to
        Automatic and is Running; replace the CONDITION block with your own read-only check.

    HOW TO RUN
        This script is UPLOADED to Intune as the DETECTION script of a remediation package
        (Reports > Endpoint analytics > Remediations > Create — verify path with Microsoft docs).
        Intune's management extension runs it on-device on the assignment's schedule. You do not run
        it manually in production, though you can run it locally on a pilot device to test the verdict.
        Run context: this example touches a machine service, so package it to run as SYSTEM (Run using
        logged-on credentials = No). A check of HKCU/user data would instead run in the USER context.

    GRAPH SCOPES
        None — this runs ON THE DEVICE via the Intune Management Extension, not against Graph.

    EXPECTED RESULTS
        Writes one human-readable line (surfaced in the console's detection output column) and sets
        the exit code. Healthy device -> "…healthy" + exit 0. Affected device -> "…issue" + exit 1.
        It NEVER changes the device — detection is read-only by contract.

.NOTES
    White-label — Intune Solutions. DETECTION template — read-only, idempotent, exit-code contract.
    Detection must NOT change the device. Keep all fixes in the paired remediation script.
#>

# --- CONDITION (replace this block with your own READ-ONLY check) -----------------------------
# Rule: report an issue ONLY when the observed state is wrong. Do not modify anything here.
$ServiceName    = 'w32time'
$WantStartType  = 'Automatic'   # desired start type
$WantStatus     = 'Running'     # desired run status

try {
    $svc = Get-Service -Name $ServiceName -ErrorAction Stop
    # Start type via CIM (Get-Service StartType can vary by PS version)
    $startType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction Stop).StartMode
    # Win32 StartMode 'Auto' maps to 'Automatic'
    $startOk  = ($startType -eq 'Auto') -or ($startType -eq $WantStartType)
    $statusOk = ($svc.Status -eq $WantStatus)

    if ($startOk -and $statusOk) {
        Write-Output "$ServiceName healthy (StartMode=$startType, Status=$($svc.Status))."
        exit 0    # HEALTHY — do nothing
    }
    else {
        Write-Output "$ServiceName issue (StartMode=$startType, Status=$($svc.Status); want $WantStartType/$WantStatus)."
        exit 1    # ISSUE FOUND — run the paired remediation
    }
}
catch {
    # If the very thing you check cannot be read, report an issue so the remediation (or an admin) looks.
    Write-Output "Detection could not read service '$ServiceName': $($_.Exception.Message)"
    exit 1
}
# ----------------------------------------------------------------------------------------------
