# 2. Requirements Guide — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

Verify **every** requirement before configuring. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant compliance licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/privacy/legal stakeholders, and
pilot/change-control) are in `global-requirements-purview.md` — this guide adds the prerequisites specific
to AI prompt/response governance and monitoring.

> **Availability caveat.** AI-governance capabilities in Purview (Copilot monitoring in Communication
> Compliance, a DLP **Microsoft 365 Copilot** location, DSPM for AI, the `CopilotInteraction` audit
> record, risky-AI-usage insider-risk indicators) are **new, evolving, and licensing-/tenant-dependent**.
> Where this guide names a portal path, policy location, or record type, **confirm it exists in your
> tenant** — several requirements below are "verify in your tenant" by design.

## 2.1 AI-governance licensing (verify in your tenant)
**Description:** The compliance licensing these capabilities require — commonly **Microsoft 365 E5** or
the **E5 Compliance** add-on for **Communication Compliance**, **DLP for Copilot/AI**, and **DSPM for AI**;
plus a **Microsoft 365 Copilot** (or other AI-app) license for AI prompt/response activity to *exist* and
be monitorable.
**Why:** Communication Compliance, advanced DLP, and DSPM for AI are plan-gated; with no Copilot/AI in use
there is nothing to monitor yet.
**Verify:** In the Microsoft 365 admin center confirm the subscriptions/add-ons; in the Purview portal
confirm **Communication Compliance**, **Data Loss Prevention**, and **DSPM for AI** are visible. Run
`AIPROMPT-ScopeConfig.ps1` (read-only) to enumerate the AI-governance features your session can see.
**Implement:** Assign/purchase the required licensing before starting; if a capability is absent, note it
out of scope and proceed with the licensed subset (e.g. usage monitoring only, no DLP-for-AI location yet).

## 2.2 Least-privilege Purview roles with strict separation of duties
**Description:** Membership in the least-privilege role groups these capabilities need, kept **separate**:
**Communication Compliance Administrators** (configure policy), **Communication Compliance Analysts**
(triage on pseudonymized data), **Communication Compliance Investigators** (full detail, gated), plus the
**DLP / Information Protection** configuration role and an **Audit** reader role for monitoring. Confirm the
**exact current role-group names** in your portal.
**Why:** Purview uses fine-grained role groups; monitoring people's communications demands separation of
duties so no one both configures policy and investigates individuals.
**Verify:** Purview portal → **Settings / Roles & scopes → Role groups** — confirm each account's
membership matches its function; confirm you can open **Communication Compliance** and **DLP** without an
access error.
**Implement:** Assign the least-privilege role groups under change control; reserve Global/Compliance
Administrator for the initial enablement only. Document who holds Analyst vs Investigator rights.

## 2.3 Purview auditing (unified audit log) turned on
**Description:** Purview **Audit** (the unified audit log) enabled tenant-wide, because AI usage monitoring
— prompt/response activity and DSPM-for-AI reporting — is sourced from audit records (e.g. the
`CopilotInteraction` record type).
**Why:** Without auditing on, the AI usage/monitoring signal and DSPM-for-AI reports are empty or
incomplete.
**Verify:** Purview portal → **Audit** shows searching is on; `AIPROMPT-ScopeConfig.ps1` reports whether
`UnifiedAuditLogIngestionEnabled` is true. `CopilotInteraction` records should appear once Copilot/AI is
used.
**Implement:** Turn on auditing (a one-time tenant action); allow time for records to accumulate before
expecting monitoring to populate.

## 2.4 Communication Compliance readiness (Copilot as a monitored source; privacy-by-design)
**Description:** **Communication Compliance** available and **enabled/onboarded**, with **anonymization
(pseudonymization)** configured, trained reviewers assigned, and — **verify in your tenant** — the ability
to include **Microsoft 365 Copilot / AI interactions** as a monitored source in a policy.
**Why:** The governance layer for *risky/sensitive content inside prompts and responses* is a Communication
Compliance policy; anonymization and reviewer training are prerequisites for running it lawfully and fairly.
**Verify:** Purview portal → **Communication Compliance** loads; **Settings → Privacy** anonymization is
available; confirm whether a policy can target Copilot/AI interactions (the template/source name evolves).
`AIPROMPT-Discovery.ps1` inventories existing Communication Compliance policies via
`Get-SupervisoryReviewPolicyV2`.
**Implement:** Onboard Communication Compliance, enable anonymization, assign Analysts/Investigators, and
confirm the Copilot/AI monitored source is present before creating the AI policy — otherwise scope to the
DLP-for-AI + monitoring path.

## 2.5 DLP with a Microsoft 365 Copilot / AI location (verify in your tenant)
**Description:** **Data Loss Prevention** available, and — **verify** — a **Microsoft 365 Copilot** (or
AI) **location** exposed by DLP so a policy can govern how sensitivity-labeled content is processed by
Copilot/AI. Requires a baseline of **sensitivity labels** and/or **sensitive information types** as the
levers the policy matches on.
**Why:** DLP for Copilot/AI is the preventive lever — it keeps the most sensitive (labeled) content out of
AI processing. It has no effect without labels/SITs to match and the Copilot location to scope to.
**Verify:** Purview portal → **Data Loss Prevention → Policies → Create** and confirm whether a **Copilot /
AI** location is offered; **Information Protection → Labels** shows your taxonomy. `AIPROMPT-Discovery.ps1`
inventories DLP policies, labels, and sensitive information types.
**Implement:** Stand up a baseline label taxonomy (a dedicated sensitivity-labels solution covers this) and
confirm the Copilot/AI DLP location; if the location is absent for your plan, use the portal's DSPM-for-AI
one-click "protect sensitive data from Copilot" policy where present, or scope to monitoring + Communication
Compliance only.

## 2.6 DSPM for AI as the monitoring surface (verify in your tenant)
**Description:** **DSPM for AI** visible and enabled, providing the **AI interaction reports** (sensitive
interactions per AI app, data-access) that complement the scripted audit signal for usage monitoring.
**Why:** DSPM for AI is the portal-native view of which prompts/responses touch sensitive data and which AI
apps are in use — the monitoring dashboard this solution reads and evidences.
**Verify:** Purview portal → **DSPM for AI → Reports** render; `AIPROMPT-Monitor.ps1` reports the scriptable
audit signal that mirrors it.
**Implement:** Complete the one-time DSPM-for-AI get-started/enablement (may enable AI-interaction audit
collection — confirm it aligns with Requirement 2.3); if absent, rely on the scripted audit monitoring.

## 2.7 In-scope AI apps and population
**Description:** Clarity on **which AI is in scope** (Microsoft 365 Copilot, Copilot experiences, and/or
other enterprise AI apps) and **which population** (users/groups) the governance and monitoring cover.
**Why:** Policies and reports key off the AI apps present and the in-scope users; monitoring the wrong scope
either misses activity or over-collects.
**Verify:** Confirm Copilot/AI rollout and the target population with the owning team and stakeholders;
`AIPROMPT-Monitor.ps1` shows which AI activity is visible.
**Implement:** Define the in-scope AI apps and population with stakeholders before authoring policies; if
Copilot is not yet deployed, use the pre-adoption window to stage monitoring and policy so governance is
live on day one.

## 2.8 Pilot ring and test/simulation discipline
**Description:** A named **pilot ring** (`AI Governance – Pilot – Ring1`) and the intent to run every
high-impact policy — Communication Compliance and DLP for AI — in a **limited scope / test / simulation**
mode first (as the category model requires, GR §6), reviewed with HR/privacy/legal before any expansion.
**Why:** A Communication Compliance policy applied broadly can over-collect on real people; a DLP-for-AI
policy in enforce can block legitimate AI use. Piloting in a limited/test scope surfaces impact and
false-positives before anyone is affected.
**Verify:** Confirm the pilot ring, that DLP **test mode** and a limited Communication-Compliance scope are
available, and that a change window/approval (including HR/privacy sign-off) exists.
**Implement:** Define the pilot ring and change-control path before enforcing anything; the scripts default
to `-WhatIf` and create the DLP-for-AI policy in **test** mode.
