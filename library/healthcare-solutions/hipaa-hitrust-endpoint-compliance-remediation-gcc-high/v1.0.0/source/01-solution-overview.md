# 1. Solution Overview — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

This is the **Government (GCC High) edition** of the HIPAA & HITRUST Endpoint Compliance &
Vulnerability Remediation solution. It walks a novice administrator through mapping the **HIPAA
Security Rule** (45 CFR Part 164, Subpart C) technical safeguards and the **HITRUST CSF** control
expectations to enforceable, auditable controls on clinical Windows endpoints — using **Microsoft
Intune** and **Microsoft Defender for Endpoint (Defender Vulnerability Management)** on a **US
sovereign-cloud (GCC High)** tenant, with the **`.us` admin portals**, **US Gov service endpoints**,
and **US Gov Microsoft Graph**, and the **Commercial-vs-GCC High parity gaps** called out where they
change what you can do.

> **Why a separate Government edition?** GCC High is **not** the Commercial portal behind a different
> sign-in. The admin URLs differ, the device onboarding/telemetry endpoints differ, the Graph
> environment differs, and **some Intune and Defender capabilities lag, are limited, or are absent**
> versus Commercial. Following Commercial steps on a GCC High tenant leads you to portals that don't
> exist there and to features that silently aren't present (most consequentially, several **Windows
> Update policies** and **classic Autopilot** in Intune). This edition gives you the **sovereign-correct**
> path.

## Description

The solution operationalizes the loop that auditors actually ask for — **enforce** the control,
**gate** access on it with Conditional Access, **remediate** the vulnerabilities the enforcement
surfaces, and **produce evidence** that proves it — but every portal, endpoint, and Graph call targets
the **US Government cloud**. It delivers a repeatable phase model and five PowerShell tools that all
connect to **US Gov Graph** (`-Environment USGov`, `graph.microsoft.us`).

> **Important — what this is and is not.** HIPAA and HITRUST are **frameworks**, not products. This
> solution provides the **technical enforcement and evidence layer** that supports a compliance
> program on a sovereign tenant; it does **not** by itself make an organization "HIPAA compliant" or
> confer any HITRUST certification. Legal compliance and certification require organizational policies,
> risk analysis, workforce training, business associate agreements, physical safeguards, and (for
> HITRUST) a formal assessment by an authorized External Assessor. Treat this as the part a Microsoft
> administrator can build and prove — the device-level safeguards and the evidence that they operate.

## Why this matters

Most healthcare and government organizations can *state* a security policy ("all devices that access
ePHI must be encrypted, lock automatically, run antivirus, and stay patched") but cannot *enforce* it
on every endpoint or *prove* it on demand. A HIPAA audit (or an OCR investigation after a breach) and
a HITRUST assessment both turn on the same question: show me that the safeguard was configured, applied
to the in-scope devices, and operating during the period under review. On a GCC High tenant this is
harder to get right, because a doc that points you at `security.microsoft.com` or a script that omits
`-Environment USGov` silently reaches the **Commercial** cloud and returns nothing — which looks
exactly like "no devices / no evidence." This edition removes that failure mode.

## The portals you will use (GCC High — memorize these)

| Purpose | Commercial URL | **GCC High URL (use this)** |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Microsoft Defender portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Microsoft Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |

> The Defender portal URL differs again for **DoD** (`security.apps.mil`) and **GCC**
> (`security.microsoft.com`). This solution targets **GCC High → `security.microsoft.us`**. If your
> tenant is GCC or DoD, substitute the matching portal from the table in `gcc-high-parity-notes.md`.
> Cited: Microsoft, *"Microsoft Defender for Endpoint for US Government customers"* — Portal URLs.

## Commercial vs GCC High — what's different

Read this before you start. These are the differences that actually change the steps:

- **Different admin portals.** Every portal is a `.us` (or `portal.office365.us`) host, not `.com`. A
  bookmark that sends you to a `.com` portal is Commercial and will show you the wrong (or an empty)
  tenant.
- **Different sign-in authority.** Authentication is `login.microsoftonline.us`. Scripts and API
  clients must target the **US Gov** authority, not the Commercial one.
- **Different Microsoft Graph environment.** Automation connects with
  **`Connect-MgGraph -Environment USGov`** (US Gov L4 Graph, `graph.microsoft.us`). Omit it and the
  session silently talks to the Commercial cloud and returns nothing for your tenant.
- **Different Defender API base URIs.** The Defender for Endpoint API is
  `https://api-gov.securitycenter.microsoft.us` for **GCC High & DoD** (and
  `https://api-gcc.securitycenter.microsoft.us` for GCC) — **not** the public
  `api.securitycenter.microsoft.com`. Cited: Microsoft — *…for US Government customers*, "API."
- **Different device onboarding/telemetry endpoints.** Devices must reach the **US Gov service URLs**
  (the "Gov/GCC/DoD" connectivity URL lists), not the Commercial MDE endpoints; use the **streamlined**
  Gov URL list where supported (marked **Preview** — verify). Cited: Microsoft — Required connectivity
  settings (Gov/GCC/DoD).
- **Intune update-policy and provisioning gaps (design-affecting).** In GCC High, the newer **Windows
  Update policies** — *feature, quality, expedite, driver updates, Autopatch, Delivery Optimization* —
  are **planned but not yet available**, and **classic Windows Autopilot is not available**. The patch
  safeguard in this solution therefore uses an **Update ring for Windows 10 and later** (Windows Update
  for Business rings, a standard MDM feature that **does** work in GCC High) plus the compliance
  policy's **Minimum OS version** — not the update *policies* or their reports. *Verify current Gov
  availability before relying on any of them.* Cited: Microsoft — Intune Government Service overview.
- **Defender parity gaps.** **Microsoft Threat Experts** and **enterprise IoT security** are **not
  available**; **Microsoft Secure Score** is present but **omits some recommendations**. **Defender
  Vulnerability Management core + premium are available** (the remediation engine works), but **Report
  inaccuracy** and **Request CVE support** are **not** available in Gov. The full, cited map is in
  `gcc-high-parity-notes.md`.

> Everything else — the *shape* of the control set (map → enforce with compliance policy + baselines →
> gate with Conditional Access → remediate with Defender TVM → evidence) — is the same as Commercial.
> The prevention/detection/remediation engine is the same underlying technology, built in the Azure US
> Government environment. Cited: Microsoft — *…for US Government customers*, overview.

## Scope

**In scope**
- Mapping HIPAA Security Rule technical safeguards and HITRUST CSF control expectations to specific,
  enforceable **Intune** and **Defender** settings on a **GCC High** tenant.
- **Intune device compliance policies** for clinical Windows endpoints: BitLocker encryption, screen
  lock / inactivity timeout, Microsoft Defender Antivirus healthy + signatures current, firewall
  enabled, minimum OS build / patch currency, and account/sign-in controls.
- **Intune configuration baselines** (settings catalog / disk-encryption / endpoint-security policies)
  that *enforce* what the compliance policy *measures*.
- A **Conditional Access** gate that requires device compliance before access to corporate cloud
  resources.
- **Microsoft Defender Vulnerability Management (TVM)** — exposure scoring, security recommendations,
  and a remediation workflow with exception handling (core + premium available in GCC High).
- **Evidence and reporting** — audit-ready exports of compliance state, configuration proof, and
  exposure/remediation trend, produced by the included US-Gov-Graph scripts.

**Out of scope**
- Legal interpretation of HIPAA/HITRUST applicability, risk analysis methodology, or any compliance
  attestation/certification.
- macOS, iOS/iPadOS, Android, and Linux endpoints (named objects target Windows clinical endpoints; the
  pattern is extensible).
- Server, EHR-application, network, and physical safeguards beyond the endpoint.
- The DoD and (Intune-Commercial) GCC clouds beyond the substitution note above — this edition targets
  **GCC High**.

## Objects this solution creates (named, and reused across the docs)

You will create and **reuse** these exact objects throughout the guide (created in
`intune.microsoft.us` / `entra.microsoft.us`):

| Object | Name | Where |
| --- | --- | --- |
| Clinical endpoint scope group | **`HIPAA – Clinical Endpoints`** | Entra (`entra.microsoft.us`) → Groups |
| Compliance policy | **`HIPAA Compliance – Clinical Endpoints – Policy`** | Intune → Devices → Compliance |
| Encryption baseline (BitLocker) | **`Encryption – Clinical Endpoints – Baseline`** | Intune → Endpoint security → Disk encryption |
| Lock / auto-logoff baseline | **`Lock – Clinical Endpoints – Baseline`** | Intune → Devices → Configuration (settings catalog) |
| Antivirus baseline (Defender AV) | **`Antivirus – Clinical Endpoints – Baseline`** | Intune → Endpoint security → Antivirus |
| Firewall baseline | **`Firewall – Clinical Endpoints – Baseline`** | Intune → Endpoint security → Firewall |
| Patch baseline (Update ring) | **`Patch – Clinical Endpoints – Baseline`** | Intune → Devices → Windows → Update rings |
| Access / sign-in baseline | **`Access – Clinical Endpoints – Baseline`** | Intune → Devices → Configuration (settings catalog) |
| Vulnerability remediation task | **`Vulnerability – Clinical Endpoints – Remediation`** | Defender (`security.microsoft.us`) → Vulnerability management |
| Conditional Access gate | **`Require Compliance – Clinical Endpoints – Gate`** | Entra → Conditional Access |

## The standard deployment model

Like every solution in this library, you follow **Assess → Configure → Pilot → Validate → Expand**,
with a **gate** at each boundary (do not proceed until the gate passes). Mapped onto the control loop:

1. **Assess** — confirm GCC High tenant, US Gov licensing, roles, `.us` portal access, endpoint
   reachability, and map controls to settings (`02-requirements.md`, `03-implementation.md` Phase 1).
2. **Configure** — build the compliance policy and configuration baselines (Phase 2).
3. **Pilot** — assign to a pilot subset of **`HIPAA – Clinical Endpoints`**, gate in **Report-only**.
4. **Validate** — run the included scripts and the Testing Guide (`05-testing.md`); confirm Compliant,
   safeguards enforced, gate behaves, TVM exposure captured.
5. **Expand** — enable the gate, roll out in waves, and run the Remediate/Evidence/Operate loop
   continuously.

## Outcomes

After implementing this solution on your GCC High tenant you will have:
1. A documented **control-to-policy mapping** linking each in-scope HIPAA/HITRUST safeguard to a named
   Intune/Defender object and a named owner.
2. Clinical Windows endpoints evaluating **Compliant** against an enforced sovereign baseline.
3. A **Conditional Access** gate that blocks non-compliant clinical endpoints from corporate resources.
4. A running **Defender TVM remediation workflow** with measurable exposure reduction and a documented
   exception process (built with the two Gov-unavailable functions — *Report inaccuracy*, *Request CVE
   support* — designed around).
5. **Audit-ready evidence** produced on a schedule from **US Gov Graph**, stored in a defined,
   access-controlled evidence repository.

## Audience

Healthcare and government IT/security administrators, virtual CISOs and compliance leads, and MSPs
delivering managed compliance for regulated sovereign-cloud clients. The pattern applies to any
regulated organization on GCC High that must enforce and evidence endpoint security controls.

---
*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"
(learn.microsoft.com/defender-endpoint/gov); "Microsoft Intune Government Service overview"; "Network
endpoints for US government deployments." Verify all GCC High / DoD specifics against your tenant, as
US Gov availability changes over time. See `gcc-high-parity-notes.md` for the full cited parity map.*
