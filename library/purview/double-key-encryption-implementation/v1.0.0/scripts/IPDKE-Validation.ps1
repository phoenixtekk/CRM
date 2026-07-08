<#
.SYNOPSIS
    IPDKE-Validation.ps1 — confirm the DKE label, its endpoint URL, and the publishing policy. Read-only.
.DESCRIPTION
    PURPOSE
        Checks that the expected named objects for a Double Key Encryption rollout are in place: the
        DKE sensitivity label exists with encryption enabled and the expected endpoint URL, the label
        policy is published to the pilot group, and (optionally) the DKE endpoint responds over HTTPS.
        Use it after Implementation Steps 6–7 and after each expansion. It changes nothing.
    HOW TO RUN
        Install-Module ExchangeOnlineManagement -Scope CurrentUser
        powershell -ExecutionPolicy Bypass -File .\IPDKE-Validation.ps1 `
            -LabelName 'Sensitivity Label - Ultra Confidential (DKE) - Named Group' `
            -PolicyName 'Label Policy - DKE Ultra Confidential - DKE Pilot' `
            -DkeEndpointUrl 'https://dke.contoso.com/DKE-Key-01'
        Sign in as a Compliance Administrator (or Information Protection Admin) when prompted.
    EXPECTED RESULTS
        PASS/FAIL lines for: label exists, encryption enabled, DKE endpoint URL matches, policy exists
        and is enabled, and (if -DkeEndpointUrl given) the endpoint returns HTTP 200 over HTTPS.
.NOTES
    White-label — Purview Solutions. Read-only. No secrets. No changes to any object.
    Uses Get-Label / Get-LabelPolicy and a read-only Invoke-WebRequest GET for endpoint reachability.
#>
[CmdletBinding()] param(
    [string]$LabelName      = 'Sensitivity Label - Ultra Confidential (DKE) - Named Group',
    [string]$PolicyName     = 'Label Policy - DKE Ultra Confidential - DKE Pilot',
    [string]$PilotGroupName = 'Purview - DKE Pilot Users',
    [string]$DkeEndpointUrl = ''
)

function Write-Result([string]$name,[bool]$ok,[string]$detail=''){
    $tag = if($ok){'PASS'}else{'FAIL'}; $col = if($ok){'Green'}else{'Red'}
    Write-Host ("  [{0}] {1}{2}" -f $tag,$name,$(if($detail){" — $detail"}else{''})) -ForegroundColor $col
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host ("`n=== DKE validation — '{0}' ===" -f $LabelName) -ForegroundColor Cyan

# 1. Label exists
$label = Get-Label -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $LabelName } | Select-Object -First 1
Write-Result 'DKE label exists' ([bool]$label)

# 2. Encryption enabled
if ($label) {
    Write-Result 'Encryption enabled on the label' ([bool]$label.EncryptionEnabled)

    # 3. DKE endpoint URL present / matches
    $url = $null
    foreach ($p in @('EncryptionDoubleKeyEncryptionUrl','DoubleKeyEncryptionUrl','EncryptionDoubleKeyEncryption')) {
        if ($label.PSObject.Properties.Name -contains $p -and $label.$p) { $url = $label.$p; break }
    }
    if ($DkeEndpointUrl) {
        Write-Result 'Label DKE endpoint URL matches expected' ($url -eq $DkeEndpointUrl) ("found: $url")
    } else {
        Write-Result 'Label has a DKE endpoint URL' ([bool]$url) ("found: $url")
    }
}

# 4. Policy exists and enabled
$pol = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $PolicyName } | Select-Object -First 1
Write-Result 'Label policy exists' ([bool]$pol)
if ($pol) { Write-Result 'Label policy enabled' ([bool]$pol.Enabled) }

# 5. Endpoint reachable (read-only GET)
if ($DkeEndpointUrl) {
    try {
        $resp = Invoke-WebRequest -Uri $DkeEndpointUrl -Method Get -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        Write-Result 'DKE endpoint reachable over HTTPS' (($resp.StatusCode -eq 200) -and $DkeEndpointUrl.StartsWith('https://')) ("HTTP $($resp.StatusCode)")
    } catch {
        Write-Result 'DKE endpoint reachable over HTTPS' $false $_.Exception.Message
    }
}

Write-Host "`nValidation complete." -ForegroundColor Cyan
Write-Host ("Note: confirm the label policy targets '{0}' in the Purview portal (assignment is not always exposed to PowerShell)." -f $PilotGroupName) -ForegroundColor Gray
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
