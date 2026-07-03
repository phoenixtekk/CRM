# 1. Solution Overview — Intune Compliance-Failure Diagnostics & Remediation (Government / GCC High)

This is the **Government (GCC High) edition**. It diagnoses and remediates **Intune device
compliance failures** on a **US sovereign-cloud** tenant — where the admin portals, service
endpoints, and Microsoft Graph all live on `*.us` domains, and where a handful of compliance-relevant
features behave differently from, or are absent versus, the Commercial cloud. Following Commercial
steps on GCC High produces *silent* failures: you sign into the wrong portal, allow the wrong
endpoint through the proxy, or script against the Commercial Graph — and devices never turn compliant.

## What this solution does

A device that reports **Not compliant** (or **Not evaluated**, or **In grace period**) blocks
Conditional Access and locks the user out of Microsoft 365. This solution gives a novice admin a
**symptom-driven Diagnostic Playbook** (section 3) that walks from the symptom the user reports to
the exact GCC High portal blade, the exact setting, and a safe fix — plus five PowerShell scripts
that connect to **US Gov Graph** (`Connect-MgGraph -Environment USGov`) to discover, validate,
report, and (with `-WhatIf` by default) remediate.

The scope is **diagnostics and remediation of existing compliance policies**, not authoring a
compliance baseline from scratch. You already have compliance policies; this fixes why devices fail
them on GCC High.

## The deployment model (all solutions)

**Assess → Configure → Pilot → Validate → Expand.** Here that maps to: **Assess** the reported
symptom and the tenant's compliance surface (Discovery/Report scripts) → **Configure** the fix in the
correct GCC High blade → **Pilot** on one affected device or a small group → **Validate** the device
turns compliant (Validation script + portal) → **Expand** the fix to the affected population.

## Commercial vs GCC High — what's different

GCC High is **not** the Commercial portal with a different sign-in. The differences below are the
ones that change how you *diagnose* compliance. Every one is drawn from Microsoft's own US Government
documentation (cited in `gcc-high-parity-notes.md`); anything Microsoft does not explicitly confirm
for GCC High is flagged **"verify for GCC High"** rather than assumed.

**1. Different admin portals and service URLs — all `*.us`.** Using a `.com` portal or endpoint on a
GCC High tenant causes authentication failures, so a device or admin "silently" never reaches the
service.

| Purpose | Commercial | **GCC High** |
| --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Entra admin center | `entra.microsoft.com` | **`portal.azure.us`** (Microsoft Entra ID blade) |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** |
| Defender portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Purview / Compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** |
| Company Portal (web) | `portal.manage.microsoft.com` | **`portal.manage.microsoft.us`** |
| Sign-in (Evo STS) | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** |

**2. Devices reach a different set of service endpoints.** Compliance check-in, enrollment, and
reporting flow through **`*.manage.microsoft.us`** and **`*.dm.microsoft.us`** — and SSL/TLS
inspection is **not supported** on `*.manage.microsoft.us` (or on the Defender/EPM `*.dm.microsoft.us`
endpoints). A proxy that breaks TLS on those is one of the most common causes of a device stuck at
**Not evaluated** in GCC High. Section 2 lists the endpoints; section 3 turns them into a symptom.

**3. Some compliance-relevant features are absent or lag.** The features that most often change a
GCC High compliance diagnosis:
- **Classic Windows Autopilot is not available** in GCC High (only Autopilot **device preparation**,
  with some modes still planned) — so "device isn't compliant right after provisioning" has a
  different root cause than in Commercial.
- **Cloud PKI** (GCC High) and **Remote Help** are **planned, not yet available** — certificate-based
  compliance and assisted remediation workflows differ.
- **Mobile Threat Defense (MTD)** connectors work **only for vendors that also support GCC High** —
  a "device risk level" compliance rule can be un-evaluatable if your MTD vendor isn't in GCC High.
- **Some newer Windows Device Health Attestation (DHA) capabilities** are listed as planned for GCC
  High; the core BitLocker / Secure Boot / Code Integrity compliance settings **do** use the DHA
  service across Commercial, GCC High, and DoD. This nuance is called out precisely in section 3 and
  `gcc-high-parity-notes.md` — **verify for GCC High** before promising a specific DHA-backed rule.

**4. Scripting must target US Gov Graph.** Every script in this pack connects with
`Connect-MgGraph -Environment USGov` (use `-Environment USGovDoD` for DoD). Omit `-Environment` and
the module authenticates against the Commercial endpoint and returns nothing — the single most common
scripting failure on GCC High.

## What's inside

- **This overview**, an **executive summary**, a **requirements guide** (section 2), the
  **Diagnostic Playbook** (section 3), a **testing guide** (section 5), a **troubleshooting guide**
  (section 6), **best practices** (section 7), a **deliverables summary** (section 8), and a cited
  **GCC High parity reference** (`gcc-high-parity-notes.md`).
- **Five PowerShell scripts** — Discovery, Validation, Report (all read-only), Remediation and
  Set-ScopeTargeting (both default to `-WhatIf`), all on US Gov Graph.

## Who this is for

A novice-to-intermediate admin operating a GCC High tenant who needs to turn **Not compliant** into
**Compliant** correctly — using the right sovereign portals and endpoints, with the Commercial-vs-GCC
High gaps called out so nothing fails silently.
