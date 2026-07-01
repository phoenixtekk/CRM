<#
.SYNOPSIS
    PSAUTO-Validation.ps1 — sample Intune remediation DETECTION script (detect-then-remediate).
.DESCRIPTION
    PURPOSE
        Detects whether this device matches the desired known-good state. Use it as the detection
        script in an Intune remediation (proactive remediation). It exits 0 when the device is
        compliant (nothing to do) and exits 1 when it has drifted (Intune then runs the paired
        remediation, PSAUTO-Remediation.ps1). The sample checks a registry value and a service state;
        edit the DESIRED STATE block for your standard.
    HOW TO RUN
        In Intune: Devices > Manage devices > Remediations (Scripts and remediations) >
        Create script package > upload as the Detection script. Run in 64-bit PowerShell = Yes.
        Locally: powershell -ExecutionPolicy Bypass -File .\PSAUTO-Validation.ps1
    EXPECTED RESULTS
        Exit 0 + "COMPLIANT" when state matches; exit 1 + "NON-COMPLIANT: <reason>" when it does not.
.NOTES
    Endpoint automation toolkit — the repeatable way. Read-only (detection only; makes no changes).
#>
[CmdletBinding()] param()

# --- DESIRED STATE (edit for your environment) -------------------------------
$RegPath   = 'HKLM:\SOFTWARE\Contoso\EndpointStandard'   # registry key to check
$RegName   = 'BaselineApplied'                            # value name
$RegValue  = 1                                            # required value
$SvcName   = 'W32Time'                                    # service that must be Running
# -----------------------------------------------------------------------------

$reasons = @()

# Registry value check
$current = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue).$RegName
if ($current -ne $RegValue) { $reasons += "registry $RegName is '$current' (want '$RegValue')" }

# Service state check
$svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
if (-not $svc) { $reasons += "service '$SvcName' not found" }
elseif ($svc.Status -ne 'Running') { $reasons += "service '$SvcName' is $($svc.Status) (want Running)" }

if ($reasons.Count -eq 0) {
    Write-Output "COMPLIANT"
    exit 0
} else {
    Write-Output ("NON-COMPLIANT: " + ($reasons -join '; '))
    exit 1
}
