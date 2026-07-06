<#
.SYNOPSIS
    GEMCONN-Remediation.ps1 — safe remediation: disable an unapproved connector (data store) or
    unpublish an over-shared agent, defaulting to preview mode.
.DESCRIPTION
    PURPOSE
        Safe, targeted fixes for the "Gemini Connector Strategy & Agent Development Framework" solution.
        Two actions:
          'DisableConnector' — delete / disable a named Discovery Engine data store that failed the
                          approval criteria, so it no longer exposes its source to Gemini Enterprise;
          'UnpublishAgent' — narrow or remove a named agent/engine that is shared beyond its approved
                          audience.
        DEFAULTS TO -WhatIf — it prints the change it would make and changes nothing until you pass
        -Execute. Both actions are destructive to the named resource only; run GEMCONN-Report.ps1 first
        to capture the pre-change state and confirm the id.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\GEMCONN-Remediation.ps1 -Action DisableConnector -ProjectId 'your-project-id' -ResourceId 'your-datastore-id'
            powershell -ExecutionPolicy Bypass -File .\GEMCONN-Remediation.ps1 -Action UnpublishAgent -ProjectId 'your-project-id' -ResourceId 'your-engine-id'
        Apply for real (explicit):
            ... -Execute
        Requires the Google Cloud SDK (gcloud) authenticated with a principal that can edit Discovery
        Engine resources (an editor/admin-level role). Run 'gcloud auth login' and
        'gcloud config set project your-project-id' first. Agent audience controls are a preview
        surface — UnpublishAgent is best-effort and may require a console step.
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the connector disable or agent unpublish —
        nothing changes. With -Execute: the delete/unpublish call is issued and the result reported.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf. Read-only until you pass -Execute.
    Acts only on the single resource id you name. Gemini Enterprise agent audience controls are preview;
    where no stable API exists, the script tells you the console step to take instead of guessing.
    Never invents API or resource specifics.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [ValidateSet('DisableConnector','UnpublishAgent')] [string]$Action,
    [Parameter(Mandatory)] [string]$ProjectId,
    [Parameter(Mandatory)] [string]$ResourceId,
    [string]$Location = 'global',
    [ValidateSet('v1','v1alpha','v1beta')] [string]$ApiVersion = 'v1',
    [switch]$Execute                                  # omit for -WhatIf (default safe mode)
)

function Get-GcloudToken {
    try { $t = (& gcloud auth print-access-token 2>$null); if (-not $t) { throw "empty" }; return $t.Trim() }
    catch { Write-Host "Could not obtain a gcloud access token. Run 'gcloud auth login' first." -ForegroundColor Red; throw }
}

$whatIf  = -not $Execute
$token   = Get-GcloudToken
$headers = @{ Authorization = "Bearer $token"; 'X-Goog-User-Project' = $ProjectId }
$base    = "https://discoveryengine.googleapis.com/$ApiVersion/projects/$ProjectId/locations/$Location/collections/default_collection"

Write-Host "`n=== Gemini Connector Strategy & Agent Development — remediation ===" -ForegroundColor Cyan

switch ($Action) {

    'DisableConnector' {
        $uri = "$base/dataStores/$ResourceId"
        if ($whatIf) {
            Write-Host ("[WhatIf] Would DELETE / disable connector (data store) '{0}' in project {1}." -f $ResourceId, $ProjectId) -ForegroundColor Yellow
            Write-Host "         No change made. Re-run with -Execute to apply." -ForegroundColor Yellow
        } else {
            try {
                Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers -ErrorAction Stop | Out-Null
                Write-Host ("Disabled connector '{0}'. It no longer exposes its source to Gemini Enterprise." -f $ResourceId) -ForegroundColor Green
            } catch {
                Write-Host ("Disable failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
                Write-Host "Confirm the data-store id and that your API version matches your tenant (-ApiVersion)." -ForegroundColor Yellow
            }
        }
    }

    'UnpublishAgent' {
        if ($whatIf) {
            Write-Host ("[WhatIf] Would unpublish / narrow the audience of agent (engine) '{0}' in project {1}." -f $ResourceId, $ProjectId) -ForegroundColor Yellow
            Write-Host "         No change made. Re-run with -Execute to apply." -ForegroundColor Yellow
        } else {
            $uri = "$base/engines/$ResourceId"
            try {
                Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers -ErrorAction Stop | Out-Null
                Write-Host ("Removed agent/engine '{0}' from the shared surface." -f $ResourceId) -ForegroundColor Green
            } catch {
                Write-Host ("Automated unpublish not available (preview surface): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
                Write-Host "VERIFY IN YOUR TENANT: in the Google Cloud / Agentspace admin, open the agent and set its" -ForegroundColor Yellow
                Write-Host "audience back to the approved group, or unpublish it, manually." -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ("`nRemediation complete ({0})." -f $(if ($whatIf){'WhatIf — no changes'}else{'executed'})) -ForegroundColor ($(if ($whatIf){'Yellow'}else{'Green'}))
