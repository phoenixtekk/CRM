<#
.SYNOPSIS
    AIWLSEC-Discovery.ps1 — read-only inventory of Azure AI workloads and their security posture.
.DESCRIPTION
    PURPOSE
        Builds the point-in-time AI estate baseline. For every Azure OpenAI / Cognitive Services account,
        Azure AI Search service, and Azure ML workspace in scope it records the risk posture: public network
        access, local-auth (account keys) enabled, custom subdomain, model deployments and whether a
        content-filter policy is attached, private endpoints, diagnostics, and (for Search) API-key vs RBAC
        auth and index/data-source hints of a RAG pattern. Every call is read-only; nothing is changed.
    HOW TO RUN
        Connect-AzAccount ; Connect-MgGraph -Scopes "Directory.Read.All"
        pwsh -File .\AIWLSEC-Discovery.ps1 -SubscriptionIds "<sub>" -OutputFolder "<secure path>"
        Run AIWLSEC-Validate.ps1 first. *Verify current Az cmdlet/property names and the AI Foundry resource model.*
    EXPECTED RESULTS
        A per-resource posture table on screen and CSV/JSON in the output folder. Read-only.
.NOTES
    White-label. Read-only. Makes no changes. Best-effort across evolving API surfaces — verify property names.
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
function Add-Res($o){ $rows.Add($o) }
Write-Host "AIWLSEC discovery — Azure AI workloads (read-only)`n" -ForegroundColor Cyan

if (-not $SubscriptionIds) { $SubscriptionIds = (Get-AzSubscription -ErrorAction SilentlyContinue).Id }

foreach ($sid in $SubscriptionIds) {
    try { Set-AzContext -SubscriptionId $sid -ErrorAction Stop | Out-Null } catch { Write-Host "  (skip $sid — cannot set context; Reader missing? R1)" -ForegroundColor Yellow; continue }
    Write-Host "Subscription $sid" -ForegroundColor Cyan

    # --- Azure OpenAI / Cognitive Services -----------------------------------
    $cs = Get-AzCognitiveServicesAccount -ErrorAction SilentlyContinue
    foreach ($a in $cs) {
        $p = $a.Properties
        $publicAccess = $p.PublicNetworkAccess
        $keysUsable   = if ($null -ne $p.DisableLocalAuth) { -not $p.DisableLocalAuth } else { $true }
        $subdomain    = $p.CustomSubDomainName
        $peCount      = (@($p.PrivateEndpointConnections)).Count
        $deployments = @()
        try { $deployments = Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $a.ResourceGroupName -AccountName $a.AccountName -ErrorAction SilentlyContinue } catch {}
        # content filter policy attached? (RaiPolicyName property — *verify*)
        $noFilter = @($deployments | Where-Object { -not $_.Properties.RaiPolicyName })
        $diag = @(); try { $diag = Get-AzDiagnosticSetting -ResourceId $a.Id -ErrorAction SilentlyContinue } catch {}

        $risk = @()
        if ($publicAccess -eq 'Enabled') { $risk += 'PUBLIC' }
        if ($keysUsable)                 { $risk += 'KEYS-ON' }
        if (-not $subdomain)             { $risk += 'NO-SUBDOMAIN' }
        if ($noFilter.Count -gt 0)       { $risk += 'DEPLOY-NO-FILTER' }
        if (-not $diag)                  { $risk += 'NO-DIAG' }

        Add-Res ([pscustomobject]@{
            Subscription=$sid; Type=$a.Kind; Name=$a.AccountName; ResourceGroup=$a.ResourceGroupName; Location=$a.Location
            PublicAccess=$publicAccess; KeysUsable=$keysUsable; CustomSubdomain=(if($subdomain){$subdomain}else{'(none)'})
            PrivateEndpoints=$peCount; Deployments=(@($deployments)).Count; DeploymentsNoFilter=$noFilter.Count
            Diagnostics=(if($diag){'yes'}else{'NO'}); Risk=(if($risk){($risk -join ',')}else{'ok'})
        })
    }

    # --- Azure AI Search -----------------------------------------------------
    $searchRes = Get-AzResource -ResourceType 'Microsoft.Search/searchServices' -ErrorAction SilentlyContinue
    foreach ($s in $searchRes) {
        $full = $null; try { $full = Get-AzResource -ResourceId $s.ResourceId -ExpandProperties -ErrorAction SilentlyContinue } catch {}
        $props = $full.Properties
        $publicAccess = $props.publicNetworkAccess
        $authOptions  = $props.authOptions           # presence => API keys allowed
        $disableLocal = $props.disableLocalAuth       # true => RBAC-only (good)
        $peCount = (@($props.privateEndpointConnections)).Count

        $risk = @()
        if ($publicAccess -eq 'enabled' -or $publicAccess -eq 'Enabled') { $risk += 'PUBLIC' }
        if ($disableLocal -ne $true) { $risk += 'API-KEYS-ALLOWED' }
        if ($peCount -eq 0) { $risk += 'NO-PRIVATE-EP' }

        Add-Res ([pscustomobject]@{
            Subscription=$sid; Type='AI Search'; Name=$s.Name; ResourceGroup=$s.ResourceGroupName; Location=$s.Location
            PublicAccess=(if($publicAccess){$publicAccess}else{'unknown'}); KeysUsable=(if($disableLocal -eq $true){$false}else{$true})
            CustomSubdomain='n/a'; PrivateEndpoints=$peCount; Deployments='(indexes — verify permission-trimming manually)'; DeploymentsNoFilter=0
            Diagnostics='verify'; Risk=(if($risk){($risk -join ',')}else{'ok'})
        })
    }

    # --- Azure ML workspaces -------------------------------------------------
    $mlRes = Get-AzResource -ResourceType 'Microsoft.MachineLearningServices/workspaces' -ErrorAction SilentlyContinue
    foreach ($w in $mlRes) {
        $full = $null; try { $full = Get-AzResource -ResourceId $w.ResourceId -ExpandProperties -ErrorAction SilentlyContinue } catch {}
        $props = $full.Properties
        $publicAccess = $props.publicNetworkAccess
        $peCount = (@($props.privateEndpointConnections)).Count
        $risk = @()
        if ($publicAccess -eq 'Enabled') { $risk += 'PUBLIC' }
        if ($peCount -eq 0) { $risk += 'NO-PRIVATE-EP' }
        Add-Res ([pscustomobject]@{
            Subscription=$sid; Type='Azure ML'; Name=$w.Name; ResourceGroup=$w.ResourceGroupName; Location=$w.Location
            PublicAccess=(if($publicAccess){$publicAccess}else{'unknown'}); KeysUsable='n/a'; CustomSubdomain='n/a'
            PrivateEndpoints=$peCount; Deployments='(models/endpoints — verify)'; DeploymentsNoFilter=0
            Diagnostics='verify'; Risk=(if($risk){($risk -join ',')}else{'ok'})
        })
    }
}

if ($rows.Count -eq 0) { Write-Host "No Azure AI resources found in scope. Confirm Reader role/scope (R1) and -SubscriptionIds." -ForegroundColor Yellow; return }

$rows | Format-Table -AutoSize
$csv  = Join-Path $OutputFolder "AIWLSEC-posture-$stamp.csv"
$json = Join-Path $OutputFolder "AIWLSEC-posture-$stamp.json"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8
Write-Host "`nSaved: $csv" -ForegroundColor Green
Write-Host "Saved: $json" -ForegroundColor Green
$risky = @($rows | Where-Object { $_.Risk -ne 'ok' })
Write-Host "$($risky.Count) AI resource(s) have a risk posture (see Risk). Run the network/content-safety reviews, then AIWLSEC-Report.ps1. Read-only; nothing changed." -ForegroundColor Yellow
Write-Host "NOTE: RAG index permission-trimming must be confirmed by inspection (Implementation Step 2.4)." -ForegroundColor Yellow
