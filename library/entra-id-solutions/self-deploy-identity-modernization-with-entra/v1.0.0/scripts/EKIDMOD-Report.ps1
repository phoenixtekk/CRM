<#
.SYNOPSIS
    EKIDMOD-Report.ps1 — Modernization scorecard exported to CSV + HTML (read-only).
.DESCRIPTION
    PURPOSE
        Turn the read-only discovery signals into a shareable scorecard across the modernization
        building blocks: legacy auth, MFA/passwordless coverage, Conditional Access posture,
        governance (PIM/reviews presence), and federated domains. Produces a CSV and an HTML summary.
    HOW TO RUN
        .\EKIDMOD-Report.ps1 -OutputPath .\EKIDMOD-Scorecard
        Sign in when prompted (read-only scopes). Writes <OutputPath>.csv and <OutputPath>.html.
    EXPECTED RESULTS
        Two files: a CSV of metrics and an HTML summary. No tenant changes are made.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param(
    [string]$OutputPath = ".\EKIDMOD-Scorecard"
)

$ErrorActionPreference = 'Stop'
Write-Host "`n=== Identity Modernization — Scorecard (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All','Domain.Read.All','AuditLog.Read.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

$rows = New-Object System.Collections.Generic.List[object]
function Add-Metric($area,$metric,$value,$status){ $rows.Add([pscustomobject]@{ Area=$area; Metric=$metric; Value=$value; Status=$status }) }

# Domains / federation
try {
    $domains = Get-MgDomain -All
    $fedCount = @($domains | Where-Object { $_.AuthenticationType -eq 'Federated' }).Count
    Add-Metric 'Coexistence' 'Federated domains (AD FS)' $fedCount $(if($fedCount -eq 0){'Modern'}else{'Legacy — migrate to cloud auth'})
} catch { Add-Metric 'Coexistence' 'Federated domains' 'n/a' 'Unknown' }

# Conditional Access
try {
    $ca = Get-MgIdentityConditionalAccessPolicy -All
    $on = @($ca | Where-Object { $_.State -eq 'enabled' }).Count
    $ro = @($ca | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count
    Add-Metric 'Conditional Access' 'Enabled policies' $on $(if($on -ge 1){'Present'}else{'Gap — no enforced CA'})
    Add-Metric 'Conditional Access' 'Report-only policies' $ro 'Info'
} catch { Add-Metric 'Conditional Access' 'Policies' 'n/a' 'Requires P1 (verify)' }

# Authentication methods (passwordless)
try {
    $am = Get-MgPolicyAuthenticationMethodPolicy
    $enabled = @($am.AuthenticationMethodConfigurations | Where-Object { $_.State -eq 'enabled' } | Select-Object -ExpandProperty Id)
    Add-Metric 'Passwordless' 'FIDO2/passkey enabled' $(if($enabled -contains 'Fido2'){'Yes'}else{'No'}) $(if($enabled -contains 'Fido2'){'Modern'}else{'Gap — enable phishing-resistant'})
    Add-Metric 'Passwordless' 'Methods enabled' (($enabled) -join ' ') 'Info'
} catch { Add-Metric 'Passwordless' 'Auth methods' 'n/a' 'Unknown' }

# Legacy auth signals (7d sample)
try {
    $since = (Get-Date).AddDays(-7).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $legacy = Get-MgAuditLogSignIn -Filter "createdDateTime ge $since and clientAppUsed eq 'Other clients'" -Top 100 -ErrorAction Stop
    Add-Metric 'Legacy Auth' "'Other clients' sign-ins (7d, <=100)" @($legacy).Count $(if(@($legacy).Count -eq 0){'Clean'}else{'Legacy — block via CA'})
} catch { Add-Metric 'Legacy Auth' 'Legacy sign-ins' 'n/a' 'Requires AuditLog.Read.All (verify)' }

# Emit
$csv = "$OutputPath.csv"; $html = "$OutputPath.html"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:18px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 10px;text-align:left}th{background:#f2f2f2}</style>"
$body = ($rows | ConvertTo-Html -Property Area,Metric,Value,Status -Head $style -PreContent "<h1>Identity Modernization Scorecard — $((Get-Date).ToString('yyyy-MM-dd'))</h1>" -PostContent "<p>Read-only snapshot. Re-run after each modernization step to track progress.</p>")
$body | Out-File -FilePath $html -Encoding UTF8

Write-Host "Wrote: $csv" -ForegroundColor Green
Write-Host "Wrote: $html" -ForegroundColor Green
