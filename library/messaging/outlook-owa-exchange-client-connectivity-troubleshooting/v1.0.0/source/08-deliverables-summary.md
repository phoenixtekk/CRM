# Deliverables Summary

Everything included in the **Outlook / OWA / Exchange Client Connectivity Troubleshooting
Toolkit**, on one page.

## Documentation

| Document | What it gives you |
|----------|-------------------|
| **Solution Overview** | The client-connectivity model (Autodiscover → protocols → auth → client), the layered diagnostic method, benefits, limitations, and the Assess→Expand adoption model. |
| **Requirements Guide** | Solution-specific prerequisites — diagnostic-capable least-privilege role, the `ConnTest` baseline mailbox, correct Autodiscover DNS, modern auth / Conditional Access read access, RCA + SARA access, and hybrid free/busy prerequisites — each with how to *verify* and *implement*. Builds on the shared Messaging requirements. |
| **Diagnostic Playbook** | The core: a symptom→root-cause **decision tree** (D0 scope; D1 Discovery; D2 Protocol; D3 Auth; D4 Client; D5 hybrid free/busy; D6 Mobile) with the exact test and pass/fail branch at each node, and change-control gates + rollback for any remediation. |
| **Testing & Validation** | Six pass/fail **gates** (Autodiscover resolves, protocols connect, auth succeeds, free/busy returns, mobile syncs, isolation is conclusive) plus regression re-test and the pilot exit criterion. |
| **Troubleshooting** | Common failure modes across every layer and their resolutions. |
| **Best Practices** | Durable practices for diagnosing by layer, using `ConnTest`/OWA as instruments, treating auth loops as policy, respecting version/cloud boundaries, and closing the loop to reduce future ticket volume. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk for decision-makers. |

## PowerShell scripts (5)

All scripts use the **ExchangeOnlineManagement (EXO V3)** module and/or **Microsoft Graph**,
connect only via **modern authentication** (no stored credentials), and are **read-only or
`-WhatIf`/dry-run by default**.

| # | Script | What it does |
|---|--------|--------------|
| 1 | **`Get-ClientConnectivityAssessment.ps1`** | *Discovery (read-only).* Per-user client-access + protocol picture: `Get-CASMailbox` enablement (MAPI/EWS/OWA/ActiveSync), plan defaults, and server-side `Test-OutlookConnectivity` / `Test-OutlookWebServices` results, compared against the `ConnTest` baseline. Outputs an object/table per user. |
| 2 | **`Set-MailboxProtocolAccess.ps1`** | *Remediation (safe-by-default).* Re-enables a disabled client protocol (`Set-CASMailbox`). Defaults to a **dry-run report** that records the current value; changes only with explicit `-Commit`; supports `-WhatIf`. Prints the recorded prior value for rollback. |
| 3 | **`Test-AutodiscoverEndpoints.ps1`** | *Validation.* Tests the Discovery layer per user: Autodiscover DNS (CNAME/SRV), the Autodiscover v2 JSON endpoint, and (hybrid) the SCP `AutoDiscoverServiceInternalUri`. Read-only; reports the resolved endpoint vs the expected host. |
| 4 | **`Test-ModernAuthConditionalAccess.ps1`** | *Validation.* Summarizes the Auth layer: org modern-auth (`Get-OrganizationConfig` OAuth), per-user auth policy (`Get-CASMailbox`), and — via Microsoft Graph — the Conditional Access policies and recent sign-in results for the user's mail client app. Read-only. |
| 5 | **`Get-ClientConnectivityScope.ps1`** | *Scope / health helper.* Answers D0 "how big is the blast radius": runs the assessment across a set of users, buckets pass/fail, and flags whether a fault is per-mailbox, per-site, or tenant-wide. Read-only reporting. |

**Safety note.** Diagnostics never change state. The one remediation script defaults to a
dry-run and requires `-Commit` under change control, keeping the recorded prior value as the
rollback (per the gates in Testing & Validation).
