# Solution Overview — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

## What this solution does

This is the **Government (GCC High)** edition of the *Microsoft 365 Security Baseline & Audit
Readiness* solution. It walks a novice administrator, click by click, through raising and holding a
measurable Microsoft 365 security posture on a **US sovereign cloud (GCC High)** tenant — using
**Microsoft Secure Score** to drive a hardened baseline, and **Microsoft Purview Compliance Manager**
to organize the evidence that auditors ask for (CMMC, NIST SP 800-171, FedRAMP, DFARS).

The important thing to understand up front: **GCC High is not "the Commercial portal with a different
sign-in."** It is a physically and logically isolated national cloud, operated by screened US
personnel, with its **own admin portal URLs, its own Microsoft Graph endpoints, and a feature set that
lags or omits some Commercial capabilities.** Commercial click-paths and scripts will *silently fail*
or point at the wrong tenant if used here. This edition uses the **`*.us` sovereign portals** and the
**US Gov Graph endpoints (`-Environment USGov`)** throughout, and calls out every parity gap at the
step where it matters.

> **White-label note.** This document is vendor-neutral. Object names it tells you to create (groups,
> policies, tags) are yours to keep and reuse across the solution.

## The two engines

1. **Microsoft Secure Score** (in the **Microsoft Defender portal**, `https://security.microsoft.us`)
   — a running measurement of your identity, device, app, and data security configuration, expressed
   as points earned vs. points achievable, with prioritized improvement actions. In GCC High, Secure
   Score is **available**, but **some recommendations that exist in Commercial are not surfaced** — so
   your achievable total and your action list will differ from a Commercial tenant. (Verify for GCC
   High; cited in `gcc-high-parity-notes.md`.)

2. **Microsoft Purview Compliance Manager** (in the **Microsoft Purview portal**,
   `https://compliance.microsoft.us`) — a control-mapping and evidence workspace that scores your
   compliance posture against **assessment templates**. In GCC High, Compliance Manager is
   **available**, the **Microsoft Data Protection Baseline** is included, and **CMMC Levels 1–5** are
   included with **G5 (Gov)** licensing — but a few Compliance Manager features are still *in
   development* or *rolling out* for GCC High (see parity notes).

## Commercial vs GCC High — what's different

This is the single most important section for a Government deployment. Read it before touching
anything.

| Thing | Commercial | GCC High (this edition) |
| --- | --- | --- |
| Entra admin center | `https://entra.microsoft.com` | `https://entra.microsoft.us` |
| Microsoft 365 admin center | `https://admin.microsoft.com` | `https://portal.office365.us` |
| Defender portal (Secure Score) | `https://security.microsoft.com` | `https://security.microsoft.us` |
| Purview / Compliance portal (Compliance Manager) | `https://compliance.microsoft.com` | `https://compliance.microsoft.us` |
| Intune / endpoint | `https://intune.microsoft.com` / `https://endpoint.microsoft.com` | `https://intune.microsoft.us` / `https://endpoint.microsoft.us` |
| Azure portal | `https://portal.azure.com` | `https://portal.azure.us` |
| Sign-in / token authority | `https://login.microsoftonline.com` | `https://login.microsoftonline.us` |
| Microsoft Graph service root | `https://graph.microsoft.com` | `https://graph.microsoft.us` (GCC High / L4) |
| Graph PowerShell connect | `Connect-MgGraph` (default) | `Connect-MgGraph -Environment USGov` |
| Defender for Endpoint API | `https://api.securitycenter.microsoft.com` | `https://api-gov.securitycenter.microsoft.us` |
| Secure Score recommendations | Full set | **Available, but some recommendations are not present** |
| Microsoft Threat Experts | Available | **Not available** in GCC/GCC High/DoD |
| Defender for IoT (enterprise IoT) | Available | **Not available** in GCC/GCC High/DoD |
| Compliance Manager templates | Full catalog | Available; **CMMC L1–5 included with G5 Gov**; some CM features *in development / rolling out* |
| Graph Explorer web tool | Supported | **Not supported** for the US Gov endpoints |

> Sources for the URLs, Graph endpoints, and parity statements are cited in
> `gcc-high-parity-notes.md`. Where Microsoft's public documentation does not explicitly confirm a
> GCC High behavior, this solution flags it **"verify for GCC High"** rather than inventing a fact.

**Why this matters in practice:** if you (or a downloaded Commercial script) connect to
`graph.microsoft.com` with GCC High credentials, authentication is attempted against the *Commercial*
authority and fails — often with a confusing redirect or "wrong tenant" error. If you open
`security.microsoft.com`, you either land in a Commercial tenant you don't own or get an access error.
Every step and every script in this edition is pinned to the sovereign endpoints so this class of
"silent failure" cannot happen.

## The deployment model

Every task in this solution follows the standard, gated model:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — read-only discovery of the current GCC High tenant (baseline Secure Score, licensing,
  roles, existing policies) using `M365SECG-Discovery.ps1`.
- **Configure** — create the named objects (pilot group, baseline policies) and stage improvement
  actions, using the correct `*.us` portals.
- **Pilot** — apply changes to a **named pilot group** first, never the whole tenant.
- **Validate** — confirm with `M365SECG-Validation.ps1` and the Secure Score / Compliance Manager UI
  that the change took effect and nothing broke.
- **Expand** — widen scope in controlled waves, re-validating at each **gate** before proceeding.

No change goes tenant-wide without passing a pilot and a validation gate. This is doubly important in
GCC High, where an authentication-impacting misconfiguration can lock out cleared users who have no
Commercial fallback.

## What you will produce

- A **named pilot security group** (default: `SEC-Baseline-Pilot`) used across the solution.
- A raised, **documented Secure Score baseline** on the GCC High tenant, with a prioritized backlog of
  the improvement actions that are actually available in GCC High.
- A **Compliance Manager assessment** (default: Microsoft Data Protection Baseline, plus CMMC if G5
  Gov) with evidence organized for audit.
- **Repeatable evidence**: discovery, validation, and report outputs from the five PowerShell scripts,
  all pinned to US Gov Graph — so the posture can be re-measured on demand and handed to an auditor.

## What's inside this solution

- **Solution Overview** (this document) — with the Commercial-vs-GCC-High map above.
- **Requirements Guide** (`02-requirements.md`) — every prerequisite, each with *verify* and
  *implement-if-missing* steps, pinned to sovereign portals and Gov licensing.
- **Implementation Guide** (`03-implementation.md`) — exact ordered steps in the `*.us` portals, with
  GCC-High-only caveats inline at the step where they bite.
- **Testing & Validation** (`05-testing.md`) — pass/fail gates for each phase.
- **Best Practices** (`07-best-practices.md`) — how to keep the posture from decaying.
- **Deliverables Summary** (`08-deliverables-summary.md`) — everything in the box.
- **GCC High Parity Notes** (`gcc-high-parity-notes.md`) — the cited reference for every "different in
  GCC High" claim.
- **Troubleshooting** (`06-troubleshooting.md`) — GCC-High-specific gotchas and fixes.
- **5 PowerShell scripts** — Discovery, Validation, Report (read-only), Remediation and
  Set-ScopeTargeting (both default to `-WhatIf`), all connecting with `-Environment USGov`.
