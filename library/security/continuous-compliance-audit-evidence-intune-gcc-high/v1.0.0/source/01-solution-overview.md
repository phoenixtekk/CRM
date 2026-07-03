# Solution Overview — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

## What this solution delivers

This is the **Government (GCC High)** edition of the continuous-compliance solution. Passing a CIS or
STIG baseline **once** is not the same as **proving** you are still compliant months later, when an
assessor asks for evidence. In a **US sovereign-cloud** tenant this is not a nicety — it is how you
keep an authorization. Devices drift: a policy is edited, an exclusion is added, a new device enrolls
without the baseline, a user with local rights changes a setting.

This solution gives a competent-but-novice government administrator a **repeatable, operational
method** — with PowerShell scripts you keep and reuse, all targeting **US Gov Graph** — to:

1. **Baseline** — take the CIS/STIG control set you already deployed to Intune + Entra in **GCC High**
   and treat it as the *expected state* (the reference you measure against).
2. **Measure** — read the *current state* of those controls for each in-scope device and identity
   directly from **Microsoft Graph US Gov** (`graph.microsoft.us`, read-only).
3. **Detect drift** — compare current state to the baseline and flag every control that no longer
   matches (drifted, missing, or newly non-conformant).
4. **Evidence / POA&M** — export the measurement as **audit evidence** (a dated, per-control,
   per-device record) and produce a **POA&M-ready gap list** (Plan of Action & Milestones) of the
   controls that fail — the exact artifact FedRAMP continuous monitoring and NIST 800-53 **CA-5**
   expect.
5. **Remediate / track** — safely re-apply the drifted baseline assignment (preview first) and
   re-measure to confirm the gap closed — then keep the cycle running on a schedule.

This is an **operations product**, distinct from a one-time baseline *build*. The build creates the
policies; **this solution watches them stay true and produces the paperwork** a Gov audit requires.

## Why GCC High is a different solution, not a re-login

Intune + Entra in **GCC High is not the Commercial portal with a different sign-in.** Two things
differ in ways that break Commercial runbooks:

- **The portals and endpoints are different sovereign-cloud hosts.** You administer Intune at
  **`intune.microsoft.us`**, Entra at **`entra.microsoft.us`**, sign in at
  **`login.microsoftonline.us`**, and your scripts must target **US Gov Graph**
  (`graph.microsoft.us`, `Connect-MgGraph -Environment USGov`; DoD uses `dod-graph.microsoft.us`,
  `-Environment USGovDoD`). Point a Commercial runbook at `graph.microsoft.com` or `intune.microsoft.com`
  and you are querying the wrong cloud — it will silently return nothing or fail auth.
- **Feature parity lags Commercial.** Several Intune reporting, update, and remediation conveniences
  that are generally available in Commercial are, in GCC High/DoD, **planned-not-yet-available** or
  **not available at all** (for example the Intune Power BI/Data-Warehouse connector, the ServiceNow
  connector, Windows Autopatch, feature/quality update rings, BIOS/DFCI profiles, Remote Help). A
  Commercial runbook that assumes those will silently fail: the menu or option simply is not there.

The good news for *this* solution: the **read-only measurement and evidence method uses Standard MDM
state + Graph**, which **is** supported in GCC High/DoD. The parity gaps hit the **downstream
analytics/integration and update tooling** — so this solution's own CSV/JSON evidence + POA&M exports
(optionally backed by Log Analytics) are exactly the right pattern for a Gov tenant. This edition
calls out the correct GCC High portals/endpoints at each step and flags the parity gaps **where they
matter**. The full parity reference lives in `gcc-high-parity-notes.md` and is cited throughout.

## The continuous-compliance model

```
   Baseline ──▶ Measure ──▶ Detect drift ──▶ Evidence / POA&M ──▶ Remediate / track
   (expected)   (current)    (compare)         (export)             (fix + re-measure)
      ▲                                                                     │
      └─────────────────────────  re-baseline on approved change  ◀────────┘
```

- **Baseline (expected state).** Your approved CIS/STIG configuration in Intune (Settings Catalog /
  device-configuration / compliance policies / Security Baselines) and Entra (Conditional Access,
  authentication methods, tenant security settings) **in the GCC High tenant**. The specific CIS
  Benchmark / DISA STIG **rule IDs and official control text are deferred to CIS and DISA** — this
  solution does not reproduce or fabricate them. (Microsoft itself points GCC High/DoD admins to the
  DISA STIGs library on `public.cyber.mil` for the hardening content.)
- **Measure (current state).** The scripts query **Microsoft Graph US Gov** read-only for the live
  value of each monitored control on each in-scope device/identity — no changes during measurement.
- **Detect drift.** Current vs. expected, per control per device: **Pass** (matches baseline),
  **Drift** (was compliant, now differs), **Missing** (baseline not applied to this device), or
  **Non-conformant** (never matched).
- **Evidence / POA&M.** Two exports: (a) an **audit-evidence** package — timestamped, immutable
  CSV/JSON showing what was measured, when, by whom, and the result; (b) a **POA&M-ready gap** list —
  each failing control with device count, severity, and a milestone/owner column ready to paste into
  your organization's POA&M template. (The Intune ServiceNow connector is **not available** in GCC
  High, so the POA&M CSV is designed to be imported into your GRC/ITSM by hand — see
  `gcc-high-parity-notes.md` §2.)
- **Remediate / track.** For drifted settings only, a safe remediation re-applies the baseline
  targeting (default **preview / -WhatIf** — nothing changes until you confirm). Re-measure to prove
  closure; the evidence trail records the fix.

## Commercial vs GCC High — what's different

*(Portals are always different. Feature statuses are doc-confirmed from Microsoft's *Intune Government
Service overview*, 2026-06-04, unless flagged. See `gcc-high-parity-notes.md` for the full tables and
citations.)*

**Portals & endpoints (always different):**

| Purpose | Commercial | GCC High / DoD |
| --- | --- | --- |
| Sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Entra admin | `entra.microsoft.com` | `entra.microsoft.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Graph (scripts) | `graph.microsoft.com` (`-Environment Global`) | `graph.microsoft.us` (`-Environment USGov`) · DoD `dod-graph.microsoft.us` (`-Environment USGovDoD`) |

**Feature parity gaps that change how you design (GCC High/DoD status in parentheses):**

- **Intune Power BI connector for Data Warehouse** is **not available** (*no planning*). Do **not**
  build evidence dashboards on the Intune DWH/Power BI connector; use this solution's Graph exports
  plus **Log Analytics** (which *is* available).
- **ServiceNow connector** is **not available** (*no planning*). Import the POA&M CSV into your
  GRC/ITSM manually rather than pushing via the native connector.
- **Windows Autopatch** and **feature / quality / expedite / driver update rings for Windows** are
  **planned — not yet available**. If a control depends on a patch level, drive updates through your
  existing Gov-approved mechanism, not these Intune rings.
- **BIOS configuration profiles / DFCI management** are **planned — not yet available**. STIG rules
  needing BIOS/DFCI enforcement are out-of-band in GCC High for now — flag them.
- **Remote Help** is **planned — not yet available** (no native Intune hands-on remediation tool).
- **Cloud PKI** is **planned — GCC High only** (not listed for **DoD**). Verify for DoD if certificate
  controls are in your baseline.
- **Security Copilot in Intune** and **Windows Device Health Attestation (DHA)** are **planned — not
  yet available**. Do not assume Copilot triage or DHA as a compliance signal.
- **Advanced Analytics**, **Log Analytics/Azure Monitor export**, and **Standard MDM** (compliance
  policies, configuration/Settings Catalog profiles, device compliance state) **are available** — this
  is what the solution reads. **Verify** the specific analytics report you want renders in
  `intune.microsoft.us`.

Where an option is not visible in `intune.microsoft.us`, treat it as a **GCC High/DoD parity gap, not
a permissions problem** — re-check the parity table before troubleshooting.

## The standard deployment model

This solution follows the category standard, with a **pass/fail gate** at each stage:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm Gov licensing (G3/G5 / EMS G-SKUs), roles, **GCC High portal access**, and
  which features are actually available in your GCC High/DoD tenant (the parity check).
- **Configure** — turn your deployed CIS/STIG baseline into a machine-readable expected state; build
  the scope groups. Name every object verbatim.
- **Pilot** — prove the method on a small **named pilot group** (`CCAUDITG-Pilot-Devices`): measure,
  seed a controlled drift, export evidence.
- **Validate** — run the pass/fail gates against the pilot; confirm evidence and POA&M meet your ATO
  requirements.
- **Expand** — widen to the fleet on a schedule only after the gate passes.

The scripts are **read-only by default**; the only script that changes anything (Remediation) and the
targeting builder (Set-ScopeTargeting) run in **preview (-WhatIf)** until you explicitly commit.

## What you get

- This documentation set: **Overview**, **Requirements**, **Implementation** (Gov portals + inline
  parity caveats; drift monitoring + POA&M evidence), **Testing** (pass/fail gates), **Troubleshooting**
  (with GCC-High-specific gotchas), **Best Practices**, **Deliverables Summary**, and **Executive
  Summary**.
- A **GCC High parity notes** reference (`gcc-high-parity-notes.md`) with per-feature status and
  Microsoft citations.
- **Five PowerShell scripts** (Microsoft Graph SDK, **US Gov endpoints**): control-state **Discovery**,
  per-device baseline **Validation**, an audit-evidence + drift/gap **Report** (POA&M-ready), safe
  **Remediation** of drifted settings (default preview), and a **Set-ScopeTargeting** pilot/fleet-group
  builder (default preview).

> **Sources:** Microsoft Learn — *Microsoft Intune Government Service overview* (2026-06-04);
> *Network endpoints for US government deployments — Microsoft Intune* (2025-12-15); *Access national
> cloud deployments with the Microsoft Graph SDKs*; *Microsoft Entra feature availability in Azure for
> US Government*. Full citations in `gcc-high-parity-notes.md`.
