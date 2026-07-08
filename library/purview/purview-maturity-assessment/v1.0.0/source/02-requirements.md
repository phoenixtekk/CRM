# 2. Requirements Guide — Microsoft Purview Maturity Assessment

Verify **every** requirement before scoring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (read that
first — this guide adds the assessment-specific prerequisites and does not repeat the six).

## 2.1 Read access across the Purview compliance estate (least-privilege)
**Description:** An admin account with the least-privilege roles needed to **read** every domain the
model scores — for example **Global Reader** or **Compliance Administrator** for the portal, plus the
role groups that expose each solution (Information Protection Reader, DLP, Records Management, Insider
Risk, Communication Compliance, Audit, eDiscovery reader roles). The assessment is read-first; write
access is only needed for the optional quick-win baseline.
**Why:** Purview uses fine-grained role groups; a domain the account cannot read will score falsely as
`L0 Absent`. The score must reflect what exists, not what the account can see.
**Verify:** Purview portal → **Settings → Roles and scopes → Role groups**; confirm membership. Run
`PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck` — it reports which domains the account can read.
**Implement:** Add the account to **Global Reader** / **Compliance Administrator** and the per-solution
reader roles under change control. Reserve write roles for the remediation step only.

## 2.2 Licensing inventory (what caps each domain's achievable level)
**Description:** A confirmed record of the tenant's compliance licensing — E3 / Business Premium
baseline vs **Microsoft 365 E5** or the **E5 Compliance** add-on — because several domains
(D4 Insider Risk, D5 Communication Compliance, D6 Audit **Premium**, D8 DSPM, D7 advanced eDiscovery)
are **plan-gated** and some DSPM/AI features are **preview**.
**Why:** A domain that is absent only because it is *unlicensed* is a different finding from one that is
*licensed but unconfigured*. The scorecard distinguishes the two; the roadmap must not recommend
enforcing a capability the tenant cannot license.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; run `PURVIEW-Discovery.ps1` which
flags licensing signals per domain. Where a signal is ambiguous, the report marks it
**"verify your licensing/tenant."**
**Implement:** Record the current plan and add-ons. Do **not** assume E5 — confirm it. If a domain is
unlicensed, mark its ceiling and note the license as a roadmap dependency, not a config task.

## 2.3 The maturity model, target levels, and domain weighting agreed
**Description:** Agreement, before scoring, on the model to use (`Purview Maturity Model - 10 Domains x
6 Levels`), the **target level** for each domain (not every org needs L5 everywhere), and the
**weighting** each domain carries in the overall band.
**Why:** A score is only meaningful against a target. Regulatory-driven organizations weight
D3 (records), D6 (audit), and D7 (eDiscovery) higher; IP-sensitive ones weight D1/D2. Without agreed
targets and weights the roadmap has no destination.
**Verify:** A one-page model exists listing the ten domains, each domain's target level, and its
weight. Stakeholders (below) have signed off.
**Implement:** Adopt the model in this solution as the default, then adjust targets/weights with the
compliance, security, and records owners before scoring.

## 2.4 Evidence scope — workloads and data sources in scope
**Description:** The workloads the assessment reads for evidence — Exchange, SharePoint, OneDrive,
Teams, endpoints/devices, and (for D9) the broader data estate registered in the Data Map — and any
that are explicitly **out of scope** for this round.
**Why:** Domain scores key off configured scope; a DLP policy that covers only Exchange should not
score the same as one covering all five workloads. Excluding a workload silently would inflate scores.
**Verify:** Confirm the in-scope workloads with stakeholders; `PURVIEW-Discovery.ps1` reports per-domain
scope coverage.
**Implement:** Define the in-scope workloads and data sources before running discovery; record any
exclusions so the scorecard notes them.

## 2.5 Compliance, records, privacy & legal stakeholders engaged
**Description:** Named owners from **compliance, records management, privacy, security, HR, and legal**
who set the target levels, own the regulated domains, and receive the readout.
**Why:** Target levels and the roadmap's priorities are business/regulatory decisions, not technical
defaults. D4 Insider Risk and D5 Communication Compliance are HR/privacy-sensitive — their scoring and
any remediation require HR/legal involvement and strict role separation.
**Verify:** Named owners exist per regulated domain; the readout distribution list is agreed.
**Implement:** Identify the owners and capture their target levels before scoring; route D4/D5 findings
to HR/legal, never actioned by IT alone.

## 2.6 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, using a modern-auth / MFA-capable
admin — the toolchain the assessment scripts run through.
**Why:** Discovery, scoring, validation, and reporting are delivered as PowerShell; the evidence is
read through these modules.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; run
`PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`.
**Implement:** Install `ExchangeOnlineManagement` and `Microsoft.Graph`; confirm modern-auth sign-in
before running the scripts. Never store credentials in the scripts.

## 2.7 A pilot scope and change control (for quick-win remediation only)
**Description:** A **pilot scope** (a Microsoft Entra security group, `Purview - Pilot Users`) and a
**change-control** process, needed only if the assessment proceeds to apply a quick-win baseline. Every
Purview policy the baseline touches supports a **simulation / test / disabled** mode that MUST be used
before enforcement.
**Why:** The assessment itself is read-only, but its recommended quick wins (a starter label, a DLP
policy in test, enabling audit) are configuration changes and follow the house pilot-first model.
**Verify:** Entra → **Groups** — `Purview - Pilot Users` exists; a change window/approver is named. Run
`PURVIEW-Set-ScopeTargeting.ps1` to create/confirm the group.
**Implement:** Build the pilot group with `PURVIEW-Set-ScopeTargeting.ps1`; agree change control before
`PURVIEW-Remediation.ps1` is run with `-Commit`.

---
## Checklist
- [ ] Least-privilege read access across all ten domains — `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`
- [ ] Licensing inventory captured (E3/BP vs E5 / E5 Compliance; preview flags) — `PURVIEW-Discovery.ps1`
- [ ] Maturity model adopted; per-domain target levels + weighting agreed
- [ ] Evidence scope (workloads/data sources) defined; exclusions recorded
- [ ] Compliance / records / privacy / HR / legal owners named; D4/D5 routed to HR/legal
- [ ] S&C PowerShell + Graph toolchain working — `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`
- [ ] Pilot group `Purview - Pilot Users` + change control (quick-win remediation only)
