<#
.SYNOPSIS
    NSSSL-Validation.ps1 — confirm the inspection root is trusted and its chain validates.
.DESCRIPTION
    PURPOSE
        Verifies the SSL inspection (forward-trust) root is present in the device trusted root store
        and that its certificate chain builds without error — the prerequisite for warning-free
        decryption. Netskope decryption-policy state is deferred to the Netskope console.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSSSL-Validation.ps1
        Optional: -RootMatch 'Netskope'
    EXPECTED RESULTS
        "INSPECTION TRUST OK" when a matching root is present and the chain validates (exit 0);
        otherwise a remediation hint (exit 1).
.NOTES
    Workplace Marketplace — Network Solutions. Read-only.
#>
[CmdletBinding()] param([string]$RootMatch = 'Netskope')
Write-Host "=== SSL Inspection Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$root = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -match $RootMatch -or $_.Issuer -match $RootMatch } | Select-Object -First 1

if (-not $root) {
    Write-Host ("Inspection root present : NO (no match for '{0}')" -f $RootMatch) -ForegroundColor Yellow
    Write-Host "`nResult: NOT TRUSTED — deploy/sync the Intune Trusted certificate profile (NSSSL-Remediation.ps1)" -ForegroundColor Yellow
    exit 1
}
Write-Host ("Inspection root present : YES  ({0})" -f $root.Subject) -ForegroundColor Green
Write-Host ("Thumbprint              : {0}   NotAfter: {1}" -f $root.Thumbprint, $root.NotAfter)

$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$ok = $chain.Build($root)
Write-Host ("Chain validates         : {0}" -f ($(if($ok){'YES'}else{'NO'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
if (-not $ok) { foreach ($s in $chain.ChainStatus) { Write-Host ("  - {0}: {1}" -f $s.Status, $s.StatusInformation.Trim()) -ForegroundColor Yellow } }

if ($ok) { Write-Host "`nResult: INSPECTION TRUST OK" -ForegroundColor Green; exit 0 }
else     { Write-Host "`nResult: TRUST INCOMPLETE — check intermediate deployment / expiry" -ForegroundColor Yellow; exit 1 }
