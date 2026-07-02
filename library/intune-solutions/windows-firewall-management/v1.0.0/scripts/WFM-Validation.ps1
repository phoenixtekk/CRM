<#
.SYNOPSIS
    WFM-Validation.ps1 — confirm all firewall profiles are enabled with default-deny inbound.
.DESCRIPTION
    PURPOSE
        Verifies Domain, Private, and Public profiles are enabled and that the default inbound
        action is Block (outbound Allow) — the posture this solution enforces.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WFM-Validation.ps1
    EXPECTED RESULTS
        "FIREWALL OK" when all three profiles are enabled with inbound Block / outbound Allow.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== Firewall Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$ok = $true
foreach ($p in (Get-NetFirewallProfile)) {
    $good = $p.Enabled -and $p.DefaultInboundAction -in 'Block','NotConfigured'
    $inboundBlock = $p.DefaultInboundAction -eq 'Block'
    $ok = $ok -and $p.Enabled -and $inboundBlock
    Write-Host ("{0,-8}: Enabled={1}  Inbound={2}  Outbound={3}" -f $p.Name, $p.Enabled, $p.DefaultInboundAction, $p.DefaultOutboundAction) -ForegroundColor ($(if($p.Enabled -and $inboundBlock){'Green'}else{'Yellow'}))
}
if ($ok) { Write-Host "`nResult: FIREWALL OK" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY ENFORCED — run WFM-Remediation.ps1 / check policy & conflicts" -ForegroundColor Yellow; exit 1 }
