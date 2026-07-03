# Requirements Guide — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

Confirm every requirement below **before** you begin implementation. These are **in addition to** the
category-level requirements in `global-requirements-security.md` — read that file too, but note that
its portal URLs are Commercial and must be **substituted with the `*.us` sovereign equivalents** shown
here for a GCC High tenant.

Each entry follows: **Description · Why · Verify · Implement-if-missing.**

> **Sovereign-portal substitution (applies to every requirement below).** Wherever a Commercial doc
> says `entra.microsoft.com`, use `entra.microsoft.us`; `admin.microsoft.com` → `portal.office365.us`;
> `security.microsoft.com` → `security.microsoft.us`; `compliance.microsoft.com` →
> `compliance.microsoft.us`; `intune.microsoft.com`/`endpoint.microsoft.com` →
> `intune.microsoft.us`/`endpoint.microsoft.us`; `portal.azure.com` → `portal.azure.us`;
> `login.microsoftonline.com` → `login.microsoftonline.us`. (Cited in `gcc-high-parity-notes.md`.)

## R1. A GCC High (US sovereign) tenant — not Commercial, not GCC Moderate
**Description:** An active **Microsoft 365 Government – GCC High** tenant.
**Why:** This entire edition targets the L4 sovereign cloud. GCC High has its own endpoints and feature
set; Commercial or GCC-Moderate steps will point at the wrong cloud. (Note: **GCC Moderate uses the
*worldwide* Commercial endpoints** — `portal.azure.com`, `graph.microsoft.com` — so if you are on GCC
Moderate, this GCC High edition's `*.us` endpoints do **not** apply to you.)
**Verify:** Sign in at `https://portal.office365.us`. In the Microsoft 365 admin center, your tenant
type/region should reflect US Government GCC High. Signing in at `https://entra.microsoft.us` succeeds
(the Commercial `entra.microsoft.com` will not host your GCC High tenant).
**Implement:** GCC High requires eligibility validation and enrollment through Microsoft's Government
program; you cannot self-provision it like a Commercial trial. If you do not yet have a GCC High
tenant, complete Microsoft's Government eligibility and onboarding first. (See parity notes.)

## R2. US Government (Gov) licensing — G3/G5 Gov, not Commercial SKUs
**Description:** Gov-variant Microsoft 365 licensing that carries Secure Score and Compliance Manager.
**Why:** Secure Score (via Defender) and Compliance Manager assessments depend on Gov SKUs. **CMMC
Levels 1–5 assessment templates are included with G5 (Gov)** licensing; the **Microsoft Data Protection
Baseline** is included for all. Commercial E3/E5 SKUs are **not** valid in a GCC High tenant.
**Why (Secure Score):** Full device/app recommendations require the Gov Defender SKUs (for example
**Microsoft 365 E5 for GCC High** or **Microsoft 365 G5 Security for GCC High**, or
**Microsoft Defender for Endpoint for GCC High**).
**Verify:** `https://portal.office365.us` → **Billing → Licenses**; confirm Gov SKUs (names contain
"GCC High" or "for GCC High"). Confirm at least one G5 Gov / G5 Security Gov license if you intend to
use CMMC templates.
**Implement:** Acquire the appropriate Gov SKUs via your Government licensing channel. Do not attempt
to add Commercial SKUs.

## R3. Administrative roles (least privilege) in the sovereign tenant
**Description:** The operator holds the right Entra roles, assigned in the **GCC High** directory.
**Why:** Reading Secure Score, editing improvement actions, and managing Compliance Manager each need
specific roles. In **GCC High and DoD, Compliance Manager user permissions/roles can only be set in
Microsoft Entra ID** (not in the portal's own role UI as in Commercial).
**Verify:** `https://entra.microsoft.us` → **Roles and administrators**. For this solution you
typically need: **Security Reader** (read Secure Score/Compliance), **Security Administrator** (act on
improvement actions), and for Compliance Manager a **Compliance Administrator** / **Compliance Manager**
role assigned **in Entra**. Reserve **Global Administrator** for tenant-wide changes only.
**Implement:** In `entra.microsoft.us` → **Roles and administrators**, assign the least-privilege role
that covers the task. Use **Privileged Identity Management (PIM)** for just-in-time elevation if
available on your Gov SKU.

## R4. Microsoft Defender portal access (Secure Score home)
**Description:** The operator can open the **sovereign** Defender portal.
**Why:** Secure Score lives at `https://security.microsoft.us` in GCC High — **not**
`security.microsoft.com`.
**Verify:** Browse to `https://security.microsoft.us` and confirm it loads your tenant and that
**Microsoft Secure Score** appears in the left navigation.
**Implement:** If it does not load, confirm R2/R3 (Gov license + Security Reader/Administrator) and that
you are signing in with a **GCC High** account against `login.microsoftonline.us`.

## R5. Microsoft Purview portal access (Compliance Manager home)
**Description:** The operator can open the **sovereign** Purview/Compliance portal.
**Why:** Compliance Manager lives at `https://compliance.microsoft.us` in GCC High.
**Verify:** Browse to `https://compliance.microsoft.us` → **Compliance Manager**; confirm your overall
score and the **assessments** list render.
**Implement:** If blocked, confirm the Compliance role is assigned **in Entra** (R3) and the Gov license
(R2) is present.

## R6. Microsoft Graph PowerShell, connected to US Gov
**Description:** The Microsoft Graph PowerShell SDK installed and connecting with `-Environment USGov`.
**Why:** All five scripts read/write through Graph. In GCC High the Graph service root is
`https://graph.microsoft.us`, reached by **`Connect-MgGraph -Environment USGov`**. Omitting
`-Environment USGov` connects to Commercial and **fails** for a GCC High tenant.
**Verify:** In PowerShell:
`Get-MgEnvironment` lists a `USGov` environment whose Graph endpoint is `https://graph.microsoft.us`.
Then `Connect-MgGraph -Environment USGov -Scopes "SecurityEvents.Read.All"` succeeds and
`(Get-MgContext).Environment` returns `USGov`.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser` (from an elevated or user PowerShell
with access to the PowerShell Gallery). If the Gallery is blocked by filtering, allow it or use an
offline package. Always pass `-Environment USGov`.

## R7. Least-privilege Graph scopes consented for this tenant
**Description:** The delegated Graph scopes the scripts need are consented in the GCC High tenant.
**Why:** Read scopes power discovery/validation/report; a small set of write scopes power remediation.
**Verify:** First `Connect-MgGraph -Environment USGov` run prompts for (or shows already-consented)
scopes such as `SecurityEvents.Read.All`, `Directory.Read.All`, `Policy.Read.All`,
`RoleManagement.Read.Directory`. Remediation additionally needs write scopes (for example
`Policy.ReadWrite.ConditionalAccess`), which the remediation script requests explicitly.
**Implement:** A Global Administrator (or Privileged Role Administrator) grants admin consent in
`entra.microsoft.us` → **App registrations / Enterprise applications** the first time, or approves the
interactive consent prompt. Grant **only** the scopes the task requires.

## R8. Network access to the *sovereign* Microsoft cloud endpoints
**Description:** Outbound HTTPS to the **`*.us`** service URLs (not just the Commercial ones).
**Why:** GCC High enrollment, sign-in, Graph, and Defender/Compliance traffic use **different
hostnames** than Commercial. A firewall/proxy allow-list built for Commercial will block GCC High.
**Verify:** From an admin workstation, confirm reachability of `https://login.microsoftonline.us`,
`https://graph.microsoft.us`, `https://security.microsoft.us`, and `https://compliance.microsoft.us`.
**Implement:** Add Microsoft's published **US Government** (GCC High/DoD) URL and IP ranges to the
proxy/firewall allow-list. Do not assume the Commercial 365 URL set covers GCC High.

## R9. A named pilot security group
**Description:** A Microsoft Entra security group for the pilot cohort (default name:
**`SEC-Baseline-Pilot`**).
**Why:** Every baseline/policy change is piloted before tenant-wide rollout. In GCC High, an
auth-impacting mistake has no Commercial fallback, so the pilot gate is mandatory.
**Verify:** `https://entra.microsoft.us` → **Groups**; `SEC-Baseline-Pilot` exists with a small set of
representative members.
**Implement:** `entra.microsoft.us` → **Groups → New group** → type **Security**, name it
`SEC-Baseline-Pilot`, add pilot members. (Script `M365SECG-Set-ScopeTargeting.ps1` can create/populate
it — it defaults to `-WhatIf`.)

## R10. Change control for authentication-impacting changes
**Description:** A documented change/rollback process for anything touching sign-in, Conditional
Access, MFA, or device compliance.
**Why:** Secure Score improvement actions frequently harden authentication; a misstep can lock out
cleared users. GCC High offers no Commercial-cloud escape hatch.
**Verify:** A change ticket exists naming an approver, a maintenance window, the pilot group, and a
concrete rollback step.
**Implement:** Record the change, name `SEC-Baseline-Pilot` as the pilot scope, define the rollback,
and obtain approval before expanding beyond pilot.

---

### Requirements quick-check

| # | Requirement | Sovereign verify location |
| --- | --- | --- |
| R1 | GCC High tenant | `portal.office365.us`, `entra.microsoft.us` |
| R2 | Gov licensing (G3/G5 Gov) | `portal.office365.us` → Billing → Licenses |
| R3 | Admin roles (set in Entra) | `entra.microsoft.us` → Roles and administrators |
| R4 | Defender portal access | `security.microsoft.us` |
| R5 | Purview portal access | `compliance.microsoft.us` |
| R6 | Graph PowerShell `-Environment USGov` | `Get-MgContext` → `USGov` |
| R7 | Graph scopes consented | first `Connect-MgGraph -Environment USGov` |
| R8 | Network to `*.us` endpoints | reach `graph.microsoft.us` etc. |
| R9 | Pilot group `SEC-Baseline-Pilot` | `entra.microsoft.us` → Groups |
| R10 | Change control | change ticket exists |
