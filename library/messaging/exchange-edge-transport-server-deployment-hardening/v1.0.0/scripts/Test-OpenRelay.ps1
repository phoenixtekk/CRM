<#
.SYNOPSIS
  Read-only open-relay + TLS posture validator for the Edge SMTP listener (Gate C).
.DESCRIPTION
  Probes the Edge's inbound SMTP service to confirm it does NOT relay for an anonymous sender to an
  EXTERNAL recipient (open relay), and optionally checks that STARTTLS is advertised. It performs an
  SMTP conversation up to RCPT TO and reads the server's response — it does NOT send DATA and does
  NOT deliver any message. Read-only / non-delivering by design.
.EXAMPLE
  .\Test-OpenRelay.ps1 -TargetHost edge01.mail.contoso.com
  # Probe relay acceptance for an anonymous external recipient. PASS = relay denied.
.EXAMPLE
  .\Test-OpenRelay.ps1 -TargetHost edge01.mail.contoso.com -CheckTls
  # Also confirm STARTTLS is advertised in the EHLO response.
  (PowerShell 5.1+/7+. Run from an external test point; use a non-accepted external recipient domain.)
.NOTES
  Expected results: PASS when the server returns a relay-denied code (e.g. 550/553/554 'Unable to
  relay') for an anonymous external RCPT TO; FAIL if it returns 250 (accepted = OPEN RELAY). With
  -CheckTls, PASS when STARTTLS appears in EHLO. No mail is delivered.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetHost,
    [int]$Port = 25,
    [string]$MailFrom = 'relay-test@external-probe.invalid',
    [string]$ExternalRcpt = 'relay-target@not-your-domain.invalid',
    [string]$HeloName = 'relay-probe.invalid',
    [switch]$CheckTls,
    [int]$TimeoutSec = 20
)

function Read-SmtpResponse([System.IO.StreamReader]$Reader) {
    $line = $Reader.ReadLine()
    return $line
}

Write-Host "Open-relay / TLS probe -> $TargetHost`:$Port (non-delivering, read-only)`n" -ForegroundColor Cyan
$client = New-Object System.Net.Sockets.TcpClient
try {
    $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($TimeoutSec))) {
        throw "Connection to $TargetHost`:$Port timed out."
    }
    $client.EndConnect($iar)
} catch {
    Write-Host "RESULT: FAIL (cannot connect) — $($_.Exception.Message)" -ForegroundColor Red
    return
}

$stream = $client.GetStream()
$stream.ReadTimeout = $TimeoutSec * 1000
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)
$writer.NewLine = "`r`n"; $writer.AutoFlush = $true

$tlsAdvertised = $false
$relayVerdict  = 'UNKNOWN'
try {
    $banner = Read-SmtpResponse $reader
    Write-Host "S: $banner" -ForegroundColor DarkGray

    $writer.WriteLine("EHLO $HeloName")
    # EHLO is multiline (250-...) — read until a line without the '-' continuation.
    do {
        $ehlo = Read-SmtpResponse $reader
        Write-Host "S: $ehlo" -ForegroundColor DarkGray
        if ($ehlo -match 'STARTTLS') { $tlsAdvertised = $true }
    } while ($ehlo -match '^\d{3}-')

    $writer.WriteLine("MAIL FROM:<$MailFrom>")
    $mf = Read-SmtpResponse $reader; Write-Host "S: $mf" -ForegroundColor DarkGray

    $writer.WriteLine("RCPT TO:<$ExternalRcpt>")
    $rcpt = Read-SmtpResponse $reader; Write-Host "S: $rcpt" -ForegroundColor DarkGray

    if ($rcpt -match '^250') {
        $relayVerdict = 'OPEN-RELAY'   # accepted an external recipient anonymously = FAIL
    } elseif ($rcpt -match '^(550|553|554|571|530)') {
        $relayVerdict = 'DENIED'       # relay denied = PASS
    } else {
        $relayVerdict = "OTHER ($($rcpt.Substring(0,[Math]::Min(3,$rcpt.Length))))"
    }

    $writer.WriteLine('QUIT')
} catch {
    Write-Warning "SMTP conversation error: $($_.Exception.Message)"
} finally {
    $writer.Dispose(); $reader.Dispose(); $stream.Dispose(); $client.Close()
}

Write-Host ''
if ($relayVerdict -eq 'DENIED') {
    Write-Host "OPEN-RELAY: PASS — anonymous external relay was DENIED ($relayVerdict)." -ForegroundColor Green
} elseif ($relayVerdict -eq 'OPEN-RELAY') {
    Write-Host "OPEN-RELAY: FAIL — server ACCEPTED an anonymous external recipient. This is an OPEN RELAY. Fix connector scope immediately." -ForegroundColor Red
} else {
    Write-Host "OPEN-RELAY: REVIEW — inconclusive response ($relayVerdict). Inspect the server reply and connector permissions." -ForegroundColor Yellow
}

if ($CheckTls) {
    if ($tlsAdvertised) { Write-Host 'TLS: PASS — STARTTLS advertised in EHLO.' -ForegroundColor Green }
    else                { Write-Host 'TLS: FAIL — STARTTLS NOT advertised. Verify the SMTP certificate (Cert - Edge SMTP - Prod) is enabled for SMTP.' -ForegroundColor Red }
}
Write-Host "`nGate C passes when relay is DENIED and (if checked) STARTTLS is advertised. Verify TLS protocol/cipher policy for your Exchange version/CU/OS." -ForegroundColor DarkGray
