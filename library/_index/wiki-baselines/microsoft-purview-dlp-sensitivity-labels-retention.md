# Microsoft Purview — DLP, Sensitivity Labels & Retention

> **Version 1.0.0** · Category: Purview · Solution code: PURVIEW

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview: DLP, Sensitivity Labels & Retention

**White-label · Security Solutions**

Sensitive data leaks and compliance gaps almost always trace back to the same root: data that is
never classified, never protected, and never retained on a defined schedule. Microsoft Purview fixes
that — but rolled out carelessly, labels confuse users, Data Loss Prevention (DLP) floods the help
desk with false positives, and retention either deletes too much or nothing at all.

This is a complete, deploy-it-in-order package for implementing Microsoft Purview information
protection with a repeatable method: a sane sensitivity-label taxonomy with auto-labeling, DLP
policies that start in audit and are tuned before they enforce, and retention labels and policies
(plus records management) that meet compliance without surprises. It is written for an administrator
with no prior Purview experience.

## What you get
- A plain-language Solution Overview of sensitivity labels, label policies, auto-labeling, DLP across
  Microsoft 365 and endpoints, and retention/records — and how they work together.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps in the Microsoft Purview portal.
- Five PowerShell scripts for configuration discovery, coverage validation, a classification and DLP
  event report, safe remediation of gaps, and a protection-scope group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable set of objects — a sensitivity-label taxonomy, label policies, auto-labeling
policies, DLP policies, and retention labels/policies — deployed on the assess-configure-pilot model
with a mandatory DLP audit gate before any policy switches to enforce, and a documented rollback.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Data classified, protected, and retained with Microsoft Purview — a clear label taxonomy with
auto-labeling, DLP tuned in audit before it enforces, and retention that meets compliance without
over- or under-deleting — proven on a pilot before you scale.


---


# 1. Solution Overview — Microsoft Purview: DLP, Sensitivity Labels & Retention

## What Microsoft Purview information protection is
Microsoft Purview is Microsoft's cloud suite for classifying, protecting, and retaining data across
Microsoft 365. Three capabilities work together:

1. Sensitivity labels — persistent tags (for example `Public`, `General`, `Confidential`,
   `Highly Confidential`) that can encrypt content, apply visual markings, and control sharing. They
   travel with the file and enforce protection wherever the file goes.
2. Data Loss Prevention (DLP) — policies that detect sensitive content (credit-card numbers, health
   identifiers, a matched sensitivity label, and so on) and take action — audit, warn, or block — as
   users share it across Exchange, SharePoint, OneDrive, Teams, and managed endpoints.
3. Retention and records management — labels and policies that keep content for a required period and
   then delete it (or block deletion for records), so the organization meets legal and regulatory
   obligations without hoarding or over-deleting data.

## How it works
1. You design a small sensitivity-label taxonomy and publish it with a label policy so it appears in
   Office apps, Outlook, and the web. Auto-labeling can apply labels automatically based on content.
2. DLP policies reference sensitive-information types and/or sensitivity labels. Each policy is first
   deployed in an audit-only test mode; you review the matches (the DLP audit gate), tune the
   conditions to remove false positives, and only then switch the policy to enforce (warn or block).
3. Retention labels and retention policies set how long content lives and what happens at the end of
   the period. Records management adds regulatory records (declared, immutable) and disposition
   review.
4. Every action is logged in the Microsoft Purview audit and activity explorer, so classification and
   DLP coverage can be reported.

## What you can control
- The label taxonomy, label order/priority, and the protection each label applies (encryption,
  marking, sharing restrictions).
- Where labels are published (users/groups) and whether auto-labeling applies them by content match.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoint devices), the sensitive-information
  types or labels a policy matches, and the action (audit, notify, block) plus policy tips.
- Retention duration, trigger, and end-of-life action (delete, retain, or declare a record); records
  management and disposition review.

## Benefits
- Protection that travels — a sensitivity label encrypts and marks content so it stays protected
  outside the tenant.
- Fewer leaks, fewer false positives — DLP tuned in audit before enforcement blocks real risk without
  blocking legitimate work.
- Defensible retention — content is kept and deleted on a defined schedule, satisfying compliance
  without over-retention.
- Reportable coverage — classification and DLP events are visible per service and fleet-wide.

## Limitations (be honest with buyers)
- Auto-labeling for SharePoint/OneDrive at rest and several DLP/endpoint features require the higher
  Microsoft 365 / Purview plans; the Requirements Guide names the licensing.
- Endpoint DLP requires devices onboarded to Microsoft Purview (the same onboarding used by Defender
  for Endpoint).
- Encryption applied by a label can affect third-party or legacy apps that do not understand the
  protection; pilot before broad enforcement.
- Retention deletion is irreversible once the period elapses; validate the schedule on a pilot scope
  first.

## The standard deployment model
> **Design the label taxonomy → publish labels and label policies → configure auto-labeling → build
> DLP in audit and tune → set retention/records → pilot → validate → expand.** repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand**, with a DLP audit gate before any policy
> enforces and a documented rollback.


---


# 2. Requirements Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-security.md`.

## 2.1 Microsoft 365 + Purview licensing
**Description:** Licensing that includes sensitivity labels, DLP, and retention. Sensitivity labels
and basic DLP ship in Microsoft 365 E3 / Business Premium; auto-labeling at rest, endpoint DLP, and
advanced records management require Microsoft 365 E5 (or the E5 Compliance / Information Protection
and Governance add-on).
**Why:** The Purview features this solution configures are gated by plan; auto-labeling and endpoint
DLP will not appear without the higher plan.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; run `PURVIEW-Discovery.ps1`.
**Implement:** Assign the required plan (E3/Business Premium for labels + basic DLP; E5 or the E5
Compliance add-on for auto-labeling at rest, endpoint DLP, and advanced records).

## 2.2 Microsoft Purview roles
**Description:** The operator holds the roles needed to create labels, DLP, and retention — for
example **Compliance Administrator** (or **Information Protection Admin** plus **Data Loss Prevention
roles**) in the Purview portal.
**Why:** Creating and publishing labels, DLP policies, and retention policies requires these roles;
Global Administrator alone is not the least-privilege choice.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership.
**Implement:** Add the operator to **Compliance Administrator** (or **Information Protection Admin** +
DLP roles). Reserve Global Administrator for tenant-wide changes.

## 2.3 Sensitivity-label taxonomy defined
**Description:** A short, agreed set of labels with a clear meaning for each — the taxonomy this
solution publishes as `Sensitivity Label - Confidential - All Users` and its siblings.
**Why:** Labels only work if users understand them; too many labels confuse, too few under-protect.
**Verify:** A one-page taxonomy exists (label name, meaning, protection, who applies it).
**Implement:** Agree a 3–5 label taxonomy with data owners before configuring (see the Implementation
Guide, Step 1).

## 2.4 Data owners and a classification decision
**Description:** Named business owners who decide what is sensitive and how long it must be kept.
**Why:** DLP conditions and retention durations are business decisions, not IT defaults; without an
owner the policies will be wrong.
**Verify:** A named owner (and a retention schedule source) exists per data category.
**Implement:** Identify data owners; capture the sensitive data types and the required retention
periods.

## 2.5 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group of pilot users for label/DLP/retention piloting, and
— for endpoint DLP — devices onboarded to Microsoft Purview.
**Why:** Every policy is piloted before fleet rollout; DLP in particular must run in audit on a pilot
before it can enforce safely.
**Verify:** Entra → **Groups**; the pilot group `Purview - Pilot Users` exists. Purview → **Settings
→ Device onboarding** shows pilot devices onboarded (endpoint DLP only).
**Implement:** Build the pilot group with `PURVIEW-Set-ScopeTargeting.ps1`; onboard pilot devices via
the Purview device onboarding package.

## 2.6 Endpoint onboarding (endpoint DLP only)
**Description:** Windows devices onboarded to Microsoft Purview so endpoint DLP can monitor file
activity.
**Why:** Endpoint DLP conditions (copy to USB, upload to a browser, print) require onboarded devices;
un-onboarded devices are invisible to endpoint DLP.
**Verify:** Purview → **Settings → Device onboarding → Devices**; run `PURVIEW-Discovery.ps1`.
**Implement:** Deploy the onboarding configuration (Intune or the script package) to the pilot group.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview audit (unified audit log) is turned on.
**Why:** DLP tuning and coverage reporting read audit/activity data; without it you cannot review the
audit gate or report classification.
**Verify:** Purview → **Audit**; searching returns results. Run `PURVIEW-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.8 Change control for enforce-mode changes
**Description:** A documented change-control / rollback process for switching any DLP policy from
audit to enforce, or for activating a retention policy that deletes content.
**Why:** Enforce-mode DLP can block user work and retention deletion is irreversible; a pilot gate and
rollback are mandatory.
**Verify:** A change ticket exists with an approver, a pilot scope, and a documented rollback (revert
the DLP policy to test/audit; disable the retention policy).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] Microsoft 365 + Purview licensing (E3/Business Premium for labels + basic DLP; E5/add-on for auto-labeling at rest, endpoint DLP, advanced records) — `PURVIEW-Discovery.ps1`
- [ ] Purview roles assigned (Compliance Administrator / Information Protection + DLP)
- [ ] Sensitivity-label taxonomy defined (3–5 labels)
- [ ] Data owners named; sensitive types + retention periods captured
- [ ] Pilot scope group `Purview - Pilot Users` created — `PURVIEW-Set-ScopeTargeting.ps1`
- [ ] Endpoint devices onboarded (endpoint DLP only) — `PURVIEW-Discovery.ps1`
- [ ] Purview audit logging enabled — `PURVIEW-Report.ps1`
- [ ] Change control + rollback for enforce-mode / retention deletion


---


# Global Requirements — Security solutions (Intune + Entra ID + cloud PKI) (category-level)

These requirements apply to **every** solution in the **Security solutions (Intune + Entra ID +
cloud PKI)** category. They are published once at the category level so individual listings stay
small. Confirm these before deploying *any* security solution in this category. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID tenant.
**Why:** It is the identity backbone for every cloud-managed device, certificate, and security policy.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers the configuration, certificate, compliance, and security policies these solutions rely on.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating certificate profiles, connectors, and security policies requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted devices are enrolled and manageable.
**Why:** Certificate and security policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution in this category is piloted before fleet rollout — especially anything that touches authentication.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported, current OS baseline
**Description:** Devices on a vendor-supported, currently-patched OS (Windows 10/11, iOS/iPadOS, Android, or macOS as applicable).
**Why:** Modern Intune certificate and security features assume a supported, patched OS.
**Verify:** `winver` (Windows), device **Settings → About**, or Intune → device → **Hardware**.
**Implement:** Patch/upgrade to a supported build before deploying policies.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, certificate issuance, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through proxy/firewall.

## G8. Change control for authentication-impacting changes
**Description:** A documented change-control / rollback process for any change that touches certificates, Wi-Fi, VPN, or sign-in.
**Why:** Certificate and authentication changes can lock users out of network or apps if misconfigured; a pilot gate and rollback are mandatory.
**Verify:** A change ticket exists with an approver, a maintenance window, and a documented rollback step.
**Implement:** Record the change, name a pilot group, define the rollback, and get approval before assigning to production.

---
**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Follow these steps **in order**, in the **Microsoft Purview portal** (`https://purview.microsoft.com`).

> **Model:** Design a small label taxonomy, publish it, add auto-labeling, build DLP in audit and
> tune it (the DLP audit gate) before enforcing, then set retention/records — piloting each on
> `Purview - Pilot Users` before you expand. Pattern: Assess → Configure → Pilot → Validate → Expand.

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Sensitivity labels | `Sensitivity Label - Public - All Users`, `Sensitivity Label - General - All Users`, `Sensitivity Label - Confidential - All Users`, `Sensitivity Label - Highly Confidential - All Users` |
| Label policy | `Label Policy - Sensitivity Taxonomy - All Users` |
| Auto-labeling policy | `Auto-Label - Confidential Financial - Pilot` |
| DLP policy | `DLP Policy - Financial and PII - Audit` (renamed to `... - Enforce` at the gate) |
| Retention label | `Retention Label - Financial Records - 7 Year` |
| Retention policy | `Retention Policy - M365 Baseline - 5 Year` |

## Step 1 — Design the label taxonomy (Assess)
1. With the data owners, agree 3–5 labels and the protection each applies. A common starting set:
   - `Sensitivity Label - Public - All Users` — no protection; shareable externally.
   - `Sensitivity Label - General - All Users` — internal business data; no encryption.
   - `Sensitivity Label - Confidential - All Users` — encrypt; restrict to the organization.
   - `Sensitivity Label - Highly Confidential - All Users` — encrypt; restrict to a named group.
2. Record each label's meaning, protection, and who applies it. This one-pager is the taxonomy from
   Requirement 2.3.

## Step 2 — Create the sensitivity labels
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter `Sensitivity Label - Confidential - All Users` and a user-facing
   tooltip. **Next**.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption** for `Confidential` / `Highly Confidential`; set
   permissions (for example **All Users in <org>** for `Confidential`). Leave `Public` / `General`
   without encryption. **Next**.
5. **Content marking:** add a header/footer/watermark if required (for example `CONFIDENTIAL`).
   **Next**.
6. **Auto-labeling for items:** leave off here (configured centrally in Step 4). **Next → Create the
   label**.
7. Repeat for each label in the taxonomy, creating them in sensitivity order
   (`Public` → `General` → `Confidential` → `Highly Confidential`). Label order sets priority.

## Step 3 — Publish the labels with a label policy
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add all four taxonomy labels. **Next**.
3. **Assign to users and groups:** add `Purview - Pilot Users` for the pilot. **Next**.
4. **Policy settings:** optionally require a justification for downgrading a label and require a label
   for new items. **Next**.
5. **Default label / mandatory labeling:** set a default (for example `General`) if the org wants one.
   **Next**.
6. **Name:** `Label Policy - Sensitivity Taxonomy - All Users`. **Next → Submit**.

## Step 4 — Configure auto-labeling
1. Purview portal → **Information Protection → Auto-labeling → Create auto-labeling policy**.
2. **Choose the information to label:** pick a template (for example **Financial**) or **Custom**.
   **Next**.
3. **Name:** `Auto-Label - Confidential Financial - Pilot`. **Next**.
4. **Admin units / locations:** select **Exchange email**, **SharePoint sites**, **OneDrive
   accounts** as needed. Scope to pilot locations. **Next**.
5. **Rules:** define the condition (for example the **Credit Card Number** and **U.S. / EU sensitive
   information types**) and set the label to apply to `Sensitivity Label - Confidential - All Users`.
   **Next**.
6. **Test the policy first:** choose **Run policy in simulation mode** — do not turn it on yet.
   **Next → Create**. Review the simulation matches before turning the policy on.

## Step 5 — Build the DLP policy in AUDIT mode
1. Purview portal → **Data Loss Prevention → Policies → Create policy**.
2. **Category / template:** choose a template (for example **Financial** or **Privacy**) or
   **Custom**. **Next**.
3. **Name:** `DLP Policy - Financial and PII - Audit`. **Next**.
4. **Locations:** enable **Exchange email**, **SharePoint sites**, **OneDrive accounts**, **Teams
   chat and channel messages**, and **Devices** (endpoint DLP) as licensed. Scope to
   `Purview - Pilot Users` where the location supports user scoping. **Next**.
5. **Rules:** add a rule that matches the sensitive-information types (for example **Credit Card
   Number**, **U.S. Social Security Number**) and/or the label
   `Sensitivity Label - Confidential - All Users`. Set actions to **audit only** — enable **policy
   tips** for visibility but do **not** block. **Next**.
6. **Policy mode:** select **Run the policy in test mode** (turn on policy tips in test mode).
   **Next → Submit**. The policy now audits without blocking.

## Step 6 — Pilot and tune (the DLP audit gate)
1. Let the audit-mode policy run against `Purview - Pilot Users` for the agreed window.
2. Review matches in Purview → **Data Loss Prevention → Alerts** and in **Activity explorer**; run
   `PURVIEW-Report.ps1` for a classification and DLP-event summary.
3. Tune the rules to remove false positives (adjust confidence levels, instance counts, and
   exceptions).
4. **Gate:** only when the audit shows the policy matches real sensitive data and not routine work do
   you proceed to enforce (Step 7). If it is still noisy, keep tuning — do not enforce.

## Step 7 — Switch DLP to ENFORCE (after the gate)
1. Purview portal → **Data Loss Prevention → Policies →** open `DLP Policy - Financial and PII -
   Audit` → **Edit**.
2. Rename it to `DLP Policy - Financial and PII - Enforce` so the stage is visible.
3. **Rules:** change the action from audit to **Block** (or **Block with override**) as the business
   requires; keep policy tips on. **Next**.
4. **Policy mode:** select **Turn the policy on**. **Next → Submit**. Enforcement now applies to the
   pilot scope first; widen the scope in Step 10.
5. **Rollback (if needed):** set the policy mode back to **Test mode** (audit) or turn the policy off.

## Step 8 — Create retention labels
1. Purview portal → **Data Lifecycle Management → Retention labels → Create a label**.
2. **Name:** `Retention Label - Financial Records - 7 Year`. **Next**.
3. **Retention settings:** **Retain items for** 7 years, then **Start of the retention period** based
   on when items were created (or labeled). Choose the end action: **Delete**, or **Mark as a record**
   (records management) if the item must be immutable. **Next → Create**.

## Step 9 — Create a retention policy (baseline)
1. Purview portal → **Data Lifecycle Management → Retention policies → New retention policy**.
2. **Name:** `Retention Policy - M365 Baseline - 5 Year`. **Next**.
3. **Locations:** enable **Exchange mailboxes**, **SharePoint sites**, **OneDrive accounts**, and
   **Teams** as required. Scope to `Purview - Pilot Users` for the pilot. **Next**.
4. **Retention settings:** **Retain items for** 5 years then decide whether to delete or retain only.
   **Next → Submit**.
5. For regulatory records, configure **Records Management → File plan** to publish record labels and
   set **disposition review** so deletions are reviewed, not automatic.

## Step 10 — Validate, then expand
1. Complete the Testing Guide against `Purview - Pilot Users`.
2. Run `PURVIEW-Validation.ps1` (labels published, DLP present, retention present) and
   `PURVIEW-Report.ps1` (classification + DLP-event coverage).
3. Widen scope: republish `Label Policy - Sensitivity Taxonomy - All Users`, the DLP enforce policy,
   and the retention policy from `Purview - Pilot Users` to broader groups (or **All users** /
   **All locations**) once the pilot passes. Turn auto-labeling on (out of simulation) after its
   simulation is clean.
4. Re-validate each expansion with `PURVIEW-Validation.ps1` and `PURVIEW-Report.ps1`.

---
### Order of operations
`Taxonomy → labels → label policy → auto-labeling (simulation) → DLP (audit) → audit gate → DLP (enforce) → retention labels → retention policy/records → validate → expand`


---


# 5. Testing Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Run after publishing to `Purview - Pilot Users` (Implementation Step 3 onward), before the DLP audit
gate (Step 6), and again after each expansion.

## Test 1 — Labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`PURVIEW-Validation.ps1`.
**Expected:** All four taxonomy labels appear (`Sensitivity Label - Public - All Users` through
`Sensitivity Label - Highly Confidential - All Users`) via
`Label Policy - Sensitivity Taxonomy - All Users`.

## Test 2 — Label protection applies
**Do:** Apply `Sensitivity Label - Confidential - All Users` to a test document and try to open it as
an out-of-scope external user.
**Expected:** The document is encrypted/marked; the external user is denied per the label's
permissions.

## Test 3 — Auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open
`Auto-Label - Confidential Financial - Pilot` → **Simulation**.
**Expected:** The simulation lists items that match the rule (for example files containing card
numbers) — and does not flag routine, non-sensitive content.

## Test 4 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a fake credit-card number to an external
address; check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or run
`PURVIEW-Report.ps1`.
**Expected:** `DLP Policy - Financial and PII - Audit` records the match (policy tip shown, no block)
— the audit gate has data to review.

## Test 5 — DLP enforces (after the gate)
**Do:** After Step 7, repeat Test 4 against `DLP Policy - Financial and PII - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is
logged.

## Test 6 — Retention label applied and honored
**Do:** Apply `Retention Label - Financial Records - 7 Year` to a test item and attempt to delete it.
**Expected:** The item is retained for the period (or declared a record and blocked from deletion) per
the label.

## Test 7 — Retention policy scoped
**Do:** Confirm `Retention Policy - M365 Baseline - 5 Year` is applied to the pilot locations
(Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`PURVIEW-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams.

## Test 8 — Coverage report
**Do:** Run `PURVIEW-Report.ps1`.
**Expected:** A summary of classification (labeled items) and DLP events across the enabled services,
so coverage and gaps are visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4, 6–7 pass on `Purview - Pilot Users`; the DLP audit shows real matches and acceptable noise |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 5 (enforce) run |
| **Expand pass** | Tests 1, 4/5, 7, 8 pass after widening scope beyond the pilot |


---


# 6. Troubleshooting Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Use `PURVIEW-Discovery.ps1` for the tenant's current config, `PURVIEW-Validation.ps1` to confirm the
named objects are in place, `PURVIEW-Report.ps1` for classification and DLP-event coverage, and
`PURVIEW-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Sensitivity labels not appearing for users
| Symptom | Cause | Remediation |
|---|---|---|
| No Sensitivity button / labels missing | Label policy not published to the user, or publish still propagating | Confirm the user is in `Purview - Pilot Users`; verify `Label Policy - Sensitivity Taxonomy - All Users` targets them; allow up to 24 hours to propagate |
| Labels appear but no encryption | Label scoped to items but encryption not configured | Edit the label (`Sensitivity Label - Confidential - All Users`), enable **Configure encryption**, republish |
| Wrong label order/priority | Labels created out of sensitivity order | Reorder labels `Public` → `General` → `Confidential` → `Highly Confidential`; order sets priority |

## B. Auto-labeling not labeling
- Confirm the policy `Auto-Label - Confidential Financial - Pilot` is turned on (not left in
  simulation). Simulation reports matches but applies nothing.
- Auto-labeling for SharePoint/OneDrive at rest requires the higher plan; verify licensing with
  `PURVIEW-Discovery.ps1`.
- Check the rule's sensitive-information types and confidence — too high a confidence or instance
  count can suppress matches.

## C. DLP is too noisy (false positives)
- This is expected before the audit gate — keep the policy in test/audit mode and tune. Raise the
  match confidence, require a higher instance count, and add exceptions.
- Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
  `PURVIEW-Report.ps1`.
- Do not switch `DLP Policy - Financial and PII - Audit` to enforce until the noise is acceptable.

## D. DLP not blocking after enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Enforce policy does not block | Policy left in test mode, or scope excludes the user | Confirm `DLP Policy - Financial and PII - Enforce` mode is **Turn the policy on**; confirm the user/location is in scope |
| Endpoint (device) rules never fire | Device not onboarded to Purview | Onboard the device (Purview → **Settings → Device onboarding**); verify with `PURVIEW-Discovery.ps1` |
| Teams/SharePoint not covered | Location not enabled on the policy | Edit the policy and enable the missing location |

## E. Retention deleting too much or nothing
- Over-deletion: confirm the duration on `Retention Policy - M365 Baseline - 5 Year` and the end
  action; pilot on `Purview - Pilot Users` before widening. Deletion is irreversible.
- Nothing retained: confirm the policy shows **On** and is scoped to the correct locations; run
  `PURVIEW-Validation.ps1`.
- For records, enable **disposition review** so items are reviewed before deletion rather than
  auto-deleted.

## F. Licensing / feature missing
- Auto-labeling at rest, endpoint DLP, and advanced records require Microsoft 365 E5 or the E5
  Compliance add-on. If a feature is absent from the portal, verify the plan with
  `PURVIEW-Discovery.ps1` and Requirement 2.1.

## G. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, ContentType
Get-LabelPolicy | Select-Object Name, Enabled
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode
```
For classification and DLP events, use the Purview **Activity explorer** and the unified audit log
(Requirement 2.7).

## H. When to escalate
If a label policy is published and propagated, the user is in scope, licensing is correct, and labels
still do not appear (or DLP still does not act) after 24 hours and a `PURVIEW-Remediation.ps1` run,
collect the output of `PURVIEW-Discovery.ps1` and `PURVIEW-Validation.ps1` and open a Microsoft
support case.


---


# 7. Best Practices — Microsoft Purview: DLP, Sensitivity Labels & Retention

- **Keep the taxonomy small.** Three to five labels people can actually reason about beats a dozen
  nobody uses. Name each label plainly and give it a clear tooltip.
- **Publish before you protect.** Roll labels out with `Label Policy - Sensitivity Taxonomy - All
  Users` to a pilot first; confirm they appear and behave before adding encryption for everyone.
- **Simulate auto-labeling.** Always run an auto-labeling policy in simulation
  (`Auto-Label - Confidential Financial - Pilot`) and review matches before turning it on — it labels
  content at scale and mistakes are visible to users.
- **Audit DLP before you enforce.** This is the single most important practice: run every DLP policy
  in test/audit mode, review the matches, tune out false positives, and only then switch to enforce.
  A blocked-work storm is the fastest way to lose trust in DLP.
- **Tune with confidence levels and instance counts.** Reduce false positives by raising the match
  confidence and requiring a minimum count of sensitive instances rather than a single hit.
- **Name every object by purpose and stage.** Use the `<Purpose> - <Scope> - <Stage>` convention
  (for example rename `DLP Policy - Financial and PII - Audit` to `... - Enforce` at the gate) so the
  portal shows exactly where each policy is in its lifecycle.
- **Pilot retention on a scope first.** Retention deletion is irreversible; validate
  `Retention Policy - M365 Baseline - 5 Year` on `Purview - Pilot Users` before widening, and use
  disposition review for records so nothing is auto-deleted unreviewed.
- **Match retention to a real schedule.** Set durations from a records schedule or legal requirement,
  not a guess; capture the source so the schedule is defensible in an audit.
- **Report coverage regularly.** Track labeled-item and DLP-event coverage with `PURVIEW-Report.ps1`
  and chase gaps (unlabeled sensitive locations, services with no DLP).
- **Document the objects and the rollback.** Record the label taxonomy, policy names, scopes, and the
  rollback (revert DLP to audit; disable a retention policy) for repeatability and change control.


---


# 8. Deliverables Summary — Microsoft Purview: DLP, Sensitivity Labels & Retention

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Purview information protection is — labels, auto-labeling, DLP, retention/records — benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Security) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps (labels, label policy, auto-labeling, DLP audit-then-enforce, retention/records) |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIEW-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, and retention policies (labels/DLP/retention config); flags endpoint onboarding and licensing signals |
| `PURVIEW-Validation.ps1` | Confirms the expected labels are published, the DLP policy exists, and the retention policy exists and is on |
| `PURVIEW-Report.ps1` | Classification + DLP-event coverage summary across the enabled services |
| `PURVIEW-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); republishes/enables named objects only when confirmed |
| `PURVIEW-Set-ScopeTargeting.ps1` | Builds/updates the pilot and protection-scope Entra groups |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate →
  Expand**, with a DLP audit gate before enforce and a documented rollback.

## Outcome
Data classified, protected, and retained with Microsoft Purview — a clear label taxonomy with
auto-labeling, DLP tuned in audit before it enforces, and retention that meets compliance without
over- or under-deleting — proven on a pilot before you scale.
