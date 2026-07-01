<#
.SYNOPSIS
    PSAUTO-Remediation.ps1 — sample remediation script (paired with PSAUTO-Validation.ps1). Safe by default.
.DESCRIPTION
    PURPOSE
        Brings a drifted device back to the desired known-good state. Use it as the remediation
        script in an Intune remediation; Intune runs it only when the detection script exited 1.
        SAFE BY DEFAULT: it runs in -WhatIf mode and only reports the changes it would make. Re-run
        with -WhatIf:$false (or set that default before uploading) to apply. The sample sets a
        registry value and starts a service; edit the DESIRED STATE block to match the detection script.
    HOW TO RUN
        In Intune: upload as the Remediation script in the same script package as PSAUTO-Validation.ps1.
        Run script in 64-bit PowerShell = Yes; run as SYSTEM (logged-on credentials = No).
        Locally (report-only): powershell -ExecutionPolicy Bypass -File .\PSAUTO-Remediation.ps1
        Locally (apply):       powershell -ExecutionPolicy Bypass -File .\PSAUTO-Remediation.ps1 -WhatIf:$false
    EXPECTED RESULTS
        -WhatIf (default): "WOULD: ..." lines and exit 0, nothing changed.
        Applied: "FIXED: ..." lines, the device set to the desired state, exit 0 on success / 1 on failure.
.NOTES
    Endpoint automation toolkit — the repeatable way. Idempotent; safe to re-run.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param()

# Default to report-only unless the caller explicitly asks to apply.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

# --- DESIRED STATE (must match PSAUTO-Validation.ps1) ------------------------
$RegPath  = 'HKLM:\SOFTWARE\Contoso\EndpointStandard'
$RegName  = 'BaselineApplied'
$RegValue = 1
$SvcName  = 'W32Time'
# -----------------------------------------------------------------------------

$failed = $false

try {
    # Registry value
    if (-not (Test-Path $RegPath)) {
        if ($PSCmdlet.ShouldProcess($RegPath, "Create registry key")) { New-Item -Path $RegPath -Force | Out-Null; Write-Output "FIXED: created $RegPath" }
        else { Write-Output "WOULD: create $RegPath" }
    }
    $cur = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue).$RegName
    if ($cur -ne $RegValue) {
        if ($PSCmdlet.ShouldProcess("$RegPath\$RegName", "Set value to $RegValue")) { New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType DWord -Force | Out-Null; Write-Output "FIXED: set $RegName=$RegValue" }
        else { Write-Output "WOULD: set $RegName=$RegValue (current '$cur')" }
    }

    # Service running
    $svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
        if ($PSCmdlet.ShouldProcess($SvcName, "Start service")) { Start-Service -Name $SvcName; Write-Output "FIXED: started $SvcName" }
        else { Write-Output "WOULD: start $SvcName (current $($svc.Status))" }
    } elseif (-not $svc) {
        Write-Output "NOTE: service '$SvcName' not found — cannot start"
    }
}
catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    $failed = $true
}

if ($failed) { exit 1 } else { exit 0 }
