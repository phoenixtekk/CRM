<#
.SYNOPSIS
    AIWLSEC-NetworkIsolation.ps1 — read-only network-isolation review of Azure AI workloads.
.DESCRIPTION
    PURPOSE
        For every Azure OpenAI / Cognitive Services, AI Search, and Azure ML resource in scope, reports the
        network-isolation posture that most often exposes AI workloads: public network access (Enabled =
        finding), private-endpoint presence, and whether a private-DNS resolution path likely exists. This is
        where the highest-frequency AI findings live (public-by-default is the norm). Read-only; changes nothing.
    HOW TO RUN
        Connect-AzAccount
        pwsh -File .\AIWLSEC-NetworkIsolation.ps1 -SubscriptionIds "<sub>" -OutputFolder "<secure path>"
        Requires Az.Accounts / Az.CognitiveServices / Az.Resources / Az.Network / Az.PrivateDns. *Verify versions.*
    EXPECTED RESULTS
        A per-resource isolation table (public access / private endpoints / DNS) with a PASS/FINDING verdict,
        and a CSV in the output folder. Read-only.
.NOTES
    White-label. Read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [string[]]$SubscriptionIds,
    [Parameter(Mandatory=$true)][string]$OutputFolder
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rows = New-Object System.Collections.Generic.List[object]
Write-Host "AIWLSEC network-isolation review (read-only)`n" -ForegroundColor Cyan

if (-not $SubscriptionIds) { $SubscriptionIds = (Get-AzSubscription -ErrorAction SilentlyContinue).Id }

# Pre-load private DNS zones once per subscription for a resolution hint
function Test-Verdict([string]$public,[int]$pe){
    if ($public -match 'Enabled|enabled') { return 'FINDING: public access enabled' }
    if ($pe -eq 0) { return 'REVIEW: no private endpoint' }
    return 'PASS'
}

foreach ($sid in $SubscriptionIds) {
    try { Set-AzContext -SubscriptionId $sid -ErrorAction Stop | Out-Null } catch { Write-Host "  (skip $sid — Reader missing? R1)" -ForegroundColor Yellow; continue }
    $dnsZones = @(); try { $dnsZones = Get-AzPrivateDnsZone -ErrorAction SilentlyContinue } catch {}
    $dnsHint = if (@($dnsZones | Where-Object { $_.Name -match 'openai|cognitiveservices|search' }).Count -gt 0) { 'AI private DNS zone present' } else { 'no AI private DNS zone found' }

    # Cognitive Services / OpenAI
    foreach ($a in (Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue)) {
        $public = $a.Properties.PublicNetworkAccess
        $pe = (@($a.Properties.PrivateEndpointConnections)).Count
        $rows.Add([pscustomobject]@{ Subscription=$sid; Type=$a.Kind; Name=$a.AccountName; ResourceGroup=$a.ResourceGroupName
            PublicAccess=$public; PrivateEndpoints=$pe; PrivateDns=$dnsHint; Verdict=(Test-Verdict $public $pe) })
    }
    # AI Search
    foreach ($s in (Get-AzResource -ResourceType 'Microsoft.Search/searchServices' -ErrorAction SilentlyContinue)) {
        $full = $null; try { $full = Get-AzResource -ResourceId $s.ResourceId -ExpandProperties -ErrorAction SilentlyContinue } catch {}
        $public = $full.Properties.publicNetworkAccess
        $pe = (@($full.Properties.privateEndpointConnections)).Count
        $rows.Add([pscustomobject]@{ Subscription=$sid; Type='AI Search'; Name=$s.Name; ResourceGroup=$s.ResourceGroupName
            PublicAccess=(if($public){$public}else{'unknown'}); PrivateEndpoints=$pe; PrivateDns=$dnsHint; Verdict=(Test-Verdict "$public" $pe) })
    }
    # Azure ML
    foreach ($w in (Get-AzResource -ResourceType 'Microsoft.MachineLearningServices/workspaces' -ErrorAction SilentlyContinue)) {
        $full = $null; try { $full = Get-AzResource -ResourceId $w.ResourceId -ExpandProperties -ErrorAction SilentlyContinue } catch {}
        $public = $full.Properties.publicNetworkAccess
        $pe = (@($full.Properties.privateEndpointConnections)).Count
        $rows.Add([pscustomobject]@{ Subscription=$sid; Type='Azure ML'; Name=$w.Name; ResourceGroup=$w.ResourceGroupName
            PublicAccess=(if($public){$public}else{'unknown'}); PrivateEndpoints=$pe; PrivateDns=$dnsHint; Verdict=(Test-Verdict "$public" $pe) })
    }
}

if ($rows.Count -eq 0) { Write-Host "No AI resources found in scope (R1)." -ForegroundColor Yellow; return }
$rows | Format-Table -AutoSize
$csv = Join-Path $OutputFolder "AIWLSEC-network-$stamp.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host "`nSaved: $csv" -ForegroundColor Green
$findings = @($rows | Where-Object { $_.Verdict -like 'FINDING*' })
Write-Host "$($findings.Count) network-isolation FINDING(s) (public access enabled). Feed to AIWLSEC-Report.ps1. Read-only; nothing changed." -ForegroundColor Yellow
