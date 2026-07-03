# Solution Overview — IP/Port/URL Allow-List & Egress Filtering Management for Microsoft 365 & Intune Endpoints (Government / GCC High)

## What this solution does

Microsoft 365, Intune, and Microsoft Defender for Endpoint are **cloud services reached over the
public network**. When your egress path is filtered — a firewall, a secure web gateway (SWG), a
proxy, or a SASE/SSE stack — the client only works if the **exact IP ranges, URLs, and ports** that
those services use are allowed through. Miss one, over-inspect one, or hardcode an address that later
changes, and users see broken sign-in, stalled Intune check-ins, failed Teams calls, or Defender
devices that never onboard.

This solution gives a novice administrator a **repeatable, click-to-implement method** to:

1. **Derive** the current required IP/URL/port set **from Microsoft's own web service** — not from a
   hand-typed list that goes stale.
2. **Build** a named, documented allow-list (and SSL-inspection **bypass** list) on your egress
   device from that derived set.
3. **Validate** connectivity from a real endpoint before and after each change, with pass/fail gates.
4. **Keep it current** automatically, because Microsoft publishes additions **30 days in advance**
   and changes the data monthly.

**The critical difference in this edition:** everything is derived from the **US Government GCC High
instance** of the endpoints service and points at the **US sovereign (`*.us` / `*.microsoft.us`)
admin portals and service endpoints** — not the Commercial (Worldwide) ones. GCC High is a
**physically and logically separate cloud** with its **own published endpoint set**. Using Commercial
endpoints on a GCC High tenant is a silent-failure trap: sign-in redirects, portal URLs, and service
FQDNs are all different.

## The one fact that governs this whole solution

Microsoft publishes four **instances** of the IP/URL web service, and **you must query the one that
matches your tenant**:

| Instance name | Cloud | Use it if… |
| --- | --- | --- |
| `Worldwide` | Commercial (incl. GCC) | Standard commercial or GCC (moderate) tenant |
| `USGovGCCHigh` | **GCC High** | **This edition — US sovereign GCC High tenant** |
| `USGovDoD` | DoD | US Department of Defense tenant |
| `China` | 21Vianet | Operated by 21Vianet in China |

> This solution uses **`USGovGCCHigh`** everywhere. The valid instance names are documented by
> Microsoft on the IP Address and URL web service page. (Cited — see `gcc-high-parity-notes.md`.)

Because the addresses **change month to month**, this solution **never hardcodes Microsoft IPs**.
Every script derives the live set from the `USGovGCCHigh` instance at run time. The only fixed facts
we rely on are Microsoft's **published GCC High portal/service FQDNs** (e.g. `login.microsoftonline.us`,
`*.manage.microsoft.us`, `security.microsoft.us`), which Microsoft documents explicitly for the Gov
cloud.

## Commercial vs GCC High — what's different

This is the section to read before you touch anything. If you have done this on a Commercial tenant,
**almost every URL you memorized is wrong here.**

| Area | Commercial (Worldwide) | **GCC High (this edition)** |
| --- | --- | --- |
| Endpoints web-service instance | `Worldwide` | **`USGovGCCHigh`** |
| Endpoints download (JSON) | `endpoints.office.com/endpoints/Worldwide?...` | **`endpoints.office.com/endpoints/USGOVGCCHigh?...`** |
| Sign-in / identity | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft 365 portal | `portal.office.com` | **`portal.office365.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Intune admin center | `intune.microsoft.com` / `endpoint.microsoft.com` | **`intune.microsoft.us`** |
| Intune service (client) | `*.manage.microsoft.com` | **`*.manage.microsoft.us`** |
| Intune Company Portal | `portal.manage.microsoft.com` | **`portal.manage.microsoft.us`** |
| Defender portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Compliance / Purview | `compliance.microsoft.com` | **`compliance.microsoft.us` / `purview.microsoft.us`** |
| Exchange Online | `outlook.office.com` | **`outlook.office365.us`** |
| SharePoint / OneDrive | `*.sharepoint.com` | **`*.sharepoint.us`** |
| Teams | `*.teams.microsoft.com` | **`*.gov.teams.microsoft.us`** |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** |
| Defender/EPM device channel | `*.dm.microsoft.com` | **`*.dm.microsoft.us`** |
| Graph PowerShell environment | (default) | **`Connect-MgGraph -Environment USGov`** |

> **Parity gaps are real.** Some Commercial capabilities lag, are limited, or are absent in GCC High.
> Where a step depends on a capability whose GCC High behavior we could not confirm against Microsoft
> Gov documentation, it is flagged **"verify for GCC High"** at the step. Never assume a Commercial
> feature exists in GCC High just because the portal looks similar.

## Objects this solution creates (name them, reuse them)

Consistent names make the allow-list auditable and let every later step reference the same objects.

| Object | Suggested name | What it is |
| --- | --- | --- |
| Derived endpoint export | `EGRESSG-Endpoints-USGovGCCHigh.json` | The raw GCC High set pulled from the web service |
| Allow-list address group | `EGRESSG-M365-GCCHigh-Allow` | Firewall/SWG object holding the required IP ranges |
| URL allow / bypass category | `EGRESSG-M365-GCCHigh-URLs` | Proxy/SWG URL category for the required FQDNs |
| SSL-inspection bypass list | `EGRESSG-NoInspect-GCCHigh` | FQDNs Microsoft says must **not** be SSL-inspected |
| Pilot device group (Entra) | `EGRESSG-Pilot` | Staged rollout group (see Global Requirement G6) |
| Change/version checkpoint file | `EGRESSG-latestversion.txt` | Stores the last-applied web-service version |

## The deployment model

This solution follows the standard model used across the library, with a **gate** between each phase —
you do not advance until the gate passes.

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess** — Confirm you are on a GCC High tenant, gather the Gov portal URLs, and run read-only
   discovery to derive today's required `USGovGCCHigh` set. *Gate: discovery returns a non-empty set
   from the `USGovGCCHigh` instance.*
2. **Configure** — Build the named allow-list, URL category, and SSL bypass list from the derived set.
   *Gate: every required endpoint set is represented; nothing hardcoded.*
3. **Pilot** — Apply to the `EGRESSG-Pilot` group only. *Gate: pilot devices pass validation.*
4. **Validate** — Run the validation script from a pilot endpoint; confirm sign-in, Intune check-in,
   Defender onboarding, and Teams media. *Gate: all checks green.*
5. **Expand** — Roll out fleet-wide, then schedule the monthly keep-current job. *Gate: scheduled job
   runs and reports "up to date" or a reviewed change set.*

## What's inside

- **Requirements Guide** (`02-requirements.md`) — every prerequisite with **Verify** and
  **Implement-if-missing** steps, GCC High–specific.
- **Implementation Guide** (`03-implementation.md`) — derive the Gov required set, build the
  allow-list, validate, and keep current, step by step.
- **Testing** (`05-testing.md`) — pass/fail gates for each phase.
- **Troubleshooting** (`06-troubleshooting.md`) — GCC High–specific gotchas.
- **Best Practices** (`07-best-practices.md`), **Deliverables Summary** (`08-deliverables-summary.md`),
  **Executive Summary**, and a cited **GCC High Parity Notes** reference.
- **5 PowerShell scripts** — Discovery, Validation, Report, Remediation (`-WhatIf` by default), and
  Set-ScopeTargeting — all querying the **`USGovGCCHigh`** instance and using `-Environment USGov`
  for Graph.

## Bottom line

IP/Port/URL allow-list and egress filtering deployed **correctly on GCC High** — right web-service
instance, right sovereign portals and service FQDNs, SSL-inspection bypasses in place, parity gaps
called out, and a monthly keep-current job — **proven on a pilot before you scale.**
