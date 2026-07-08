# 2. Requirements Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Verify **every** requirement before configuring. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, stakeholders, pilot/change-control) are in
`global-requirements-purview.md` — this guide adds the DSPM/DSPM-for-AI-specific prerequisites.

> **Availability caveat.** DSPM and DSPM for AI are newer, evolving capabilities whose blades,
> reports, and one-click policies change and are **licensing-/tenant-dependent**. Where this guide names
> a portal path or a policy, **confirm it exists in your tenant** rather than assuming — several
> requirements below are "verify in your tenant" by design.

## 2.1 DSPM / DSPM-for-AI licensing (verify in your tenant)
**Description:** The compliance licensing DSPM and DSPM for AI require — commonly **Microsoft 365 E5** or
the **E5 Compliance** add-on for the full posture, recommendations, and AI reporting; some AI-exposure
and site-access controls may additionally require **SharePoint Advanced Management** and/or a
**Microsoft 365 Copilot** license.
**Why:** Most DSPM signals derive from advanced Purview features (auto-labeling, advanced DLP, Insider
Risk) that are plan-gated; the AI reports depend on AI/Copilot being licensed and in use.
**Verify:** In the Microsoft 365 admin center confirm the subscriptions/add-ons; in the Purview portal
(`https://purview.microsoft.com`) confirm **Data Security Posture Management** and **DSPM for AI** are
visible and their reports render. Run `PURVDSPM-ScopeConfig.ps1` (read-only) to enumerate the labels,
DLP, and auto-labeling features that will feed posture.
**Implement:** Assign/purchase the required licensing before starting; if a capability is absent, note it
as out of scope and proceed with the licensed subset.

## 2.2 DSPM roles (least-privilege) and portal access
**Description:** Membership in the least-privilege Purview role group(s) that grant DSPM and DSPM-for-AI
access — typically an information-protection / DSPM-capable role group for reading posture, plus the
matching configuration role for changing labels, DLP, or auto-labeling. Confirm the **exact current
role-group names** in your portal.
**Why:** Purview uses fine-grained role groups; reading posture, working recommendations, and creating
policies each need the matching role, and separation of duties should be preserved.
**Verify:** Purview portal → **Settings / Roles & scopes → Role groups** — confirm your account's
membership; confirm you can open **Data Security Posture Management** and **DSPM for AI** without an
access error.
**Implement:** Assign the least-privilege role group under change control; reserve Global/Compliance
Administrator for the initial enablement only.

## 2.3 Purview auditing (unified audit log) turned on
**Description:** Purview **Audit** (the unified audit log) enabled tenant-wide, since DSPM-for-AI
prompt/response reporting and much of the activity signal is sourced from audit records.
**Why:** Without auditing on, AI-interaction and sensitive-activity reporting is empty or incomplete.
**Verify:** Purview portal → **Audit** shows searching is on; `PURVDSPM-ScopeConfig.ps1` reports whether
auditing is enabled. AI-interaction audit records should be present once Copilot/AI is used.
**Implement:** Turn on auditing (a one-time tenant action); allow time for records to accumulate before
expecting AI reports to populate.

## 2.4 A labels + DLP foundation to build posture on
**Description:** At least a **baseline of sensitivity labels and DLP** in place (or ready to create),
because DSPM posture and DSPM-for-AI reduction controls act *through* labels and DLP — DSPM measures and
recommends; labels/DLP are the levers.
**Why:** Recommendations such as "extend a label" or "protect sensitive data in Copilot" have no effect
without a label taxonomy and DLP to apply; oversharing reduction relies on them.
**Verify:** Purview portal → **Information Protection → Labels** and **Data Loss Prevention → Policies**
show your taxonomy and policies; `PURVDSPM-Discovery.ps1` inventories labels, label policies, DLP
policies, and auto-labeling policies.
**Implement:** Stand up a baseline label taxonomy and at least one DLP policy first (a dedicated
sensitivity/retention-labels or DLP solution covers this) so DSPM has levers to recommend.

## 2.5 Microsoft 365 Copilot / AI apps in scope (for DSPM for AI)
**Description:** Clarity on which AI is in scope — **Microsoft 365 Copilot**, Copilot experiences, and/or
other **enterprise AI apps** — and whether it is licensed and in use, so DSPM-for-AI reporting has data.
**Why:** DSPM for AI reports on the AI actually present; with no Copilot/AI usage there is nothing to
report yet, and the value is pre-adoption posture plus in-adoption monitoring.
**Verify:** Confirm Copilot/AI licensing and rollout status with the owning team; Purview portal →
**DSPM for AI** shows connected AI activity once present. `PURVDSPM-AIExposure.ps1` reports what AI
activity is visible.
**Implement:** Confirm the AI in scope with stakeholders; if Copilot is not yet deployed, use DSPM for AI
in its **pre-adoption** mode to reduce oversharing *before* turning Copilot on.

## 2.6 SharePoint/OneDrive access & sharing signal (for oversharing)
**Description:** The ability to read **site/file access and sharing** state — the "oversharing" that makes
content reachable by AI — and, for the strongest site-access controls, **SharePoint Advanced Management**
(verify licensing).
**Why:** Oversharing reduction targets broadly-shared and organization-wide-accessible content;
measuring and restricting it needs the sharing/access signal and the SharePoint controls.
**Verify:** `PURVDSPM-AIExposure.ps1` reports SharePoint/OneDrive sharing exposure from the signals
available to it; confirm whether SharePoint Advanced Management site-access reviews/restrictions are
available in your tenant.
**Implement:** Where the advanced site-access controls are unavailable, use the label + DLP-for-AI levers
plus manual site-owner sharing reviews as the reduction path.

## 2.7 Pilot scope and simulation/test discipline
**Description:** A named **pilot scope** (a ring of users/sites) and the intent to run every high-impact
reduction — auto-labeling, DLP for AI, sharing restriction — in **simulation/test/disabled** mode first
(as the category model requires, GR §6).
**Why:** Auto-labeling and DLP can misfire on real content; a broad sharing restriction can break
legitimate collaboration. Simulation/test surfaces the impact before anyone is affected.
**Verify:** Confirm the pilot ring, that auto-labeling **simulation mode** and DLP **test mode** are
available, and that a change window/approval exists.
**Implement:** Define the pilot and the change-control path before enforcing anything; the scripts default
to `-WhatIf` and create policies in simulation/test.
