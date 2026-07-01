<#
.SYNOPSIS
    NSSSL-Discovery.ps1 — SSL inspection certificate-trust and decryption readiness on this device.
.DESCRIPTION
    PURPOSE
        Reports OS/build, whether an inspection (forward-trust) root is already in the device trusted
        root store, and surfaces obvious certificate-trust gaps before a decryption rollout.
        Netskope decryption-policy specifics are deferred to the Netskope console (not checked here).
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSSSL-Discovery.ps1
        Optional: -RootMatch 'Netskope'   (substring to match the inspection root subject/issuer)
    EXPECTED RESULTS
        OS build, a list of candidate inspection roots in LocalMachine\Root with thumbprint/expiry,
        and a readiness note (root present / not present).
.NOTES
    Workplace Marketplace — Network Solutions. Read-only.
#>
[CmdletBinding()] param([string]$RootMatch = 'Netskope')
Write-Host "`n=== SSL Inspection — certificate readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS               : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

$roots = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -match $RootMatch -or $_.Issuer -match $RootMatch }
if ($roots) {
    Write-Host ("Inspection root  : PRESENT ({0} match '{1}')" -f $roots.Count, $RootMatch) -ForegroundColor Green
    foreach ($r in $roots) {
        Write-Host ("  Subject : {0}" -f $r.Subject)
        Write-Host ("  Thumb   : {0}   NotAfter: {1}" -f $r.Thumbprint, $r.NotAfter)
    }
} else {
    Write-Host ("Inspection root  : NOT present (no LocalMachine\Root cert matches '{0}')" -f $RootMatch) -ForegroundColor Yellow
    Write-Host "  Deploy the inspection root via an Intune Trusted certificate profile, then re-run." -ForegroundColor Yellow
}
Write-Host "`nNote: Netskope decryption policy and bypass-list state are in the Netskope console (deferred)." -ForegroundColor DarkGray
