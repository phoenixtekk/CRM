# 2. Requirements Guide — AI Data-Exposure Assessment (Microsoft Purview)

Verify **every** requirement before assessing. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the S&C PowerShell +
Graph toolchain, in-scope workloads, stakeholders, pilot/change-control) are in
`global-requirements-purview.md` — this guide adds the exposure-assessment-specific prerequisites.

> **Availability caveat.** DSPM for AI, auto-labeling, advanced DLP, and site-access controls are
> evolving, licensing-/tenant-dependent capabilities whose blades, cmdlets, and audit record types
> change. Where this guide names a portal path, cmdlet, or audit RecordType, **confirm it exists in your
> tenant** rather than assuming — several requirements below are "verify in your tenant" by design.

## 2.1 Compliance / AI licensing (verify in your tenant)
**Description:** The compliance licensing the assessment relies on — commonly **Microsoft 365 E5** or the
**E5 Compliance** add-on for advanced DLP, auto-labeling, and the DSPM-for-AI reports; some AI-exposure and
site-access controls may additionally require **SharePoint Advanced Management** and/or a **Microsoft 365
Copilot** license. The assessment can run on a licensed subset — it notes any absent capability rather than
failing.
**Why:** The reachability signal and the fix-path validation lean on plan-gated features (auto-labeling,
advanced DLP, DSPM for AI); their presence bounds what can be measured and validated.
**Verify:** In the M365 admin center confirm the subscriptions/add-ons; in the Purview portal
(`https://purview.microsoft.com`) confirm **DSPM for AI** is visible. Run `AIEXPOSE-ScopeCheck.ps1`
(read-only) to enumerate the licensing-dependent features present.
**Implement:** Assign/purchase the required licensing before starting; where a capability is absent, note it
out of scope and assess the licensed subset.

## 2.2 Least-privilege assessment roles and portal access
**Description:** Membership in the least-privilege Purview role group(s) needed to **read** posture and
configuration — typically an information-protection / compliance-reader-capable role group — plus, only for
the simulation fix-path validation, the role that can **create an auto-labeling policy in simulation**.
Confirm the **exact current role-group names** in your portal.
**Why:** Purview uses fine-grained role groups; reading labels/DLP/reachability and creating a simulation
policy each need the matching role, and separation of duties should be preserved (reading exposure ≠
changing enforcement).
**Verify:** Purview portal → **Settings / Roles & scopes → Role groups** — confirm your account's
membership; confirm you can open **DSPM for AI** without an access error.
**Implement:** Assign the least-privilege role group under change control; reserve Global/Compliance
Administrator for the initial enablement only.

## 2.3 Unified auditing turned on
**Description:** Purview **Audit** (the unified audit log) enabled tenant-wide, since the AI-interaction
signal and the broad-sharing signal are sourced from audit records.
**Why:** Without auditing on, the "what has AI actually touched" and "what was shared broadly" signals are
empty or incomplete, weakening the reachability measurement.
**Verify:** Purview portal → **Audit** shows searching is on; `AIEXPOSE-ScopeCheck.ps1` reports
`UnifiedAuditLogIngestionEnabled`. AI-interaction records should be present once Copilot/AI has been used.
**Implement:** Turn on auditing (a one-time tenant action); allow time for records to accumulate before
expecting AI-interaction reports to populate.

## 2.4 A labels + DLP baseline to measure exposure against
**Description:** At least a **baseline of sensitivity labels and DLP** in place (or ready to create),
because the assessment measures exposure *relative to* the protection that exists and validates a fix that
acts *through* labels and DLP.
**Why:** Label coverage and DLP scope bound how much exposure can be reduced; their absence is itself a
top-of-register finding (the register adds a no-lever penalty when no DLP exists).
**Verify:** Purview portal → **Information Protection → Labels** and **Data Loss Prevention → Policies**;
`AIEXPOSE-Discovery.ps1` inventories labels, label policies, DLP policies/rules, and auto-labeling policies.
**Implement:** A thin or absent taxonomy/DLP is a valid finding — record it. A dedicated sensitivity-labels
or DLP solution stands up the baseline that any recommended fix would use.

## 2.5 Microsoft 365 Copilot / AI apps in scope
**Description:** Clarity on which AI is in scope — **Microsoft 365 Copilot**, Copilot experiences, and/or
other **enterprise AI apps** — and whether it is licensed and in use, so the assessment is framed correctly
as **pre-adoption** (measure exposure before turning AI on) or **in-adoption** (measure what AI already
touches).
**Why:** The value pivots on this: pre-adoption, the assessment quantifies risk to inform the go/no-go;
in-adoption, it also reads the AI-interaction signal of actual contact with sensitive data.
**Verify:** Confirm Copilot/AI licensing and rollout status with the owning team; Purview portal → **DSPM
for AI** shows connected AI activity once present. `AIEXPOSE-ScopeCheck.ps1` probes whether AI-interaction
audit records exist.
**Implement:** Confirm the AI in scope with stakeholders; if Copilot is not yet deployed, run the assessment
in **pre-adoption** mode — the oversharing signal is still the exposure to quantify before enabling AI.

## 2.6 SharePoint/OneDrive access & sharing signal
**Description:** The ability to read **site/file access and sharing** state — the "oversharing" that makes
content reachable by AI — from the unified audit log and/or Microsoft Graph, and (for the strongest
site-access controls that a fix might later use) **SharePoint Advanced Management** (verify licensing).
**Why:** Reachability scoring targets broadly-shared and organization-wide-accessible content; measuring it
needs the sharing/access signal, and the sharing Operations that surface it evolve.
**Verify:** `AIEXPOSE-Discovery.ps1` reports the broad-sharing signal from the audit log (Operations are
parameterized); confirm whether SharePoint Advanced Management site-access controls are available in your
tenant.
**Implement:** Where the advanced site-access controls are unavailable, the register still ranks the
oversharing targets; site-owner sharing reviews and the label + DLP levers are the reduction path a
follow-on would use.

## 2.7 Pilot scope and simulation discipline
**Description:** A named **pilot scope** (a ring of users/sites) and the intent to validate the recommended
fix **only in simulation** — the assessment's single change is an auto-labeling policy in **simulation
mode** that labels nothing (as the category model requires, GR §6). Enforcement is explicitly out of scope
for the assessment.
**Why:** Even fix-path validation must not disturb real content; simulation surfaces whether the fix would
land correctly before anyone commits to enforcing it.
**Verify:** Confirm the pilot ring, that auto-labeling **simulation mode** is available, and that a change
window/approval exists for creating the simulation policy.
**Implement:** Define the pilot and the change-control path before creating the simulation policy; the
scripts default to `-WhatIf` and create the policy in simulation only — they never enforce.
