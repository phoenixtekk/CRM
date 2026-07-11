<#
.SYNOPSIS
    CLDSEC-Discovery.ps1 — read-only whole-estate discovery across the six Zero-Trust pillars.
.DESCRIPTION
    PURPOSE
        Builds the point-in-time posture baseline for the maturity score. Enumerates configuration across
        Identity, Endpoints, Data, Applications, Infrastructure, and Network using Microsoft Graph and Az,
        and writes a per-pillar posture set (CSV/JSON) into the findings folder. Every call is read-only;
        nothing in the tenant is changed. Coverage gaps (a product owned but not enabled) are captured as
        posture rows so the report can flag them as findings.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Policy.Read.All","Directory.Read.All","DeviceManagementConfiguration.Read.All"
        Connect-AzAccount
        pwsh -File .\CLDSEC-Discovery.ps1 -Label "CloudSecAssessment - Estate - Full" -OutputFolder "<secure path>"
        Run CLDSEC-Validate.ps1 first. *Verify current Graph/Az cmdlet and property names for your tenant.*
    EXPECTED RESULTS
        A per-pillar posture table on screen and per-pillar CSV/JSON files in the output folder. Read-only.
.NOTES
    White-label. Read-only. Makes no changes. Best-effort across API surfaces — verify property names.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Label,
    [Parameter(Mandatory=$true)][string]$OutputFolder,
    [string[]]$SubscriptionIds
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$posture = New-Object System.Collections.Generic.List[object]
function Add-Row([string]$Pillar,[string]$Control,[string]$State,[string]$Detail){
    $posture.Add([pscustomobject]@{ Pillar=$Pillar; Control=$Control; State=$State; Detail=$Detail })
}
Write-Host "CLDSEC discovery — '$Label' (read-only)`n" -ForegroundColor Cyan

# ============================ IDENTITY =======================================
Write-Host "Pillar: Identity" -ForegroundColor Cyan
try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction SilentlyContinue
    $enabled = @($caPolicies | Where-Object { $_.State -eq 'enabled' })
    Add-Row 'Identity' 'Conditional Access policies' (if ($enabled.Count) {'present'} else {'GAP'}) "$($enabled.Count) enabled / $((@($caPolicies)).Count) total"
} catch { Add-Row 'Identity' 'Conditional Access policies' 'unknown' $_.Exception.Message }

try {
    $admins = Get-MgDirectoryRole -All -ErrorAction SilentlyContinue
    $privCount = 0
    foreach ($r in $admins) {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $r.Id -ErrorAction SilentlyContinue
        $privCount += (@($members)).Count
    }
    Add-Row 'Identity' 'Privileged role assignments' (if ($privCount -gt 20){'REVIEW'}else{'ok'}) "$privCount active directory-role member assignments (minimize + PIM)"
} catch { Add-Row 'Identity' 'Privileged role assignments' 'unknown' $_.Exception.Message }

try {
    $authMethods = Get-MgPolicyAuthenticationMethodPolicy -ErrorAction SilentlyContinue
    Add-Row 'Identity' 'Authentication methods policy' (if ($authMethods){'present'}else{'GAP'}) 'Confirm phishing-resistant methods enabled (verify)'
} catch { Add-Row 'Identity' 'Authentication methods policy' 'unknown' $_.Exception.Message }

# ============================ ENDPOINTS ======================================
Write-Host "Pillar: Endpoints" -ForegroundColor Cyan
try {
    $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction SilentlyContinue
    $total = (@($devices)).Count
    $compliant = (@($devices | Where-Object { $_.ComplianceState -eq 'compliant' })).Count
    Add-Row 'Endpoints' 'Intune device compliance' (if ($total -eq 0){'GAP'}elseif($compliant/[math]::Max($total,1) -lt 0.8){'REVIEW'}else{'ok'}) "$compliant/$total compliant"
} catch { Add-Row 'Endpoints' 'Intune device compliance' 'unknown' 'Requires DeviceManagement read scope (verify)' }

# ============================ DATA ===========================================
Write-Host "Pillar: Data" -ForegroundColor Cyan
try {
    $labels = Invoke-MgGraphRequest -Method GET -Uri 'v1.0/security/informationProtection/sensitivityLabels' -ErrorAction SilentlyContinue
    $labelCount = (@($labels.value)).Count
    Add-Row 'Data' 'Sensitivity labels' (if ($labelCount -gt 0){'present'}else{'GAP'}) "$labelCount labels defined (verify endpoint availability)"
} catch { Add-Row 'Data' 'Sensitivity labels' 'unknown' 'Verify Purview/Graph endpoint + scope' }
Add-Row 'Data' 'DLP policy coverage' 'REVIEW' 'Confirm DLP policies across Exchange/Endpoint/Cloud Apps in Purview (manual verify — data-classification is customer-owned)'

# ============================ APPLICATIONS ===================================
Write-Host "Pillar: Applications" -ForegroundColor Cyan
try {
    $apps = Get-MgApplication -All -ErrorAction SilentlyContinue
    $withSecrets = @($apps | Where-Object { $_.PasswordCredentials.Count -gt 0 })
    $expiringSoon = 0
    foreach ($a in $withSecrets) {
        foreach ($pc in $a.PasswordCredentials) { if ($pc.EndDateTime -and $pc.EndDateTime -lt (Get-Date).AddDays(30)) { $expiringSoon++ } }
    }
    Add-Row 'Applications' 'App registrations / secrets' (if ($expiringSoon -gt 0){'REVIEW'}else{'ok'}) "$((@($apps)).Count) apps, $($withSecrets.Count) with secrets, $expiringSoon expiring <30d"
} catch { Add-Row 'Applications' 'App registrations / secrets' 'unknown' $_.Exception.Message }
Add-Row 'Applications' 'Shadow-IT visibility' 'REVIEW' 'Confirm Defender for Cloud Apps discovery enabled (coverage gap if not)'

# ============================ INFRASTRUCTURE =================================
Write-Host "Pillar: Infrastructure" -ForegroundColor Cyan
try {
    if (-not $SubscriptionIds) { $SubscriptionIds = (Get-AzSubscription -ErrorAction SilentlyContinue).Id }
    foreach ($sid in $SubscriptionIds) {
        try { Set-AzContext -SubscriptionId $sid -ErrorAction Stop | Out-Null } catch { continue }
        $plans = Get-AzSecurityPricing -ErrorAction SilentlyContinue
        $standard = @($plans | Where-Object { $_.PricingTier -eq 'Standard' })
        Add-Row 'Infrastructure' "Defender for Cloud plans ($sid)" (if ($standard.Count -gt 0){'partial/on'}else{'GAP'}) "$($standard.Count)/$((@($plans)).Count) plans on Standard"
        $policies = Get-AzPolicyAssignment -ErrorAction SilentlyContinue
        Add-Row 'Infrastructure' "Azure Policy assignments ($sid)" (if ((@($policies)).Count -gt 0){'present'}else{'GAP'}) "$((@($policies)).Count) assignments (CAF governance guardrails)"
    }
} catch { Add-Row 'Infrastructure' 'Defender for Cloud / Policy' 'unknown' 'Requires Azure Reader + Security Reader (R2)' }

# ============================ NETWORK ========================================
Write-Host "Pillar: Network" -ForegroundColor Cyan
try {
    foreach ($sid in $SubscriptionIds) {
        try { Set-AzContext -SubscriptionId $sid -ErrorAction Stop | Out-Null } catch { continue }
        $publicIps = Get-AzPublicIpAddress -ErrorAction SilentlyContinue
        $peps = Get-AzPrivateEndpoint -ErrorAction SilentlyContinue
        Add-Row 'Network' "Public exposure ($sid)" (if ((@($publicIps)).Count -gt 0){'REVIEW'}else{'ok'}) "$((@($publicIps)).Count) public IPs, $((@($peps)).Count) private endpoints"
    }
} catch { Add-Row 'Network' 'Public exposure / private endpoints' 'unknown' 'Requires Azure Reader (R2)' }

# ============================ OUTPUT =========================================
$posture | Format-Table -AutoSize
$csv  = Join-Path $OutputFolder ("CLDSEC-posture-$stamp.csv")
$json = Join-Path $OutputFolder ("CLDSEC-posture-$stamp.json")
$posture | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$posture | ConvertTo-Json -Depth 5 | Out-File -FilePath $json -Encoding UTF8
Write-Host "`nSaved: $csv" -ForegroundColor Green
Write-Host "Saved: $json" -ForegroundColor Green
$gaps = @($posture | Where-Object { $_.State -in @('GAP','REVIEW') })
Write-Host "$($gaps.Count) posture items flagged GAP/REVIEW — feed to CLDSEC-Report.ps1. Read-only; nothing changed." -ForegroundColor Yellow
