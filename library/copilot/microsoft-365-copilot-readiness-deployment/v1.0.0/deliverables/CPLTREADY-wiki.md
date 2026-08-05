# Microsoft 365 Copilot Readiness Assessment & Deployment

> **Version 1.0.0** · Category: Copilot · Solution code: CPLTREADY

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft 365 Copilot Readiness Assessment & Deployment

**Copilot**

Microsoft 365 Copilot creates no new access, but it surfaces everything a user can already reach. So the moment you turn it on, every oversharing problem, every broad "anyone with the link" file, and every stale permission your tenant already has becomes an AI data-exposure problem — served up in a chat answer. This solution does it in the right order: assess technical and data readiness, fix the blockers, license and enable Copilot for a measured pilot cohort, prove value with real metrics, then roll out in waves — so leadership sees results before a broad enablement, and the SOC never gets a permissions incident on day one.

This is a complete, deploy-it-safely package for rolling out Microsoft 365 Copilot, written for an administrator with no prior Copilot deployment experience.

## What you get

- A plain-language Solution Overview of what Copilot needs to be safe and useful — licensing, Entra identity, network/client readiness, and (most importantly) data hygiene.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite.
- An Implementation Guide of precise, click-by-click steps: run the readiness assessment, remediate blockers, assign licenses, enable the pilot cohort, and stand up the value dashboard and rollout waves.
- Five PowerShell scripts (Microsoft Graph) for readiness discovery, an oversharing/data-hygiene scan, prerequisite validation, license assignment, and a readiness-and-adoption report.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A safe, measured Copilot rollout: a readiness scorecard for the tenant, the blockers remediated (identity, oversharing, unsupported configs), Copilot licenses assigned to a named pilot cohort, Copilot enabled and adopted by that cohort, a value dashboard showing usage and impact, and a staged wave plan for the rest of the organization — proven on the pilot before you scale.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that requires the blockers fixed and value demonstrated before broad enablement.

## Boundaries

Two determinations stay with the customer. **Acceptable-AI-use and data-governance policy** — what Copilot may be used for, and how AI-generated and AI-surfaced content is handled — is a compliance/legal decision; this guide delivers the technical controls, not the policy. And **Copilot licensing and preview facts change** — base-plan prerequisites, licensing, and any preview features are flagged "verify current availability in your tenant" throughout, not asserted.

## Outcome

Microsoft 365 Copilot rolled out the safe way — assessed, de-risked, licensed, piloted, measured, and expanded in waves — so the organization gets the productivity without turning existing oversharing into AI exposure.


---


# 1. Solution Overview — Microsoft 365 Copilot Readiness Assessment & Deployment

## What this solution is

Microsoft 365 Copilot is an AI assistant embedded in Word, Excel, PowerPoint, Outlook, Teams, and Microsoft 365 Chat. It reasons over your organization's content through Microsoft Graph — documents, emails, chats, meetings — respecting each user's existing permissions. That last point is the whole game: Copilot grants no new access, but it makes everything a user *can* already reach instantly discoverable in a chat answer. This solution is the disciplined path to turning it on: assess readiness, remediate the blockers (above all, data oversharing), license and enable a pilot cohort, measure value, and expand in waves.

## How Copilot works (and why readiness matters)

1. A licensed user asks Copilot something in a Microsoft 365 app.
2. Copilot uses Microsoft Graph to retrieve relevant content the user already has permission to see, grounds its answer in that content, and returns a response with citations.
3. Because retrieval is bounded by the user's existing permissions, **the quality and safety of the answer depend on the state of your tenant**: broad "anyone with the link" sharing, over-permissioned sites, and unlabeled sensitive content all become AI-surfaced exposure.
4. Conditional Access, sensitivity labels, and Purview audit still apply — so a healthy identity and information-protection baseline is what keeps Copilot both useful and governed.

This is why the order is assess → remediate → pilot, not license-and-hope.

## The five readiness dimensions this solution assesses

- **Licensing** — Microsoft 365 Copilot is a per-user add-on on a qualifying base plan. *Verify current base-plan prerequisites and licensing in your tenant.*
- **Entra identity** — cloud identities with MFA and healthy sign-in; Copilot honors Conditional Access.
- **Network & client** — supported Microsoft 365 Apps builds/channel and reachable Copilot endpoints.
- **Data hygiene (the big one)** — the state of SharePoint/OneDrive permissions and sharing; unmanaged broad access becomes AI data exposure.
- **Information protection** — a published sensitivity-label baseline so sensitive content can be kept out of AI processing where required and audited.

## The objects this solution creates (named to convention)

Every created object is named `<Purpose> - <Scope> - <Stage>` and reused verbatim throughout the guide, testing, and scripts:

- Pilot cohort group (Entra): `Copilot Enablement - Pilot Cohort - Pilot`
- License-assignment group (Entra, group-based licensing): `Copilot License - Pilot Cohort - Pilot`
- Rollout wave groups: `Copilot Enablement - Wave 1 - Production`, `... - Wave 2 - Production`, etc.
- Readiness scorecard artifact: `Copilot Readiness - Tenant - Assess`

## What you can control

- The scope and size of the pilot cohort and the wave plan.
- Which blockers are remediated before enablement (identity gaps, oversharing, unsupported configs).
- How licenses are assigned (group-based licensing to the named groups).
- The success metrics on the value dashboard (adoption, active use, self-reported/measured impact).
- The information-protection guardrails (labels, DLP) that bound what Copilot processes — *the acceptable-use policy behind them is the customer's decision.*

## Why this matters (the business case)

- **Safe** — fixing oversharing and identity gaps *before* enablement prevents Copilot from surfacing content that should never have been broadly reachable.
- **Measured** — a pilot with real metrics gives leadership evidence of value before a large licensing spend scales out.
- **Governed** — a label and audit baseline means Copilot use is auditable and sensitive content is controllable.
- **Repeatable** — a named wave plan turns a risky big-bang into a series of low-risk, familiar rollouts.

## Limitations (be honest with buyers)

- Copilot licensing, base-plan prerequisites, and preview features change; this guide flags them "verify current availability in your tenant" rather than asserting fixed facts.
- Data-hygiene remediation depth (for example SharePoint Advanced Management / Restricted Content Discovery) depends on licensing that varies — *verify in your tenant*; deep oversharing remediation may be a separate engagement.
- Acceptable-AI-use and data-governance *policy* is a customer compliance/legal decision; this solution provides the technical controls only.
- This solution readies and deploys Copilot; it is not an end-user training curriculum (though it includes pilot enablement guidance).

## The standard deployment model

> Assess the five readiness dimensions and produce a scorecard, remediate the blockers, assign licenses and enable a named pilot cohort, validate value on the pilot against success metrics, then expand in waves with a value dashboard. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.


---


# 2. Requirements Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (supported M365 workloads, Copilot licensing baseline, Entra identity & MFA, data-readiness/oversharing controls, information-protection baseline, admin roles, network/client readiness, governance policy) are in `global-requirements-copilot.md`; do not repeat them — confirm them there first. This solution layers the deployment-specific readiness on top.

## 2.1 A readiness baseline captured (the scorecard)

- **Description:** A recorded starting-state assessment across the five dimensions — licensing, Entra identity, network/client, data hygiene, information protection — saved as `Copilot Readiness - Tenant - Assess`.
- **Why:** You cannot remediate blockers you have not measured, and the pilot gate compares against this baseline.
- **Verify:** Run `CPLTREADY-Discovery.ps1` and `CPLTREADY-OversharingScan.ps1`; confirm a scorecard exists.
- **Implement:** Run the discovery scripts, record the results as the baseline scorecard, and rank the blockers.

## 2.2 Copilot licenses available to assign

- **Description:** A pool of Microsoft 365 Copilot licenses sufficient for the pilot cohort, on a qualifying base plan. *Verify current base-plan prerequisites and licensing in your tenant.*
- **Why:** Copilot is a per-user add-on; a user cannot use Copilot without an assigned license on a qualifying base plan.
- **Verify:** `admin.microsoft.com` → `Billing` → `Licenses`; confirm free Copilot seats. Run `CPLTREADY-Discovery.ps1` (reports available seats).
- **Implement:** Acquire the required Copilot seats and confirm the pilot users hold a qualifying base plan. *Confirm the current prerequisite plan with Microsoft.*

## 2.3 Group-based licensing groups created

- **Description:** Two Entra groups: `Copilot License - Pilot Cohort - Pilot` (for group-based license assignment) and `Copilot Enablement - Pilot Cohort - Pilot` (the cohort roster).
- **Why:** Assigning licenses to a group (not user-by-user) makes the pilot and later waves repeatable and reversible.
- **Verify:** `entra.microsoft.com` → `Groups` → both groups exist. Run `CPLTREADY-Validate.ps1`.
- **Implement:** Create the groups; add the pilot users; use group-based licensing for the Copilot SKU.

## 2.4 Data-hygiene blockers identified

- **Description:** A list of the highest-risk oversharing conditions in scope for the pilot users' content — broad "Everyone/Everyone except external"/anonymous-link access on sites and files the cohort can reach.
- **Why:** Copilot surfaces anything the user can access; broad access is the primary AI-exposure risk and must be remediated before enablement.
- **Verify:** Run `CPLTREADY-OversharingScan.ps1`; review SharePoint sharing reports. *SharePoint Advanced Management / Restricted Content Discovery availability varies — verify in your tenant.*
- **Implement:** Remediate broad-access sites/links for the pilot scope before enabling (deep, tenant-wide remediation may be a separate oversharing engagement — see "where to go next").

## 2.5 A sensitivity-label baseline published

- **Description:** At least a minimal published sensitivity-label set in Microsoft Purview.
- **Why:** Labels are how sensitive content is kept out of AI processing where required and how Copilot use is audited.
- **Verify:** Purview portal → `Information Protection` → `Labels` shows published labels. Run `CPLTREADY-Validate.ps1`.
- **Implement:** Publish a baseline label taxonomy (see the Purview information-protection solutions) before broad enablement.

## 2.6 Client and network readiness for the cohort

- **Description:** The pilot users on a supported Microsoft 365 Apps channel/build with reachable Copilot endpoints. *Verify current client requirements.*
- **Why:** Copilot experiences in the apps require current clients and connectivity.
- **Verify:** Confirm the cohort's Apps update channel/build; run `CPLTREADY-Validate.ps1` for client/endpoint checks.
- **Implement:** Move the cohort to a supported channel/build and allow the required Microsoft 365/Copilot endpoints.

## 2.7 A pilot success-metrics definition

- **Description:** The agreed success criteria for the pilot — for example activation %, weekly active use, and a value signal (measured time saved or a self-reported impact survey).
- **Why:** The pilot gate requires demonstrated value before waves; the value dashboard reports against these metrics.
- **Verify:** The metrics and pass thresholds are written down. Run `CPLTREADY-Report.ps1` during the pilot.
- **Implement:** Define the metrics with the business sponsor before enabling the cohort.

## 2.8 An acceptable-AI-use position acknowledged

- **Description:** Acknowledgement that an acceptable-AI-use / data-handling policy will be adopted by the customer's compliance/legal function.
- **Why:** Copilot generates and surfaces content; the organization must define acceptable use and keep it auditable.
- **Verify:** A documented AI-use policy exists or is committed; Purview audit for Copilot is enabled.
- **Implement:** Adopt the policy (customer decision) and enable audit/eDiscovery for Copilot. *This is the customer's compliance/legal determination — this guide covers the technical controls only.*

---

## Checklist

- [ ] Supported M365 workloads, Copilot licensing baseline, Entra/MFA, admin roles, info-protection baseline, network/client, governance — see global requirements
- [ ] Readiness baseline scorecard captured — `CPLTREADY-Discovery.ps1`, `CPLTREADY-OversharingScan.ps1`
- [ ] Copilot seats available on a qualifying base plan — *verify*
- [ ] Group-based licensing groups created — `CPLTREADY-Validate.ps1`
- [ ] Data-hygiene blockers identified for the pilot scope
- [ ] Sensitivity-label baseline published
- [ ] Cohort client/network readiness confirmed
- [ ] Pilot success metrics and thresholds defined
- [ ] Acceptable-AI-use position acknowledged (customer)


---


# Global Requirements — Copilot (category-level)

These requirements apply to every solution in the Copilot category. They are published once at the
category level so individual listings stay small. Confirm these before deploying any Microsoft 365
Copilot solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Copilot inherits the tenant's existing identity, permission, and data-governance posture. It creates
> no new access — but it surfaces everything a user already has. Treat data readiness (oversharing,
> labeling) as a prerequisite, not an afterthought, and pilot before broad enablement.

## G1. Microsoft 365 tenant with supported workloads
Description: A Microsoft 365 tenant with Exchange Online, SharePoint Online, OneDrive, and Teams in use.
Why: Copilot reasons over Microsoft Graph content across these workloads; they must be provisioned and healthy.
Verify: Microsoft 365 admin center shows the services active; users have mailboxes and OneDrive provisioned.
Implement: Provision/enable the M365 workloads and confirm users are licensed for them before adding Copilot.

## G2. Microsoft 365 Copilot licensing
Description: Microsoft 365 Copilot licenses for the target users (a prerequisite base M365 plan applies).
Why: Copilot is a per-user add-on; a user cannot use Copilot without an assigned license on a qualifying base plan.
Verify: Admin center -> `Billing -> Licenses`; confirm Copilot licenses and free seats. *Verify current base-plan prerequisites in your tenant.*
Implement: Purchase/assign Microsoft 365 Copilot licenses to the pilot cohort; assign via group where possible.

## G3. Microsoft Entra ID identity and MFA
Description: Cloud identities in Entra ID with MFA and healthy sign-in.
Why: Copilot honors identity and Conditional Access; a weak or broken identity plane undermines both access and security.
Verify: Users sign in at `https://entra.microsoft.com` resources; MFA is enforced for the cohort.
Implement: Ensure licensed, MFA-protected Entra accounts (see the Entra category solutions for identity hardening).

## G4. Data readiness — permissions & oversharing controls
Description: A known state of SharePoint/OneDrive permissions and sharing (no unmanaged broad access).
Why: Copilot can surface any content the user has access to; oversharing becomes AI data exposure.
Verify: Review sharing reports / SharePoint Advanced Management signals; run the solution's discovery script. *SAM/Restricted Content Discovery availability varies — verify in your tenant.*
Implement: Remediate broad-access sites and links before broad Copilot enablement (see the oversharing-remediation solution).

## G5. Information protection baseline (sensitivity labels)
Description: A published sensitivity-label taxonomy (even minimal) in Microsoft Purview.
Why: Labels are how you keep sensitive content out of AI processing where required and audit what Copilot uses.
Verify: Purview compliance portal -> Information Protection shows published labels.
Implement: Publish a baseline label set (see the Purview information-protection solutions) before enforcing AI guardrails.

## G6. Administrative roles
Description: Global Administrator (or scoped admin roles: SharePoint Admin, Security/Compliance Admin) for the operator.
Why: Enabling Copilot, remediating SharePoint, and configuring Purview DLP/labels require these roles.
Verify: Entra -> `Roles and administrators`; confirm the required roles.
Implement: Assign least-privilege roles for the task; reserve Global Administrator for tenant-wide changes.

## G7. Network and client readiness
Description: Supported Microsoft 365 Apps clients and network access to Microsoft 365/Copilot endpoints.
Why: Copilot experiences in Word/Excel/Outlook/Teams require current clients and connectivity.
Verify: Clients on a supported channel/build; Microsoft 365 endpoints reachable. *Verify current client requirements.*
Implement: Update the M365 Apps channel/build and allow the required endpoints.

## G8. Governance & responsible-use policy
Description: An organizational position on acceptable AI use, data handling, and auditability.
Why: Copilot generates and surfaces content; the organization must define what is acceptable and keep an audit trail.
Verify: A documented AI-use/acceptable-use policy exists; Copilot interactions are auditable (Purview audit).
Implement: Adopt an AI-use policy; enable audit/eDiscovery for Copilot. *Governance and acceptable-use determinations are the customer's compliance/legal decision — this guide covers the technical controls only.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Follow these steps **in order**. They use several portals: the Microsoft 365 admin center (`https://admin.microsoft.com`) for licensing and usage reports, the Entra admin center (`https://entra.microsoft.com`) for groups and licensing, the SharePoint admin center (via the M365 admin center) and Microsoft Purview (`https://purview.microsoft.com`) for data hygiene and labels, and Viva Insights for the Copilot value dashboard.

> Model: assess readiness and score it, remediate the blockers, license and enable a named pilot cohort, validate value on the pilot, then expand in waves. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Readiness scorecard: `Copilot Readiness - Tenant - Assess`
- Cohort roster group (Entra): `Copilot Enablement - Pilot Cohort - Pilot`
- License-assignment group (Entra): `Copilot License - Pilot Cohort - Pilot`
- Rollout wave groups: `Copilot Enablement - Wave 1 - Production`, `... - Wave 2 - Production`

## Step 1 — Assess readiness and build the scorecard

1. Run `CPLTREADY-Discovery.ps1` → captures licensing (available Copilot seats), Entra identity/MFA posture, and workload provisioning for the tenant.
2. Run `CPLTREADY-OversharingScan.ps1` → captures the data-hygiene signal: broadly shared sites/links reachable in scope.
3. Record both outputs as the baseline `Copilot Readiness - Tenant - Assess`, and rank the blockers (identity → oversharing → unsupported configs). This scorecard is what the pilot gate compares against.

## Step 2 — Remediate the blockers (before any enablement)

1. **Identity:** ensure the pilot users are cloud identities with MFA enforced and healthy sign-in (see the Entra category solutions for hardening). Confirm Conditional Access does not inadvertently block the Copilot experiences.
2. **Data hygiene:** for the pilot scope, remediate the broad-access sites and links found in Step 1 — remove "Everyone/Everyone except external"/anonymous links on sensitive content. *Deep, tenant-wide oversharing remediation may need SharePoint Advanced Management (verify availability) or a dedicated engagement.*
3. **Information protection:** confirm a published sensitivity-label baseline exists in Purview (Requirement 2.5); publish one if not.
4. **Client/network:** move the cohort to a supported Microsoft 365 Apps channel/build and confirm endpoints are reachable (Requirement 2.6). *Verify current client requirements.*
5. Re-run the Step 1 scripts and confirm the ranked blockers are cleared for the pilot scope.

## Step 3 — Create the cohort and licensing groups

1. `entra.microsoft.com` → `Groups` → `New group` → create `Copilot Enablement - Pilot Cohort - Pilot` (the roster) and add the pilot users.
2. Create `Copilot License - Pilot Cohort - Pilot` for group-based licensing (you can nest or mirror the roster).
3. Keep the groups small and representative (a cross-section of roles) so pilot results generalize.

## Step 4 — Assign Copilot licenses to the pilot cohort

1. `entra.microsoft.com` → `Groups` → `Copilot License - Pilot Cohort - Pilot` → `Licenses` → `Assignments` → add the **Microsoft 365 Copilot** license → confirm the required base-plan services are enabled → `Save`. *Verify the current Copilot SKU/base-plan prerequisite in your tenant.*
2. Alternatively run `CPLTREADY-AssignLicenses.ps1` (default `-WhatIf` preview) to assign the Copilot SKU to the cohort group members via Microsoft Graph, then re-run with `-WhatIf:$false` to apply.
3. Confirm in `admin.microsoft.com` → `Billing` → `Licenses` that seats are consumed by the cohort.

## Step 5 — Enable and onboard the pilot cohort

1. Confirm Copilot is available to the licensed cohort in the Microsoft 365 apps (Word/Excel/Outlook/Teams) and Microsoft 365 Chat. Licensing is what enables the experience; there is no separate per-user "on" switch beyond the license and supported client.
2. Send the cohort a short enablement note: where Copilot appears, three or four starter prompts for their role, and how to give feedback.
3. Confirm audit for Copilot is on in Purview (Requirement 2.8) so interactions are auditable.

## Step 6 — Stand up the value dashboard

1. Open the **Microsoft Copilot Dashboard** in Viva Insights (in Teams or `https://viva.microsoft.com`) for adoption and impact signals. *Verify current availability and any Viva prerequisite in your tenant.*
2. In `admin.microsoft.com` → `Reports` → `Usage` → `Microsoft 365 Copilot`, review activation and active-usage figures for the cohort.
3. Run `CPLTREADY-Report.ps1` to compile a readiness-and-adoption snapshot against the Step 1 scorecard and the Requirement 2.7 success metrics.

## Step 7 — Validate the pilot (the gate)

1. Run `CPLTREADY-Validate.ps1` → confirms the cohort is licensed, the groups are correct, labels are published, and no ranked blocker is outstanding for the scope.
2. Run `CPLTREADY-Report.ps1` → confirms adoption/active-use against the success metrics (Requirement 2.7).
3. Pilot gate: do not begin waves until (a) the ranked blockers are cleared, (b) the cohort is actively using Copilot, and (c) the value signal meets the agreed threshold.

## Step 8 — Expand in waves

1. Create `Copilot Enablement - Wave 1 - Production` (and later waves), each a manageable population; remediate that wave's data-hygiene blockers *before* licensing it — the same order as the pilot.
2. Assign licenses to each wave's group (Step 4 pattern), enable, and add the wave to the value dashboard.
3. Advance to the next wave only when the current wave's blockers are cleared and adoption is tracking.
4. Re-run `CPLTREADY-OversharingScan.ps1` and `CPLTREADY-Report.ps1` each wave so new oversharing is caught before it becomes AI exposure and value stays visible to leadership.

---

### Order of operations

`Assess & score -> remediate blockers (identity, oversharing, labels, clients) -> cohort & licensing groups -> assign licenses -> enable & onboard cohort -> value dashboard -> validate pilot (gate) -> expand in waves (remediate-then-license each wave)`


---


# 5. Testing Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Run after the pilot is configured (Implementation Step 7) and before advancing each wave. Scripts referenced: `CPLTREADY-Discovery.ps1`, `CPLTREADY-OversharingScan.ps1`, `CPLTREADY-Validate.ps1`, `CPLTREADY-AssignLicenses.ps1`, `CPLTREADY-Report.ps1`.

## Test 1 — Readiness scorecard exists and blockers ranked

**Do:** Confirm `Copilot Readiness - Tenant - Assess` was captured; re-run `CPLTREADY-Discovery.ps1`.
**Expected:** A baseline scorecard across licensing, identity, data hygiene, and info-protection, with blockers ranked.

## Test 2 — Blockers remediated for the pilot scope

**Do:** Re-run `CPLTREADY-OversharingScan.ps1` and `CPLTREADY-Validate.ps1`.
**Expected:** The ranked broad-access findings for the cohort scope are cleared; identity/MFA and label baseline pass.

## Test 3 — Groups correct

**Do:** `entra.microsoft.com` → `Groups`; or `CPLTREADY-Validate.ps1`.
**Expected:** `Copilot Enablement - Pilot Cohort - Pilot` and `Copilot License - Pilot Cohort - Pilot` exist with the pilot users as members.

## Test 4 — Licenses assigned

**Do:** `admin.microsoft.com` → `Billing` → `Licenses`; or `CPLTREADY-Validate.ps1`.
**Expected:** Each cohort member holds an active Microsoft 365 Copilot license on a qualifying base plan; seat count matches the roster.

## Test 5 — Copilot works for a cohort user

**Do:** As a licensed cohort user on a supported client, open Word or Microsoft 365 Chat and run a starter prompt.
**Expected:** Copilot responds and cites tenant content the user is permitted to see — and does **not** surface content the user should not have (a spot-check that remediation held).

## Test 6 — Audit captures Copilot interactions

**Do:** Purview → `Audit` → search for Copilot activity for a cohort user.
**Expected:** Copilot interactions are recorded and searchable (Requirement 2.8).

## Test 7 — Value dashboard and adoption

**Do:** Open the Microsoft Copilot Dashboard (Viva Insights) and `admin.microsoft.com` → `Reports` → `Usage` → `Microsoft 365 Copilot`; run `CPLTREADY-Report.ps1`.
**Expected:** Activation and active-usage figures for the cohort are visible and tracking toward the Requirement 2.7 thresholds.

## Test 8 — Wave remediate-then-license order (per wave)

**Do:** For a new wave group, confirm the oversharing scan and blocker remediation were completed **before** licenses were assigned.
**Expected:** No wave is licensed ahead of its data-hygiene remediation.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass: blockers cleared for the cohort, groups correct, licenses assigned, Copilot works and is audited, and adoption/value meets the agreed threshold |
| Wave pass | Tests 2, 4, 7, 8 pass for the wave — blockers remediated before licensing, licenses assigned, and adoption tracking — before advancing to the next wave |


---


# 6. Troubleshooting Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Use `CPLTREADY-Discovery.ps1` for readiness, `CPLTREADY-OversharingScan.ps1` for data hygiene, `CPLTREADY-Validate.ps1` for pre-enablement checks, `CPLTREADY-AssignLicenses.ps1` (default `-WhatIf`) for license assignment, and `CPLTREADY-Report.ps1` for adoption/value.

## A. Copilot doesn't appear for a licensed user

| Symptom | Cause | Remediation |
|---|---|---|
| No Copilot in the apps despite a license | Unsupported Microsoft 365 Apps channel/build, or client not updated | Move the user to a supported channel/build (Requirement 2.6); *verify current client requirements*; restart the apps |
| License shows assigned but experience missing | Base-plan service disabled, or licensing not yet propagated | Confirm the qualifying base-plan services are enabled on the license; allow propagation; re-run `CPLTREADY-Validate.ps1` |
| Blocked by Conditional Access | A CA policy blocks the Copilot/Graph experience | Review CA for the cohort; adjust in report-only first, then enforce |

## B. Copilot surfaces content it shouldn't

| Symptom | Cause | Remediation |
|---|---|---|
| An answer cites broadly-shared sensitive content | Oversharing not remediated for the scope before enablement | This is the core risk — run `CPLTREADY-OversharingScan.ps1`, remediate the broad-access site/link, and re-verify (Implementation Step 2) |
| Sensitive content not excluded | No sensitivity-label baseline / content unlabeled | Publish and apply labels (Requirement 2.5); *deep exclusion may need SharePoint Advanced Management — verify availability* |

## C. License assignment fails

| Symptom | Cause | Remediation |
|---|---|---|
| `CPLTREADY-AssignLicenses.ps1` errors on assign | No free Copilot seats, or missing base-plan prerequisite | Confirm free seats (`admin.microsoft.com` → `Billing` → `Licenses`); ensure the user holds a qualifying base plan *(verify current prerequisite)* |
| Group-based licensing shows an error state | Conflicting/duplicate service plan, or usage-location unset | Set the user's usage location; resolve the service-plan conflict in the group licensing assignment |

## D. Readiness scan gaps

| Symptom | Cause | Remediation |
|---|---|---|
| Oversharing scan returns little/nothing | Insufficient Graph permissions, or SAM features unavailable | Grant the read scopes the script requests; *Restricted Content Discovery / SAM availability varies — verify in your tenant* and supplement with SharePoint sharing reports |
| Discovery can't read licensing/MFA | Missing admin role or Graph scope | Assign the least-privilege admin role (global requirement G6) and consent to the read scopes |

## E. Adoption/value not showing

| Symptom | Cause | Remediation |
|---|---|---|
| Copilot Dashboard empty | Viva Insights prerequisite/availability, or too little usage yet | *Verify Copilot Dashboard availability/prerequisite in your tenant*; allow usage to accumulate; use `admin.microsoft.com` → `Reports` → `Usage` → `Microsoft 365 Copilot` as well |
| Usage report lags | Reporting latency | Allow the reporting window; re-run `CPLTREADY-Report.ps1` |

## F. Permission / role errors

- Cannot manage licenses/groups → assign the required admin role (global requirement G6); reserve Global Administrator for tenant-wide changes.
- Scripts fail to connect Graph → run `Connect-MgGraph` with the scopes each script's header lists and consent as an admin.

## G. When to escalate

If licensing is confirmed, the client is supported, blockers are remediated, and Copilot still fails to appear or surfaces content that should have been remediated, capture `CPLTREADY-Validate.ps1` and `CPLTREADY-OversharingScan.ps1` output and open a Microsoft support case (Copilot enablement / SharePoint sharing) — and *re-verify any licensing/preview fact with Microsoft* before assuming it is a defect.


---


# 7. Best Practices — Microsoft 365 Copilot Readiness Assessment & Deployment

- **Fix data hygiene before you license anyone.** Copilot surfaces everything a user can already reach; remediating oversharing *before* enablement is the single most important control — do it for every wave, not just the pilot.
- **Assess, then remediate, then enable — in that order.** A scored baseline (`Copilot Readiness - Tenant - Assess`) tells you what to fix and lets the pilot gate prove you fixed it; skipping the assessment is how oversharing reaches AI answers.
- **Pilot with a representative cross-section.** A small cohort spanning several roles gives value evidence that generalizes to the waves; a pilot of only power users overstates adoption.
- **Use group-based licensing.** Assign the Copilot SKU to `Copilot License - Pilot Cohort - Pilot` and the wave groups, not user-by-user — it makes enablement and roll-back repeatable.
- **Measure value from day one.** Stand up the value dashboard before the pilot ends so leadership sees activation, active use, and impact against agreed thresholds — evidence before the big licensing spend.
- **Remediate-then-license every wave.** Repeat the pilot's order for each wave: scan for oversharing, remediate, then license — new broad-access content appears over time.
- **Keep sensitive content labeled and audited.** A published sensitivity-label baseline plus Purview audit keeps sensitive material controllable and Copilot use accountable.
- **Name every object to the convention.** Use `<Purpose> - <Scope> - <Stage>` for the cohort, licensing, and wave groups and the scorecard, and reuse the names verbatim — it makes the rollout auditable and repeatable.
- **Verify licensing and preview facts, don't assume them.** Base-plan prerequisites, the Copilot SKU, and any preview features change; confirm current availability in your tenant before committing.
- **Leave the AI-use policy to the customer.** The deployment provides the technical controls (labels, DLP, audit); what Copilot may be used for and how AI content is handled is the customer's compliance/legal decision.

## Where to go next

- **Oversharing / data-security remediation** — a dedicated engagement for deep, tenant-wide SharePoint/OneDrive permission remediation (SharePoint Advanced Management / Restricted Content Discovery — *verify availability*).
- **Purview information protection & DLP** — extend the label baseline and add DLP to bound what Copilot processes.
- **Entra identity hardening** — Conditional Access and MFA hardening so the identity plane Copilot honors is strong.
- **Copilot agents & extensibility** — once adoption is proven, extend Copilot with agents and connectors (governed the same assess-then-enable way).


---


# 8. Deliverables Summary — Microsoft 365 Copilot Readiness Assessment & Deployment

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How Copilot works, the five readiness dimensions, the objects created, benefits, limitations |
| 2. Requirements Guide | Every solution-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Copilot) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (assess & score, remediate blockers, cohort & licensing groups, assign licenses, enable, value dashboard, waves) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph)

| Script | What it does |
|---|---|
| `CPLTREADY-Discovery.ps1` | Readiness discovery — available Copilot seats, cohort licensing, MFA/identity posture, and workload signals for the scorecard (read-only) |
| `CPLTREADY-OversharingScan.ps1` | Data-hygiene scan — reports broadly shared sites/links (Everyone / anonymous) reachable in scope, the primary AI-exposure risk (read-only) |
| `CPLTREADY-Validate.ps1` | Confirms readiness before enablement: groups exist, licenses assigned, labels published, blockers cleared (read-only) |
| `CPLTREADY-AssignLicenses.ps1` | Assigns the Microsoft 365 Copilot SKU to the cohort/wave group members (default preview / `-WhatIf`; applies only with `-WhatIf:$false`) |
| `CPLTREADY-Report.ps1` | Readiness-and-adoption report — blocker status against the scorecard plus activation/active-use against the pilot success metrics (read-only) |

## What the buyer receives

- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome

Microsoft 365 Copilot rolled out safely — assessed and scored, blockers remediated, licensed to a named pilot cohort, enabled and audited, value measured on a dashboard, and expanded in waves that remediate-then-license — so the organization gets the productivity without turning existing oversharing into AI exposure.
