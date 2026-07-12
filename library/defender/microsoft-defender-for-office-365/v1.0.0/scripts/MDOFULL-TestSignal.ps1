<#
.SYNOPSIS
    MDOFULL-TestSignal.ps1 — generate (or tear down) BENIGN, simulated email test signal for the MDO proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Produces harmless, industry-standard email test signal so the MDO detection pipeline has
        something to catch during the proof-of-concept (Track B). It:
          1. Prints the exact steps to launch a Microsoft ATTACK SIMULATION TRAINING phishing campaign
             (Sim-MDOFULL-Pilot) to the pilot users — Microsoft's SAFE built-in simulator (P2).
          2. Sends a benign GTUBE spam-test message (the standard anti-spam test string, not spam).
          3. Sends a benign EICAR attachment message (the standard anti-malware test file, not malware)
             to exercise Safe Attachments.
          4. Sends a benign Safe Links test message to exercise time-of-click URL rewriting.
        NO real phishing, malware, or malicious URL is ever sent. Every message is tagged
        MDOFULL-TESTSIGNAL. -WhatIf shows what it would do.

        TEARDOWN MODE (-Teardown): rolls the PoC signal back — purges the MDOFULL-TESTSIGNAL messages
        from quarantine and prints the steps to end the simulation. Also -WhatIf-gated.
    HOW TO RUN
        # Generate signal — preview, then send:
        pwsh -File .\MDOFULL-TestSignal.ps1 -WhatIf
        pwsh -File .\MDOFULL-TestSignal.ps1 -From tester@contoso.com -To pilotuser@contoso.com
        # Tear the benign signal down — preview, then apply:
        pwsh -File .\MDOFULL-TestSignal.ps1 -Teardown -WhatIf
        pwsh -File .\MDOFULL-TestSignal.ps1 -Teardown

        Sending requires Microsoft.Graph.Authentication and Mail.Send (delegated) for the test sender.
        Teardown quarantine purge requires ExchangeOnlineManagement + Quarantine/Security Administrator.
    EXPECTED RESULTS
        Signal mode: the benign messages are actioned by MDO (rewritten / detonated / quarantined) and
        the simulation appears in Attack simulation training for the PoC to validate.
        Teardown mode: the benign MDOFULL-TESTSIGNAL messages purged, plus printed steps to end the sim.
.NOTES
    White-label. BENIGN test signal only (Attack Simulation, GTUBE, EICAR, benign URL). Never real threats.
    Coordinate with pilot users. Verify P2 for the simulation demo. Prevention config is the Mail Hygiene solution.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$From,
    [string]$To,
    [string]$Tag = 'MDOFULL-TESTSIGNAL',
    [switch]$Teardown
)

# =====================================================================================
# TEARDOWN MODE — purge the benign signal, print the steps to end the simulation.
# =====================================================================================
if ($Teardown) {
    Write-Host "`n=== MDOFULL — PoC signal teardown ($Tag) — preview by default ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    try { Get-OrganizationConfig -ErrorAction Stop | Out-Null } catch { Connect-ExchangeOnline -ShowBanner:$false }

    Write-Host "`n[1] Purge benign test messages from quarantine:" -ForegroundColor Cyan
    try {
        $items = Get-QuarantineMessage -Subject $Tag -ErrorAction SilentlyContinue
        if ($items) {
            foreach ($i in $items) {
                if ($PSCmdlet.ShouldProcess($i.Subject, "Delete quarantined benign test message")) {
                    Delete-QuarantineMessage -Identity $i.Identity -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Host "  Deleted quarantined item: $($i.Subject)" -ForegroundColor Green
                } else { Write-Host "  [WhatIf] Would delete quarantined item: $($i.Subject)" -ForegroundColor Yellow }
            }
        } else { Write-Host "  No quarantined '$Tag' items found." -ForegroundColor Gray }
    } catch {
        Write-Host ("  Quarantine purge needs the Quarantine/Security Administrator role: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }

    Write-Host "`n[2] End the phishing simulation (portal):" -ForegroundColor Cyan
    Write-Host "  security.microsoft.com -> Email & collaboration -> Attack simulation training ->" -ForegroundColor Gray
    Write-Host "  'Sim-MDOFULL-Pilot' -> cancel/complete the campaign. (No real payload was sent; nothing else to clean up.)" -ForegroundColor Gray
    Write-Host "`nConfirm with: MDOFULL-Validate.ps1  (no MDOFULL-TESTSIGNAL residue should remain)." -ForegroundColor Cyan
    return
}

# =====================================================================================
# SIGNAL MODE — generate the benign test signal.
# =====================================================================================
Write-Host "`n=== MDOFULL — benign test signal ($Tag) ===" -ForegroundColor Cyan
Write-Host "SAFE ONLY: Attack Simulation Training + GTUBE + EICAR + benign test URL. No real phishing/malware." -ForegroundColor Yellow

# 1) Attack Simulation Training (portal-driven, safe).
Write-Host "`n[1] Launch the benign phishing simulation (Attack Simulation Training, P2):" -ForegroundColor Cyan
Write-Host "  security.microsoft.com -> Email & collaboration -> Attack simulation training -> Launch a simulation." -ForegroundColor Gray
Write-Host "  Name it 'Sim-MDOFULL-Pilot', pick a BUILT-IN benign template," -ForegroundColor Gray
Write-Host "  target 'Grp-MDOFULL-PilotUsers-Pilot'. This is Microsoft's SAFE simulator. Verify P2 availability." -ForegroundColor Gray

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
# EICAR standard anti-malware test string (assembled at runtime).
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

Write-Host ("`nSignal generated at: {0}  (record this for latency comparison)." -f (Get-Date).ToString('u')) -ForegroundColor Cyan
Write-Host "Next: MDOFULL-Validate.ps1  (then MDOFULL-Report.ps1 to capture evidence)" -ForegroundColor Cyan
