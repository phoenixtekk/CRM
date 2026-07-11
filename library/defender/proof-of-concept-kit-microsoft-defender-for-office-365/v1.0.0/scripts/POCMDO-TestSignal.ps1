<#
.SYNOPSIS
    POCMDO-TestSignal.ps1 — generate BENIGN, simulated email test signal for the MDO PoC. Safe only.
.DESCRIPTION
    PURPOSE
        Produces harmless, industry-standard email test signal so the MDO detection pipeline has
        something to catch. It:
          1. Prints the exact steps to launch a Microsoft ATTACK SIMULATION TRAINING phishing
             campaign to the pilot users (Microsoft's SAFE built-in phishing simulator, P2).
          2. Sends a benign GTUBE spam-test message (the standard anti-spam test string, not spam).
          3. Sends a benign EICAR attachment message (the standard anti-malware test file, not malware)
             to exercise Safe Attachments.
          4. Sends a benign Safe Links test message to exercise time-of-click URL rewriting.
        NO real phishing, malware, or malicious URL is ever sent. -WhatIf shows what it would do.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDO-TestSignal.ps1 -WhatIf
        # Send benign signal (From must be a permitted test sender; To is a pilot mailbox):
        powershell -ExecutionPolicy Bypass -File .\POCMDO-TestSignal.ps1 -From tester@contoso.com -To pilotuser@contoso.com
        Requires Microsoft.Graph.Authentication and Mail.Send (delegated) for the test sender.
    EXPECTED RESULTS
        The benign messages are actioned by MDO (rewritten / detonated / quarantined), and the
        phishing simulation appears in Attack simulation training for the PoC to validate.
.NOTES
    White-label. BENIGN test signal only (Attack Simulation, GTUBE, EICAR, benign URL). Never real threats.
    Coordinate with pilot users. Verify P2 for the simulation demo.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$From,
    [string]$To,
    [string]$Tag = 'MDO-PoC-TESTSIGNAL'
)

Write-Host "`n=== POCMDO — benign test signal ($Tag) ===" -ForegroundColor Cyan
Write-Host "SAFE ONLY: Attack Simulation Training + GTUBE + EICAR + benign test URL. No real phishing/malware." -ForegroundColor Yellow

# 1) Attack Simulation Training (portal-driven, safe).
Write-Host "`n[1] Launch the benign phishing simulation (Attack Simulation Training, P2):" -ForegroundColor Cyan
Write-Host "  security.microsoft.com -> Email & collaboration -> Attack simulation training -> Launch a simulation." -ForegroundColor Gray
Write-Host "  Name it 'MDO PoC Phish Simulation - Pilot Users - Pilot', pick a BUILT-IN benign template," -ForegroundColor Gray
Write-Host "  target 'MDO PoC - Pilot Users - Pilot'. This is Microsoft's SAFE simulator. Verify P2 availability." -ForegroundColor Gray

if (-not $From -or -not $To) {
    Write-Host "`n[2-4] Provide -From (permitted test sender) and -To (pilot mailbox) to send the GTUBE/EICAR/Safe Links tests." -ForegroundColor Yellow
    return
}

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Mail.Send' -NoWelcome | Out-Null }

function Send-TestMail($subject, $bodyText, $attachName, $attachContentB64) {
    $msg = @{
        message = @{
            subject = "$Tag - $subject"
            body = @{ contentType = 'Text'; content = $bodyText }
            toRecipients = @(@{ emailAddress = @{ address = $To } })
        }
        saveToSentItems = $false
    }
    if ($attachName) {
        $msg.message.attachments = @(@{ '@odata.type' = '#microsoft.graph.fileAttachment'; name = $attachName; contentBytes = $attachContentB64 })
    }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$From/sendMail" -Body ($msg | ConvertTo-Json -Depth 8) -ContentType 'application/json'
}

# GTUBE standard anti-spam test string (assembled at runtime).
$gtube = 'XJS*C4JDBQADN1.NSBN3*2IDNEN*' + 'GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X'
# EICAR standard anti-malware test string.
$eicar = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$' + 'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicarB64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($eicar))
# Benign Safe Links test URL (a harmless, well-known safe domain).
$linkBody = "Benign Safe Links test. Click-time protection should rewrite: https://www.example.com/poc-safelinks-test"

if ($PSCmdlet.ShouldProcess("$To", "Send benign GTUBE spam-test message")) {
    try { Send-TestMail 'GTUBE spam test' "Benign anti-spam test string below.`n$gtube" $null $null; Write-Host "  Sent GTUBE spam-test message." -ForegroundColor Green }
    catch { Write-Host ("  GTUBE send failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} else { Write-Host "  [WhatIf] Would send GTUBE spam-test message to $To." -ForegroundColor Yellow }

if ($PSCmdlet.ShouldProcess("$To", "Send benign EICAR attachment message")) {
    try { Send-TestMail 'EICAR attachment test' 'Benign anti-malware attachment test (EICAR).' 'eicar-poc.txt' $eicarB64; Write-Host "  Sent EICAR attachment message (Safe Attachments should action it)." -ForegroundColor Green }
    catch { Write-Host ("  EICAR send failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} else { Write-Host "  [WhatIf] Would send EICAR attachment message to $To." -ForegroundColor Yellow }

if ($PSCmdlet.ShouldProcess("$To", "Send benign Safe Links test message")) {
    try { Send-TestMail 'Safe Links test' $linkBody $null $null; Write-Host "  Sent Safe Links test message (URL should be rewritten)." -ForegroundColor Green }
    catch { Write-Host ("  Safe Links send failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} else { Write-Host "  [WhatIf] Would send Safe Links test message to $To." -ForegroundColor Yellow }

Write-Host ("`nSignal generated at: {0}  (record this for scorecard latency)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
Write-Host "Next: POCMDO-Validate.ps1" -ForegroundColor Cyan
