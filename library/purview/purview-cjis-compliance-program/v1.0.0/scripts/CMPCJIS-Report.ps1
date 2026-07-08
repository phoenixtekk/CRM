<#
.SYNOPSIS
    CMPCJIS-Report.ps1 - produce the formal-audit evidence package: control map + live Purview state (read-only).
.DESCRIPTION
    PURPOSE
        Assembles "CJIS Evidence - Formal Audit - Package" (CSV + HTML) for the auditor/CSA. It reads the
        control map (CJIS policy area -> Purview capability -> implementing object) and enriches each mapped
        object with its CURRENT live state (label present/encryption, DLP mode, retention enabled, audit
        logging on), so each control shows: the implementing Purview object, its state, and the audit
        reference. Read-only against Purview - the only writes are the evidence files. Whether a control
        SATISFIES its CJIS requirement is the CSA/auditor determination - the package is evidence, not a
        pass/fail on compliance.
    HOW TO RUN
        .\CMPCJIS-Report.ps1 -ControlMapCsv .\CJIS-Control-Map.csv -OutDir .
        ControlMapCsv columns: PolicyArea,PurviewCapability,ImplementingObject,ObjectType,Status,Owner
        (ObjectType = Label|Dlp|Retention|Audit). If omitted, a default map is generated from this program's
        named objects. Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). No secrets.
    EXPECTED RESULTS
        An HTML + CSV evidence package. PASS signal: every mapped control resolves to a live object state or an
        explicit "not found / verify" - never a fabricated state. Deliver via the secured channel (Req 2.8).
.NOTES
    Purview category - CJIS Compliance Program. Read-only vs Purview. Control satisfaction, retention
    schedule, and environment authorization are CSA/auditor/records determinations. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [string]$ControlMapCsv,
    [string]$LabelName     = 'CJI - Protected - Label',
    [string]$DlpPolicyName = 'CJI Protection - Exfiltration - Policy',
    [string]$RetentionName = 'CJI Records - Retention - Policy',
    [string]$UserPrincipalName,
    [string]$OutDir = "."
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
$asOf = (Get-Date).ToUniversalTime()

# --- Control map (from CSV or a default derived from this program's objects) ---
if ($ControlMapCsv -and (Test-Path $ControlMapCsv)) {
    $map = @(Import-Csv -Path $ControlMapCsv)
} else {
    Write-Host 'No control map supplied - generating a DEFAULT map from this program''s named objects (verify policy-area numbers against your CJIS Security Policy version).' -ForegroundColor Yellow
    $map = @(
        [pscustomobject]@{ PolicyArea='Auditing & Accountability'; PurviewCapability='Unified audit log / Audit Premium'; ImplementingObject='(tenant audit config)'; ObjectType='Audit';     Status='In scope'; Owner='' }
        [pscustomobject]@{ PolicyArea='Access Control / Info Protection'; PurviewCapability='Sensitivity label + encryption'; ImplementingObject=$LabelName; ObjectType='Label'; Status='In scope'; Owner='' }
        [pscustomobject]@{ PolicyArea='Information Flow / Exfiltration'; PurviewCapability='Data Loss Prevention'; ImplementingObject=$DlpPolicyName; ObjectType='Dlp'; Status='In scope'; Owner='' }
        [pscustomobject]@{ PolicyArea='Media Protection / Records'; PurviewCapability='Retention & records'; ImplementingObject=$RetentionName; ObjectType='Retention'; Status='In scope'; Owner='' }
    )
}

# --- Connect (read-only) and resolve live state per object ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Write-Host 'ExchangeOnlineManagement not installed.' -ForegroundColor Red; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }
$auditOn = $null
try { Connect-ExchangeOnline @cp -ShowBanner:$false -ErrorAction Stop | Out-Null; $auditOn = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled } catch {}
try { if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null } } catch {}

function Resolve-State($type,$name){
    switch ($type) {
        'Audit'     { if ($null -eq $auditOn) { return 'CHECK: audit config unreadable' } return $(if($auditOn){'Audit logging ON'}else{'Audit logging OFF'}) }
        'Label'     { try { $l=Get-Label -Identity $name -ErrorAction Stop; return ("Present; Encryption={0}" -f $(if($l.EncryptionEnabled){'Yes'}else{'verify in portal'})) } catch { return 'NOT FOUND - verify' } }
        'Dlp'       { try { $d=Get-DlpCompliancePolicy -Identity $name -ErrorAction Stop; return ("Present; Mode={0}" -f $d.Mode) } catch { return 'NOT FOUND - verify' } }
        'Retention' { try { $r=Get-RetentionCompliancePolicy -Identity $name -ErrorAction Stop; return ("Present; Enabled={0}" -f $r.Enabled) } catch { return 'NOT FOUND - verify' } }
        default     { return 'verify manually (portal-read)' }
    }
}

$evidence = New-Object System.Collections.Generic.List[object]
foreach ($c in $map) {
    $state = Resolve-State "$($c.ObjectType)" "$($c.ImplementingObject)"
    $evidence.Add([pscustomobject]@{
        PolicyArea        = $c.PolicyArea
        PurviewCapability = $c.PurviewCapability
        ImplementingObject= $c.ImplementingObject
        LiveState         = $state
        AuditReference    = 'Unified audit log (Search-UnifiedAuditLog) / control map'
        Status            = $c.Status
        Owner             = $c.Owner
        AsOf              = $asOf.ToString('u')
        Determination     = 'Control satisfaction = CSA/auditor determination'
    })
}

# --- Emit CSV + HTML ---
$csvPath  = Join-Path $OutDir 'CJIS-Evidence-Formal-Audit-Package.csv'
$htmlPath = Join-Path $OutDir 'CJIS-Evidence-Formal-Audit-Package.html'
$evidence | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("<html><head><meta charset='utf-8'><title>CJIS Evidence - Formal Audit - Package</title></head><body style='font-family:Segoe UI,Arial,sans-serif'>")
[void]$sb.Append("<h2>CJIS Evidence &ndash; Formal Audit &ndash; Package</h2><p>As of $($asOf.ToString('u')) &middot; Purview technical controls (evidence, not a compliance determination)</p>")
[void]$sb.Append("<table cellpadding='6' style='border-collapse:collapse'><tr style='background:#f0f0f0'><th style='border:1px solid #ccc'>CJIS Policy Area</th><th style='border:1px solid #ccc'>Purview Capability</th><th style='border:1px solid #ccc'>Implementing Object</th><th style='border:1px solid #ccc'>Live State</th><th style='border:1px solid #ccc'>Status</th><th style='border:1px solid #ccc'>Owner</th></tr>")
foreach ($e in $evidence) {
    $bad = ("$($e.LiveState)" -match 'NOT FOUND|OFF|CHECK')
    $col = if ($bad) { '#b42318' } else { '#1a7f37' }
    [void]$sb.Append("<tr><td style='border:1px solid #ddd'>$($e.PolicyArea)</td><td style='border:1px solid #ddd'>$($e.PurviewCapability)</td><td style='border:1px solid #ddd'>$($e.ImplementingObject)</td><td style='border:1px solid #ddd;color:$col'>$($e.LiveState)</td><td style='border:1px solid #ddd'>$($e.Status)</td><td style='border:1px solid #ddd'>$($e.Owner)</td></tr>")
}
[void]$sb.Append("</table>")
[void]$sb.Append("<p style='color:#666;font-size:12px'>Policy-area numbering must be verified against your current CJIS Security Policy version with your CSA/CSO. Whether these controls SATISFY CJIS, whether the environment (GCC High / Azure Government) is authorized, and the records-retention schedule are CSA / auditor / records determinations. This package is evidence of the technical control state, not an attestation of compliance.</p></body></html>")
$sb.ToString() | Set-Content -Path $htmlPath -Encoding UTF8

Write-Section 'CJIS Evidence - Formal Audit - Package'
$evidence | Format-Table PolicyArea,ImplementingObject,LiveState,Status -AutoSize | Out-String | Write-Host
Write-Host ("Evidence package -> {0}  (+ {1})" -f $htmlPath, $csvPath) -ForegroundColor Green
$gaps = @($evidence | Where-Object { "$($_.LiveState)" -match 'NOT FOUND|OFF|CHECK' }).Count
if ($gaps -gt 0) { Write-Host ("$gaps control(s) show NOT FOUND/OFF/CHECK - remediate or annotate before the formal audit.") -ForegroundColor Yellow }
Write-Host 'Deliver via the secured channel (Requirement 2.8). Control satisfaction is the CSA/auditor determination.' -ForegroundColor Yellow
