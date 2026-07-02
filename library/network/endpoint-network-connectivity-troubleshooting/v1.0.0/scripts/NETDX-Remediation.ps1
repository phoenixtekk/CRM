<#
.SYNOPSIS
    NETDX-Remediation.ps1 — safe, local, reversible resets (DNS cache / route cache / stale proxy).
.DESCRIPTION
    PURPOSE
        Applies only safe, local, reversible resets on the affected endpoint when the block is proven
        to be local: flush the DNS client cache, reset the IP route cache, and clear a stale WinHTTP
        proxy. It never touches proxy servers, VPN concentrators, or firewalls — those are escalated
        with evidence. Defaults to preview mode (-WhatIf on) so nothing changes until you confirm.
        Run only after the Diagnostic Playbook proves the cause is local to this endpoint.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NETDX-Remediation.ps1
        (preview only — shows what would change)
        powershell -ExecutionPolicy Bypass -File .\NETDX-Remediation.ps1 -WhatIf:$false
        (apply; run from an elevated prompt; add -Confirm if your policy requires a prompt)
        Optional switches: -FlushDns -ResetRouteCache -ClearWinHttpProxy (default: all enabled)
    EXPECTED RESULTS
        In preview, admin sees each action prefixed "What if:" and nothing changes. With -WhatIf:$false
        the selected resets run and a per-action PASS/FAIL is shown.
        Pass = the selected local resets completed. If the issue persists, the cause is not local —
        escalate the captured evidence to the owning team.
.NOTES
    White-label — the repeatable way. Remediation defaults to -WhatIf (preview).
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$FlushDns = $true,
    [switch]$ResetRouteCache = $true,
    [switch]$ClearWinHttpProxy = $true
)

$ErrorActionPreference = 'Continue'

# Default posture: -WhatIf ON unless the caller explicitly disabled it (-WhatIf:$false).
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
    Write-Host "[preview] Running in -WhatIf mode; no changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}

function Invoke-Step {
    param(
        [string]$Target,
        [string]$Action,
        [scriptblock]$Do
    )
    if ($PSCmdlet.ShouldProcess($Target, $Action)) {
        try {
            & $Do
            Write-Host ("  PASS  {0} — {1}" -f $Action, $Target) -ForegroundColor Green
        }
        catch {
            Write-Host ("  FAIL  {0} — {1}: {2}" -f $Action, $Target, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host '=== NETDX safe local remediation ===' -ForegroundColor Cyan

# --- 1. Flush DNS client cache ---
if ($FlushDns) {
    Invoke-Step -Target 'DNS client cache' -Action 'Flush DNS cache' -Do {
        if (Get-Command Clear-DnsClientCache -ErrorAction SilentlyContinue) {
            Clear-DnsClientCache -ErrorAction Stop
        }
        else {
            $null = & ipconfig /flushdns
        }
    }
}

# --- 2. Reset IP route cache (safe: rebuilt automatically) ---
if ($ResetRouteCache) {
    Invoke-Step -Target 'IP route cache' -Action 'Reset route cache' -Do {
        # Deletes cached/persistent-cache neighbor+route state; the stack rebuilds it. Non-destructive.
        $null = & netsh interface ip delete destinationcache
    }
}

# --- 3. Clear a stale WinHTTP proxy ---
if ($ClearWinHttpProxy) {
    Invoke-Step -Target 'WinHTTP proxy' -Action 'Reset WinHTTP proxy to direct' -Do {
        $null = & netsh winhttp reset proxy
    }
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Preview complete. Review the actions above, then re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow
}
else {
    Write-Host 'Remediation complete. Re-test the affected target; if it still fails, the cause is not local — escalate with evidence.' -ForegroundColor Green
}
