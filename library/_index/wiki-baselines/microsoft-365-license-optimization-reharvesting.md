# Microsoft 365 License Optimization & Reharvesting

> **Version 1.0.0** · Category: Asset Mgt · Solution code: M365LIC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft 365 License Optimization & Reharvesting

Microsoft 365 license spend grows quietly and rarely shrinks. Leavers keep their seats for months,
users sit on E5 when E3 would do, duplicate or overlapping plans pile up, and nobody has a clear view
of which licenses are actually used. The bill arrives every month regardless. This solution gives you
a repeatable way to measure real usage from the Microsoft 365 admin center and Microsoft Graph,
identify unused, duplicate, and over-tier assignments, reclaim them safely, and run an ongoing savings
campaign so the spend stays right-sized.

This is a complete, deploy-it-today package for optimizing and reharvesting Microsoft 365 licenses,
written for a competent SAM or IT analyst with no prior reclamation experience.

## What you get
- A plain-language Solution Overview of the Microsoft 365 licensing model, how usage is measured, and the reclaim / right-size / downgrade levers.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click admin center and Microsoft Graph steps in the required order.
- Five PowerShell scripts for license-and-usage discovery, reclaim-candidate validation, a usage-and-savings report, safe reclamation (with `-WhatIf`), and a target-group builder for the campaign.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
A measured baseline of every Microsoft 365 subscription and assignment, a validated set of safe
reclaim candidates (unused, duplicate, and over-tier seats), a safe reclamation workflow that excludes
shared and service accounts and confirms inactivity before touching a seat, a savings report that
quantifies the dollars recovered, and a recurring campaign that keeps the tenant right-sized.

## The deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Microsoft 365 license spend cut to what is actually used — unused, duplicate, and over-tier seats
reclaimed safely, savings quantified, and a recurring campaign in place — proven on a safe pilot set
before you scale.


---


# 1. Solution Overview — Microsoft 365 License Optimization & Reharvesting

## What this solution is
Microsoft 365 licenses are assigned per user (directly or via group-based licensing) and billed per
seat every month whether or not the seat is used. Over time the assigned count drifts above the
*needed* count: people leave but keep their seats, users are placed on a high tier (E5) when a lower
tier (E3) covers what they actually do, and duplicate or overlapping plans accumulate. This solution
is a repeatable way to measure real usage, identify the waste, reclaim it safely, and keep it
reclaimed — using only the Microsoft 365 admin center and Microsoft Graph, no third-party tooling.

## Why this matters
- License waste is invisible by default. The admin center shows *assigned* counts, not *used* counts; the gap is where the money leaks.
- A single E5 → E3 right-size or a single reclaimed leaver seat recovers real, recurring dollars every month, and the savings compound across a fleet.
- Reclamation done carelessly breaks people — a shared mailbox, a service account, or a seasonal user can look "inactive" and must never be stripped blindly. The discipline below makes reclamation safe.
- A one-time cleanup regresses within months as new leavers and new over-tier assignments appear. The value is in the *recurring campaign*, not a single sweep.

## How it works
1. Microsoft 365 subscriptions are read as `subscribedSku` objects via Microsoft Graph: each SKU has a `prepaidUnits` (purchased) and `consumedUnits` (assigned) count — the first gap to close is purchased-but-unassigned seats.
2. Each user's assigned plans are read from the Graph user `assignedLicenses` / `licenseDetails`, giving an authoritative assigned inventory per person and per SKU.
3. Real usage is measured from the Microsoft 365 usage reports (Graph `reports` endpoints and the admin center Usage area): last activity date for Exchange, Teams, SharePoint, OneDrive, and overall last sign-in. A seat with no activity across the window is a candidate.
4. Candidates are classified into three levers — **unused** (assigned but no activity / leaver), **duplicate** (overlapping plans on one user), and **over-tier** (on a higher SKU than usage justifies, e.g. E5 features never touched).
5. Candidates are validated for safety (inactivity confirmed across the full window; shared mailboxes, resource/room accounts, and service accounts excluded) before any change.
6. Reclamation removes the unused/duplicate license or right-sizes the tier; freed seats either reduce the next true-up or are reassigned, and the savings are reported.
7. The whole cycle is wrapped in a recurring **savings campaign** so the tenant stays right-sized as the population changes.

## The three optimization levers
- **Reclaim (unused / leavers):** remove a license from a user with no activity across the measurement window — the largest and safest win when validated.
- **De-duplicate:** remove an overlapping plan when a user carries two SKUs that grant the same service (e.g. a standalone plan plus a suite that already includes it).
- **Right-size (downgrade tier):** move a user from a higher SKU to a lower one when the high-tier-only features show no usage (e.g. E5 → E3 when advanced security/analytics features are unused).

## What you can control
- Which SKUs are in scope for optimization (start with the highest unit cost).
- The inactivity window that defines "unused" (e.g. 90 days of no sign-in and no service activity).
- The exclusion rules that protect shared mailboxes, room/resource accounts, and service accounts.
- The pilot candidate set reclaimed first, before any broad sweep.
- The cadence of the recurring savings campaign (e.g. monthly).

## Limitations (be honest with buyers)
- Microsoft 365 usage reports can be **de-identified** (names replaced with anonymized IDs) by a tenant privacy setting; with it on, per-user matching is impossible until it is turned off (see Requirements).
- Usage data has latency (reports reflect activity up to a few days old) and a fixed maximum window (up to 180 days), so set the inactivity window inside the available range.
- Downgrading a tier can remove features a user *will* need later; right-size on evidence, communicate, and keep an easy re-grant path.
- Removing a license can affect data retention for some services (e.g. mailbox/OneDrive grace periods) — confirm retention before reclaiming a leaver's last license.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and admin center. The standard set:

| Artifact | Name |
|---|---|
| Saved discovery export | `License Inventory – M365 – Discovery` |
| Saved usage export | `Usage Activity – M365 – Discovery` |
| Reclaim-candidate list | `Reclaim Candidates – M365 – Validation` |
| Savings report | `Savings Report – M365 – Report` |
| Pilot reclaim target group | `Reclaim Targets – Pilot – Stage1` |
| Broad reclaim target group | `Reclaim Targets – Broad – Stage2` |
| Exclusion (protected) group | `Reclaim Exclusions – Shared+Service – AllStages` |
| Savings campaign tag | `Savings Campaign – M365 – Recurring` |

## The standard deployment model
> Build the baseline → classify candidates → reclaim a safe **pilot** set first → validate the savings
> and that nobody broke → expand to the broad set and stand up the recurring campaign.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Microsoft 365 License Optimization & Reharvesting

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 Microsoft 365 admin / billing role
**Description:** An account with License Administrator plus Billing Administrator (or Global Administrator for the full workflow).
**Why:** Reading subscriptions and assignments, and removing or right-sizing licenses, requires these roles.
**Verify:** Microsoft 365 admin center (`https://admin.microsoft.com`) → `Billing → Licenses` loads and shows your subscriptions; you can open a user and edit their licenses.
**Implement:** Assign License Administrator + Billing Administrator in `Roles → Role assignments`; reserve Global Administrator for tenant-wide changes.

## 2.2 Microsoft Graph PowerShell SDK
**Description:** The `Microsoft.Graph` PowerShell module installed on the analyst workstation.
**Why:** All five scripts read and (for remediation) write license data through Microsoft Graph.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication`; run `M365LIC-Discovery.ps1` (it installs the module if missing).
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.3 Graph permission scopes (consented)
**Description:** Delegated scopes: `Organization.Read.All`, `User.Read.All`, `Directory.Read.All`, `Reports.Read.All` for read; `User.ReadWrite.All` and `Organization.Read.All` for reclamation.
**Why:** Read scopes pull subscriptions, assignments, and usage; the write scope removes/changes assignments.
**Verify:** Run `M365LIC-Validation.ps1` (read-only) — it connects with the read scopes and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, an admin approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.4 Usage reports enabled and identifiable
**Description:** Microsoft 365 usage analytics available, with the privacy setting that de-identifies user names turned **off** for the analysis.
**Why:** Per-user reclamation needs real names/UPNs in the usage reports; with de-identification on, activity rows are anonymized and cannot be matched to users.
**Verify:** Admin center → `Settings → Org settings → Services → Reports` — confirm "Display concealed user, group, and site names in all reports" is **not** checked (i.e. concealment is off). Then `Reports → Usage` shows named users.
**Implement:** Uncheck the conceal setting (a Global Administrator action), wait for reports to re-render with names, run the analysis, and restore the setting afterward per your privacy policy.

## 2.5 Defined inactivity window and exclusion rules
**Description:** An agreed inactivity threshold (e.g. 90 days of no sign-in and no service activity) and a list/group of accounts that must never be reclaimed (shared mailboxes, room/resource accounts, service accounts).
**Why:** "Unused" must be defined objectively, and protected accounts must be excluded so reclamation is safe.
**Verify:** The threshold is documented and the exclusion group `Reclaim Exclusions – Shared+Service – AllStages` exists with the protected accounts as members.
**Implement:** Agree the window with stakeholders; build the exclusion group with `M365LIC-Set-ScopeTargeting.ps1` (or in Entra) and add shared/service accounts.

## 2.6 Entitlement system of record and a savings target
**Description:** The authoritative purchased-quantity / renewal record (per `global-requirements-asset-mgt.md` G3) and a stated savings goal for the campaign.
**Why:** Reclaimed seats only become savings when reflected at the next true-up/renewal; a target makes the campaign measurable.
**Verify:** You can state the purchased quantity and renewal date for each in-scope SKU, and a savings target is recorded.
**Implement:** Populate the entitlement record from purchase orders / true-up statements; set a target (e.g. reduce assigned-vs-used gap by a chosen percentage).

## 2.7 (Optional) Group-based licensing in use
**Description:** Whether any in-scope licenses are assigned via group-based licensing rather than directly.
**Why:** A group-assigned license cannot be removed from a single user directly — you change group membership instead; mixing the two without knowing leads to "removal didn't stick."
**Verify:** Run `M365LIC-Discovery.ps1` — it flags users whose assignment is inherited from a group (`assignedByGroup`).
**Implement:** For group-assigned seats, reclaim by removing the user from the licensing group (`M365LIC-Set-ScopeTargeting.ps1`), not by stripping the user license.

---
## Checklist
- [ ] License + Billing admin role confirmed
- [ ] Microsoft Graph PowerShell SDK installed
- [ ] Graph read scopes consented (write scope ready for reclamation)
- [ ] Usage reports show named users (concealment off for the analysis)
- [ ] Inactivity window agreed; `Reclaim Exclusions – Shared+Service – AllStages` built
- [ ] Entitlement record current; savings target set
- [ ] Group-based licensing identified (reclaim via group membership where used)
- [ ] `Reclaim Targets – Pilot – Stage1` and `Reclaim Targets – Broad – Stage2` groups planned


---


# Global Requirements — Asset Mgt (category-level)

These requirements apply to **every** solution in the **Asset Mgt** category (Software Asset
Management, license compliance, and entitlement governance). They are published once at the category
level so individual listings stay small. Confirm these before deploying *any* Asset Mgt solution.
Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for user-based license assignment, access, and reporting.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Administrative access to the license sources
**Description:** Admin rights to the consoles that hold entitlements — at minimum the Microsoft 365
admin center (`https://admin.microsoft.com`), plus any others in scope (Adobe Admin Console,
publisher portals).
**Why:** Reading and adjusting entitlements, assignments, and true-ups requires elevated rights.
**Verify:** Each console loads and shows the licensing/billing area for an admin account.
**Implement:** Assign the least-privilege admin role per console (e.g. License Administrator or
Billing Administrator in Microsoft 365); reserve Global Administrator for tenant-wide changes.

## G3. A system of record for entitlements
**Description:** A maintained record of purchased entitlements, contracts, and renewal dates — a
SAM/ITAM tool, a ServiceNow/CMDB instance, or (at minimum) a controlled spreadsheet/repository.
**Why:** Compliance and optimization are only possible against a known, authoritative entitlement count.
**Verify:** You can locate the current entitlement quantity and renewal date for a representative product.
**Implement:** Stand up the records repository and import current purchase orders / true-up statements.

## G4. Deployment / usage discovery data
**Description:** A source of what is actually installed or used — Microsoft Intune, Configuration
Manager (SCCM), a discovery tool (e.g. Flexera), or sign-in/usage telemetry.
**Why:** Reconciling entitlements against real deployment/usage is the core of compliance and reharvesting.
**Verify:** You can export an installed-software or license-usage report for a sample of devices/users.
**Implement:** Enable Intune/Configuration Manager inventory or onboard a discovery tool; for SaaS,
enable usage/sign-in reporting.

## G5. Reporting toolchain
**Description:** Excel (PivotTables, Power Query) and/or Power BI for analysis and dashboards.
**Why:** License usage, compliance, and cost-optimization findings are delivered as reports/dashboards.
**Verify:** Power BI Desktop opens and can connect to a data source; Excel Power Query is available.
**Implement:** Install Power BI Desktop and a current Excel; provision a Power BI workspace if sharing.

## G6. Stakeholder and process alignment
**Description:** Named owners across IT, procurement, and finance, plus a request/intake channel
(e.g. ServiceNow) for license actions.
**Why:** Renewals, true-ups, and reharvesting require coordinated decisions and an auditable workflow.
**Verify:** A request can be raised and routed to the correct owner; procurement contacts are known.
**Implement:** Define roles (SAM analyst, approver, procurement liaison) and a documented intake process.

## G7. A pilot scope
**Description:** A representative subset (one product family, one department, or one publisher) to prove
the process before fleet-wide rollout.
**Why:** Every solution is piloted before broad adoption to validate accuracy and avoid disruption.
**Verify:** A pilot scope and its data owners are identified.
**Implement:** Choose a high-value, well-understood product/department as the first pass.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Microsoft 365 License Optimization & Reharvesting

Follow these steps **in order**. Inventory and usage come from the **Microsoft 365 admin center**
(`https://admin.microsoft.com`) and **Microsoft Graph**; reclamation is run safely with `-WhatIf`
first. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are
reused verbatim.

> **Model:** Build the baseline, classify the waste, reclaim a safe **pilot** set first, validate that
> savings landed and nobody broke, then expand and stand up the recurring campaign.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Step 1 — Pull the license inventory (Assess)
1. Admin center → `Billing → Licenses`. Note each subscription, its purchased quantity, and assigned count — the purchased-minus-assigned gap is the first, zero-risk saving (cancel unassigned seats at renewal).
2. Run `M365LIC-Discovery.ps1` to capture the authoritative inventory via Graph (`subscribedSkus` plus every user's `assignedLicenses`). It writes the export `License Inventory – M365 – Discovery`.
3. Confirm the script flags group-assigned seats (`assignedByGroup`) so you know which seats must be reclaimed via group membership later.

## Step 2 — Pull real usage (Assess)
1. Admin center → `Reports → Usage` — review the Microsoft 365 activity reports (Exchange, Teams, SharePoint, OneDrive) and confirm users are shown by name (Requirement 2.4).
2. Run `M365LIC-Report.ps1` to pull last-activity dates per user from the Graph usage reports and last sign-in from the directory. It writes the export `Usage Activity – M365 – Discovery` and joins it to the inventory.
3. Set the inactivity window you agreed (e.g. 90 days) as the script parameter so "unused" is defined objectively.

## Step 3 — Classify the candidates (Configure)
1. Run `M365LIC-Validation.ps1` to classify every assigned seat into the three levers and produce the list `Reclaim Candidates – M365 – Validation`:
   - **Unused / leaver** — no sign-in and no service activity across the full window.
   - **Duplicate** — a user carrying two SKUs that grant the same service.
   - **Over-tier** — a user on a higher SKU whose high-tier-only services show no activity (e.g. E5 features never used → E3 fits).
2. The script applies the exclusion group `Reclaim Exclusions – Shared+Service – AllStages` and drops any shared mailbox, room/resource, or service account from the candidate list.

## Step 4 — Build the targeting groups (Configure)
1. Run `M365LIC-Set-ScopeTargeting.ps1` to create/populate the Entra groups:
   - `Reclaim Exclusions – Shared+Service – AllStages` — protected accounts (build this first; never reclaimed).
   - `Reclaim Targets – Pilot – Stage1` — a small, safe subset of validated candidates (e.g. obvious leavers from one department).
   - `Reclaim Targets – Broad – Stage2` — the remaining validated candidates.
2. Tag the campaign as `Savings Campaign – M365 – Recurring` so each cycle's actions roll up to one savings line.

## Step 5 — Dry-run the reclamation (Pilot, no changes yet)
1. Run `M365LIC-Remediation.ps1 -WhatIf -TargetGroup "Reclaim Targets – Pilot – Stage1"`. With `-WhatIf` (the default) it makes **no changes** — it prints exactly which license each user would lose or how each would be right-sized.
2. Read every line. Confirm each user is genuinely a leaver / duplicate / over-tier case and that no protected account appears. For any leaver, confirm data-retention implications (mailbox/OneDrive grace) before proceeding.

## Step 6 — Reclaim the pilot set (Pilot)
1. Re-run `M365LIC-Remediation.ps1 -Execute -TargetGroup "Reclaim Targets – Pilot – Stage1"` to apply only the validated pilot changes (remove unused/duplicate licenses; right-size over-tier users).
2. For any seat assigned by group, the script reclaims it by removing the user from the licensing group rather than stripping the user license (Requirement 2.7).

## Step 7 — Validate the pilot (Validate)
1. Run `M365LIC-Validation.ps1` again — the reclaimed pilot users should no longer appear as candidates.
2. Run `M365LIC-Report.ps1` to produce `Savings Report – M365 – Report` — confirm the assigned count dropped and the recovered monthly cost is quantified.
3. Wait a short observation period and check no reclaimed user filed an access ticket. Complete the **Testing Guide** before expanding.

## Step 8 — Expand and reclaim the broad set (Expand)
1. Once the pilot passes the gate, run `M365LIC-Remediation.ps1 -WhatIf -TargetGroup "Reclaim Targets – Broad – Stage2"`, review, then `-Execute` it the same way as the pilot.
2. Re-run `M365LIC-Report.ps1` to update `Savings Report – M365 – Report` with the full recovered amount and reflect freed seats in your entitlement record for the next true-up/renewal.

## Step 9 — Stand up the recurring campaign (Expand)
1. Schedule the read-only chain monthly: `M365LIC-Discovery.ps1` → `M365LIC-Report.ps1` → `M365LIC-Validation.ps1`. Each run refreshes `Reclaim Candidates – M365 – Validation` with newly inactive/over-tier seats.
2. Each cycle, refresh the target groups with `M365LIC-Set-ScopeTargeting.ps1`, dry-run, then execute under the `Savings Campaign – M365 – Recurring` tag — keeping the tenant right-sized as the population changes.

---
### Order of operations
`Inventory → Usage → Classify → Build targeting groups → Dry-run (-WhatIf) → Reclaim pilot → Validate savings → Expand to broad → Recurring campaign`


---


# 5. Testing Guide — Microsoft 365 License Optimization & Reharvesting

Run after building the baseline and after each reclamation stage. Every test is safe; the reclamation
dry-run is the gate before any change.

## Test 1 — Inventory is complete and authoritative
**Do:** Run `M365LIC-Discovery.ps1`; compare its subscription totals against `Billing → Licenses` in the admin center.
**Expected:** Each in-scope SKU's purchased and assigned counts match the admin center; group-assigned seats are flagged.

## Test 2 — Usage data is identifiable and within window
**Do:** Run `M365LIC-Report.ps1`; spot-check a few users against `Reports → Usage`.
**Expected:** Users appear by name (not anonymized), with last-activity dates inside the available window — confirming Requirement 2.4.

## Test 3 — Candidates classify correctly
**Do:** Run `M365LIC-Validation.ps1`; inspect `Reclaim Candidates – M365 – Validation`.
**Expected:** Each candidate is correctly labeled unused / duplicate / over-tier, and no shared mailbox, room/resource, or service account is present (exclusions applied).

## Test 4 — Dry-run makes no changes
**Do:** Run `M365LIC-Remediation.ps1 -WhatIf -TargetGroup "Reclaim Targets – Pilot – Stage1"`; afterward re-run `M365LIC-Discovery.ps1`.
**Expected:** The dry-run lists intended actions; assigned counts are unchanged — `-WhatIf` truly changed nothing.

## Test 5 — Pilot reclamation lands
**Do:** Run `M365LIC-Remediation.ps1 -Execute` on the pilot group, then `M365LIC-Validation.ps1`.
**Expected:** Reclaimed pilot users no longer appear as candidates; the targeted licenses are removed or right-sized.

## Test 6 — Savings are quantified
**Do:** Run `M365LIC-Report.ps1` to produce `Savings Report – M365 – Report`.
**Expected:** Assigned count dropped by the pilot amount and the recovered monthly cost is shown.

## Test 7 — No user impact
**Do:** Observe the agreed waiting period after the pilot; check for access tickets from reclaimed users.
**Expected:** No reclaimed user reports a lost capability they actually needed (validates the inactivity window and exclusions).

## Test 8 — Recurring run refreshes candidates
**Do:** Re-run the read-only chain (`Discovery → Report → Validation`) in a later cycle.
**Expected:** Newly inactive/over-tier seats appear; previously reclaimed users do not — the campaign self-refreshes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass; pilot savings landed with zero genuine user impact |
| **Broad pass** | Tests 4–6 pass for `Reclaim Targets – Broad – Stage2`; `Savings Report – M365 – Report` reflects the full recovered amount before the entitlement record / true-up is updated |


---


# 6. Troubleshooting Guide — Microsoft 365 License Optimization & Reharvesting

Use `M365LIC-Discovery.ps1` / `M365LIC-Validation.ps1` for state, `M365LIC-Report.ps1` for usage and
savings, and `M365LIC-Remediation.ps1` (`-WhatIf` first) for safe fixes.

## A. Connection / permission errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scope is denied | Read scopes not consented, or admin consent required | Re-run and accept the prompt; have an admin grant `Organization.Read.All`, `User.Read.All`, `Directory.Read.All`, `Reports.Read.All` once in Entra |
| Reclamation errors on write | Missing `User.ReadWrite.All` | Consent the write scope; confirm the account holds License + Billing Administrator |

## B. Usage report shows anonymized users
- Names appear as concealed IDs → the tenant privacy setting is concealing report identities. Turn it off for the analysis (`Settings → Org settings → Services → Reports`), let reports re-render, run `M365LIC-Report.ps1`, then restore the setting per policy (Requirement 2.4).

## C. Inventory counts don't match the admin center
| Symptom | Cause | Remediation |
|---|---|---|
| Assigned count differs from `Billing → Licenses` | Replication lag, or group-assigned seats counted differently | Re-run `M365LIC-Discovery.ps1` after a short wait; confirm group-assigned (`assignedByGroup`) seats are accounted for |
| A SKU is missing | Trial/standalone SKU not in scope filter | Add the SKU's part number to the discovery scope |

## D. License removal "didn't stick"
- The seat is assigned via group-based licensing, so removing the user license is overridden. Reclaim by removing the user from the licensing group instead (`M365LIC-Set-ScopeTargeting.ps1`) — see Requirement 2.7.

## E. A reclaimed user lost something they needed
- The inactivity window was too short or an exclusion was missing. Re-grant the license immediately, add the account to `Reclaim Exclusions – Shared+Service – AllStages` (if it should be protected), and lengthen the window before the next cycle.

## F. Savings not reflected on the bill
- Reclaimed seats reduce *assigned* counts but the *purchased* quantity (and the invoice) only drops when you lower seats at the next true-up/renewal. Update the entitlement record and adjust the subscription quantity in `Billing → Your products`.

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Organization.Read.All','Reports.Read.All' -NoWelcome
Get-MgSubscribedSku | Select-Object SkuPartNumber, @{n='Purchased';e={$_.PrepaidUnits.Enabled}}, ConsumedUnits
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365ActiveUserDetail(period='D90')?`$format=text/csv"
```

## H. When to escalate
If scopes are consented, the account holds License + Billing Administrator, usage reports show named
users, and a license still cannot be removed or right-sized, capture the Graph error response and the
user's `licenseDetails`, confirm the seat is not group-assigned or blocked by a dependency, and open a
Microsoft support case.


---


# 7. Best Practices — Microsoft 365 License Optimization & Reharvesting

- **Close the unassigned gap first.** Purchased-but-unassigned seats are pure waste and zero-risk to drop at renewal — start there before touching a single user.
- **Always dry-run before you reclaim.** Run `M365LIC-Remediation.ps1 -WhatIf` and read every line; `-WhatIf` is the default for a reason. Execution is a deliberate, separate step.
- **Protect shared and service accounts, always.** Keep `Reclaim Exclusions – Shared+Service – AllStages` current; shared mailboxes, room/resource accounts, and service accounts look inactive but must never be stripped.
- **Define "unused" objectively.** Use a documented inactivity window (no sign-in *and* no service activity across the full period), not a hunch — and pick a window inside the reports' available range.
- **Pilot a safe set first.** Reclaim obvious leavers in one department before any broad sweep; validate savings and zero user impact at the gate, then expand.
- **Right-size on evidence, with a re-grant path.** Downgrade a tier only when the high-tier-only features show no usage, communicate the change, and keep re-granting one click away in case a need appears later.
- **Mind data retention on the last license.** Removing a leaver's final license starts mailbox/OneDrive grace timers — confirm retention/offboarding before reclaiming.
- **Reclaim group-assigned seats via the group.** Where group-based licensing is used, remove the user from the licensing group; stripping the user license won't stick.
- **Make it recurring, not a one-off.** A single cleanup regresses within months. Schedule the read-only `Discovery → Report → Validation` chain monthly under `Savings Campaign – M365 – Recurring`.
- **Close the loop with finance.** Reflect freed seats in the entitlement record so they actually reduce the next true-up/renewal — reclaimed seats only become savings when the bill changes.


---


# 8. Deliverables Summary — Microsoft 365 License Optimization & Reharvesting

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Microsoft 365 licensing model, how usage is measured, the reclaim / de-dupe / right-size levers, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered admin center + Microsoft Graph steps (inventory, usage, classify, target, dry-run, reclaim, validate, expand, recurring) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `M365LIC-Discovery.ps1` | Read-only inventory of subscriptions (`subscribedSkus`) and per-user assignments via Graph; flags group-assigned seats. Writes `License Inventory – M365 – Discovery` |
| `M365LIC-Validation.ps1` | Read-only classification of seats into unused / duplicate / over-tier; applies the exclusion group. Writes `Reclaim Candidates – M365 – Validation` |
| `M365LIC-Report.ps1` | Read-only usage + savings report from Graph usage reports and sign-in data. Writes `Usage Activity – M365 – Discovery` and `Savings Report – M365 – Report` |
| `M365LIC-Remediation.ps1` | Safe reclamation (remove unused/duplicate license, right-size over-tier); `-WhatIf` by default, `-Execute` to apply; excludes protected accounts |
| `M365LIC-Set-ScopeTargeting.ps1` | Builds/populates the Entra groups (exclusions, pilot, broad) and tags the recurring savings campaign |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Microsoft 365 license spend cut to what is actually used — unused, duplicate, and over-tier seats
reclaimed safely, savings quantified in `Savings Report – M365 – Report`, and a recurring campaign
keeping the tenant right-sized.
