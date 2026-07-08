# SharePoint Online DLP — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPSPO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — SharePoint Online DLP: Microsoft Purview

SharePoint and OneDrive are where the organization's documents live, and sharing is one click away. A site
owner shares a library "with anyone," a user forwards a OneDrive link outside the company, a spreadsheet
full of customer PII sits in a site open to the whole tenant — and by default nothing inspects the content
or the share. You cannot claim your documents are protected when a share link can turn an internal file
public with one click. This solution closes that gap with **Microsoft Purview Data Loss Prevention** for
SharePoint and OneDrive — policies that inspect documents for sensitive content and govern how they can be
shared — configured, piloted in test mode, validated, and defensible.

This is a complete, do-it-today package written for an administrator implementing SharePoint/OneDrive DLP
for the first time. It delivers the capability end-to-end — from reading existing policies and available
sensitive information types, through designing content and sharing conditions and creating the policy **in
test mode** on a limited pilot, to tuning false positives, validating, and only then moving to enforcement
as a deliberate, approved step — with every policy, rule, and pilot scope named once and reused everywhere.
Because DLP enforcement blocks real collaboration, the guide never enforces on day one: it starts in test
mode and gates enforcement behind an explicit, separate action. Because capability availability is
licensing-dependent and the portal is evolving, the guide cites the method and flags every capability
"verify your licensing/tenant."

## What you get
- A plain-language Solution Overview of SharePoint/OneDrive DLP — sensitive-content detection, sharing and
  external-access conditions, policy tips, notifications, and test vs enforce mode.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: DLP licensing (E3
  baseline; E5 for advanced), the least-privilege DLP role, the S&C PowerShell toolchain, the sensitive
  content and sharing to govern, the in-scope locations and pilot scope, test-mode discipline, and the
  notification/exception design.
- An Implementation Guide of precise, ordered steps: assess, design content + sharing + actions, create the
  policy in test mode on the pilot, pilot and tune, validate, **enforce deliberately**, then expand.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default; creates in test mode; enforce behind its own action), Validation, and Reporting —
  built on Security & Compliance PowerShell, **read-only or `-WhatIf` by default with no credentials in
  code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
SharePoint and OneDrive sharing governed from Purview: documents inspected for sensitive content and
external sharing restricted where the content warrants it — proven in test mode on a limited pilot before
any enforcement.

## The deployment model
Assess → Design → Configure (**test mode**) → Pilot → Validate → Expand (**enforce deliberately**) — with
a test-mode gate before enforcement and enforcement enabled only after validation and approval.

## Outcome
The SharePoint sharing blind spot closed — sensitive documents can't be shared externally, users see a
policy tip that teaches, and every match is logged — with the determination of which content is sensitive
and which sharing is acceptable left to the compliance, security, and privacy owners who make it.


---


# 1. Solution Overview — SharePoint Online DLP (Microsoft Purview)

## What this solution is
SharePoint and OneDrive are where the organization's documents live — and sharing is one click away. A
site owner shares a library "with anyone," a user forwards a OneDrive link outside the company, a document
full of customer PII sits in a site that's open to the whole tenant. Any of those can put sensitive
content in front of the wrong audience, and by default nothing inspects the content or the share. This
solution closes that gap with **Microsoft Purview Data Loss Prevention (DLP)** for SharePoint and
OneDrive — policies that inspect documents for **sensitive content** and govern how they can be
**shared**:

- **Detect sensitive content** — match documents against **sensitive information types** (credit-card,
  national ID, health, financial), **sensitivity labels**, keyword/dictionary conditions, or trainable
  classifiers, so the policy acts on what a document *contains*, not just where it sits.
- **Govern sharing and external access** — detect and (after piloting) **block or restrict external
  sharing**, sharing with "everyone," or access by people outside the organization, so sensitive
  documents don't leave through a share link.
- **Educate with policy tips and notify** — show the user a **policy tip** at the point of sharing and
  notify/alert admins, so protection teaches rather than just blocks.
- **Prove it in test mode first** — every DLP policy is created in **test/simulation mode** (test with or
  without policy tips), so you see exactly what it *would* match and block on real content before any
  enforcement affects a user.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com) and **Security &
Compliance PowerShell** (`Connect-IPPSSession`) — no third-party tooling. Policies are configured,
**piloted in test mode first**, validated against pass/fail gates, then enforced and expanded.

> **DLP acts on content and actions, not on storage cleanup.** This solution inspects SharePoint/OneDrive
> documents and controls sharing/external access. It does **not** retain or delete content (that's the
> Data Lifecycle solution) or classify items with sensitivity labels (that's an Information Protection
> solution) — though DLP can *use* those labels as a condition. The three are complementary; this
> solution delivers the DLP half for SharePoint and OneDrive.

## Why this matters
- **A share link is an exfiltration path.** "Share with anyone" turns an internal document into a public
  one with one click. DLP inspects the content and can stop the share when the document is sensitive.
- **Content beats location as a control.** A site's permissions don't know what's inside its documents.
  DLP matches on the actual sensitive information, so a customer-PII spreadsheet is protected wherever it
  lands.
- **Policy tips change behavior.** A tip at the moment of sharing ("this document contains customer data
  — sharing externally is restricted") stops mistakes before they happen and trains users over time.
- **It is defensible and auditable.** "SharePoint/OneDrive documents containing regulated data cannot be
  shared externally, and every match is logged" is a statement you can evidence with a policy and its
  reports, not a hope.

## How it works
1. **Assess.** Read the tenant's current state — existing **DLP policies and rules**, which locations they
   cover, and the **sensitive information types** and labels available to match on — all read-only.
2. **Design.** With compliance/security, decide which **sensitive content** to detect, which **sharing
   actions** to govern (external sharing, "everyone" sharing, external access), the **actions** (restrict
   access, block sharing, notify, policy tip), and the **exceptions** — aligned to the classification
   intent your stakeholders set.
3. **Configure.** Create the **`SPO-OneDrive DLP – Policy`** with its rule(s) in Purview, scoped to the
   pilot, **in test mode** (no enforcement yet).
4. **Pilot.** Run the policy in **test/simulation mode** on the pilot sites — never enforcing on day one —
   and review what it *would* match and block on real content. DLP enforcement is **high-impact** for
   collaboration; prove the matches first.
5. **Validate.** Confirm the policy matches the intended sensitive content and share conditions, that
   policy tips and admin alerts fire, and that false positives are tuned out — against the pass/fail
   gates.
6. **Expand.** Move the policy from test to **enforce** once validated and stakeholders approve, broaden
   the scope to all intended locations, and hand ongoing tuning and reporting to operations.

## The DLP design (used throughout)
Names below are examples; the **determination** of which content is sensitive and which sharing to block
belongs to your compliance, security, and privacy stakeholders — this solution provides the technical
implementation.

| Element | Design intent |
|---|---|
| DLP policy | `SPO-OneDrive DLP – Policy` (SharePoint + OneDrive locations) |
| Detection rule | `SPO DLP – External Sharing Rule` — sensitive info type/label + shared-externally condition |
| Actions | Restrict access / block external sharing, notify the user (policy tip), alert admins |
| Mode | **Test (with/without policy tips) during pilot; Enforce after validation** |
| Pilot scope | `SPO DLP – Pilot Sites – Stage1` — limited sites/OneDrive accounts |
| Scope/design map | `DLP Scope – Map` |
| Coverage report | `SPO DLP – Coverage Report` |

> **Licensing / plan note — verify against your own tenant.** DLP for SharePoint/OneDrive/Exchange is
> included with **Microsoft 365 E3**; some advanced DLP capabilities (certain classifiers, richer
> conditions) require **E5 / E5 Compliance**. Confirm the exact capability availability, the sensitive
> information types, and portal paths for *your* tenant in Microsoft's documentation before you design —
> the DLP surface is evolving. Where a capability is unavailable, scope to what your plan supports and
> record the rest as **deferred**.

## What you get
- This **Solution Overview**, a **Requirements Guide** (every prerequisite with verify /
  implement-if-missing), a precise **Implementation Guide**, a **Testing Guide** with pass/fail gates, a
  **Troubleshooting Guide**, and field-proven **Best Practices**.
- **Five PowerShell tools** — Discovery, a prerequisite/health helper, a safe Configuration/Remediation
  tool (`-WhatIf` by default; creates in test mode), Validation, and Reporting — built on Security &
  Compliance PowerShell, **read-only or `-WhatIf` by default and with no credentials in code**.

> **Boundary.** Which content is sensitive, which sharing is acceptable, and any regulatory obligation on
> the data are **determinations owned by your compliance, security, and privacy functions**. This
> solution provides the technical configuration and the evidence — and never enforces before you validate
> in test mode — not the determination.


---


# 2. Requirements Guide — SharePoint Online DLP (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 DLP licensing (E3 baseline; E5 for advanced)
**Description:** A tenant licensed for **Data Loss Prevention** for SharePoint/OneDrive — **Microsoft 365
E3** includes DLP for Exchange/SharePoint/OneDrive/Teams; some advanced DLP capabilities (certain
classifiers, richer conditions) require **E5 / E5 Compliance**. (Global Requirement 1.)
**Why:** Core content/sharing DLP works on E3; specific advanced conditions/classifiers are plan-gated.
**Verify:** M365 admin center → `Billing → Licenses`; in the Purview portal confirm **Data Loss
Prevention → Policies** is available. `DLPSPO-Check-Prereqs.ps1` reports the DLP signal. **Verify against
your own plan.**
**Implement:** Assign the required licensing; where an advanced capability is unavailable, scope to what
your plan supports and record the rest as **deferred**.

## 2.2 Least-privilege DLP/compliance role
**Description:** A least-privilege role that can manage DLP — **Compliance Administrator**,
**Compliance Data Administrator**, or the **DLP Compliance Management** role group — in the Purview
portal. Reserve **Global Administrator** for one-time enablement only. (Global Requirement 2.)
**Why:** Creating/editing DLP policies and rules requires the matching role; DLP enforcement is
high-impact, so least privilege matters.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows the DLP/compliance role;
`Connect-IPPSSession` succeeds and `Get-DlpCompliancePolicy` runs.
**Implement:** Assign the least-privilege role under change control; do not use Global Administrator for
day-to-day DLP authoring.

## 2.3 Security & Compliance PowerShell toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (provides `Connect-IPPSSession` for
`Get-/New-/Set-DlpCompliancePolicy` and `...Rule`, and `Get-DlpSensitiveInformationType`), with a
modern-auth / MFA admin. (Global Requirement 3.)
**Why:** DLP policies/rules and sensitive information types are read/authored through Security &
Compliance PowerShell; the provided scripts run there.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` succeeds and
`Get-DlpCompliancePolicy` returns. `DLPSPO-Check-Prereqs.ps1` reports module/connection state.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in
before running steps.

## 2.4 The sensitive content and sharing to govern (compliance owned)
**Description:** The **sensitive information types / sensitivity labels / keywords** the policy must
detect, and the **sharing actions** to govern (external sharing, "everyone" sharing, external access),
translated into rule conditions and owned/signed off by **compliance/security/privacy**. (Global
Requirements 4 & 5.)
**Why:** DLP acts on the content and actions you define; which content is sensitive and which sharing is
unacceptable is a business/compliance **determination**, not a technical default.
**Verify:** The in-scope sensitive info types/labels and the sharing conditions are documented and
approved; named approvers recorded in `DLP Scope – Map`.
**Implement:** Confirm the sensitive info types and sharing conditions before authoring rules; where the
determination is incomplete, run in **test mode** and defer enforcement until agreed.

## 2.5 In-scope SharePoint/OneDrive locations and a pilot scope
**Description:** The **SharePoint sites and OneDrive accounts in scope**, and a **limited pilot scope**
(`SPO DLP – Pilot Sites – Stage1`) to validate on before enforcing tenant-wide. (Global Requirements 4 &
6.)
**Why:** DLP keys off the in-scope locations; the wrong scope either misses content or over-blocks
collaboration.
**Verify:** `DLPSPO-Discover.ps1` reports existing policies and covered locations; confirm the intended
in-scope and pilot locations with SharePoint/compliance owners.
**Implement:** Enumerate the in-scope sites/accounts and define the pilot scope before configuring.

## 2.6 Test/simulation mode understood and used
**Description:** Understanding that DLP policies support **test mode** (test with policy tips / test
without policy tips) and **enforce** mode, and the discipline to **start in test mode** so the policy's
matches and would-be blocks are reviewed on real content before enforcement.
**Why:** DLP enforcement blocks real sharing; a mistuned policy generates help-desk tickets and blocks
legitimate work. Test mode reveals the impact first.
**Verify:** Confirm test mode is available (it is, for DLP) and that the plan starts in test mode;
`DLPSPO-Validate.ps1` reports the policy's current mode.
**Implement:** Create the policy in **test mode**; move to enforce only after validation and approval.

## 2.7 Notification/alert design and exceptions
**Description:** The **policy-tip text**, **user notification**, and **admin alert** design, plus the
**exceptions** (sites, groups, or conditions that should not match), agreed with stakeholders.
**Why:** Policy tips educate users and alerts drive response; well-chosen exceptions prevent
false-positive friction. These are part of a usable DLP policy, not an afterthought.
**Verify:** The tip text, notification/alert recipients, and exceptions are documented in
`DLP Scope – Map`.
**Implement:** Define the notifications and exceptions before enforcing; tune them during the test-mode
pilot.

---
## Checklist
- [ ] DLP licensing confirmed (E3 baseline; E5 for advanced classifiers/conditions, else deferred)
- [ ] Compliance/DLP-management role assigned least-privilege
- [ ] ExchangeOnlineManagement installed; `Connect-IPPSSession` succeeds; `Get-DlpCompliancePolicy` runs
- [ ] Sensitive info types/labels + sharing conditions to govern documented and approved
- [ ] In-scope SharePoint/OneDrive locations enumerated; `SPO DLP – Pilot Sites – Stage1` defined
- [ ] Test/simulation mode understood; plan **starts in test mode**
- [ ] Policy-tip text, notifications/alerts, and exceptions designed and captured in `DLP Scope – Map`


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — SharePoint Online DLP (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot (test mode) → Validate →
Expand (enforce)**. Every write is **created in test mode on `SPO DLP – Pilot Sites – Stage1` first**,
previewed with `-WhatIf`, and reversible. Named objects are introduced once and reused everywhere:

| Object | Name |
|---|---|
| DLP policy | `SPO-OneDrive DLP – Policy` |
| Detection rule | `SPO DLP – External Sharing Rule` |
| Pilot scope | `SPO DLP – Pilot Sites – Stage1` |
| Scope/design map | `DLP Scope – Map` |
| Coverage report | `SPO DLP – Coverage Report` |

> **Test mode first, always.** A DLP policy in **test mode** matches content and shows what it *would*
> block (with or without policy tips) but **enforces nothing**. Only **enforce** mode restricts real
> sharing. This solution creates the policy in test mode and moves to enforce as a deliberate, approved
> step. **Verify capability availability (info types, conditions) against your licensing/tenant.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-IPPSSession                 # Security & Compliance PowerShell (DLP policies + rules)
```
Keep credentials out of scripts — sign in interactively. **Pass/fail:** the connection succeeds and
`Get-DlpCompliancePolicy` returns without error.

## Step 1 — Assess current state (Assess)
1. Run `DLPSPO-Discover.ps1`. Read-only, it reports every **DLP policy and rule**, whether each covers
   **SharePoint** and/or **OneDrive**, each policy's **mode** (test/enforce), and the available
   **sensitive information types** to match on.
2. Run `DLPSPO-Check-Prereqs.ps1` — module/connection, the DLP/role signals, and existing policies —
   PASS/GAP per signal.
3. Record every GAP and remediate before configuring. **Pass/fail:** the inventory and prereq report
   complete; existing coverage/overlap captured in `DLP Scope – Map`.

## Step 2 — Design the DLP policy (Design)
1. With compliance/security, choose the **sensitive information types / labels / keywords** to detect, the
   **sharing conditions** to govern (shared externally, shared with everyone, accessible by external
   users), the **actions** (restrict access / block external sharing, notify with a policy tip, alert
   admins), and the **exceptions**.
2. Define `SPO DLP – Pilot Sites – Stage1` and the notification/alert recipients. Record everything in
   `DLP Scope – Map`.
3. Confirm which info types/conditions your licensing supports; mark any unsupported condition
   **deferred**.
   **Pass/fail:** `DLP Scope – Map` is agreed and signed off; which content is sensitive and which sharing
   to block is owned by stakeholders, not IT.

## Step 3 — Create the policy in test mode (Configure)
Do this **for the pilot scope first**, and **in test mode** — no enforcement yet.

1. **Create the policy + rule (test mode).** Preview then commit:
   ```powershell
   .\DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -WhatIf
   .\DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -Commit
   ```
   This creates `SPO-OneDrive DLP – Policy` scoped to the pilot sites (and OneDrive where designed) with
   `SPO DLP – External Sharing Rule`, in **test-without-notifications** mode by default (change to
   test-with-tips as designed). Verify with `Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`.
2. **Complete tip/notification/exception detail in the portal.** Purview portal → **Data Loss Prevention →
   Policies** → the policy → confirm the rule conditions, policy-tip text, notifications, alerts, and
   exceptions match `DLP Scope – Map`.
   **Pass/fail:** the policy exists in **test mode**, covers exactly the pilot scope, and its rule matches
   the intended sensitive content + sharing condition — enforcing nothing.

## Step 4 — Pilot in test mode (Pilot)
1. Let the policy run in test mode on the pilot sites. Generate representative activity — upload a
   document containing the sensitive info type; share it externally.
2. Review what the policy **would** match and block (DLP reports / activity explorer) and where **policy
   tips** would show. Tune conditions and exceptions to remove false positives.
   **Pass/fail:** the policy matches the intended content and share conditions in test mode with an
   acceptable false-positive rate; discrepancies are recorded for troubleshooting, not worked around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `DLPSPO-Validate.ps1`. Read-only, it confirms `SPO-OneDrive DLP – Policy` exists, covers the
   intended locations, its rule matches the intended sensitive content/sharing condition, and the policy
   is in **test mode** (not prematurely enforcing) — PASS/FAIL per gate.
2. Confirm policy tips and admin alerts behave as designed on a real test share.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `SPO DLP – Pilot Sites – Stage1`.

## Step 6 — Enforce and expand (Expand)
1. **Move to enforce deliberately** — only after test-mode is validated and stakeholders approve:
   ```powershell
   .\DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -WhatIf
   .\DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -Commit
   ```
   This switches `SPO-OneDrive DLP – Policy` to **Enable** (enforce). Communicate the change to users
   first; enforcement blocks real sharing.
2. **Expand the scope** to all intended SharePoint/OneDrive locations once validated.
3. Run `DLPSPO-Report.ps1 -CsvPath .\SpoDlpReport.csv` to produce `SPO DLP – Coverage Report` — each
   policy/rule, its locations, mode, and match conditions — as the management evidence artifact, and re-run
   it on a schedule.
   **Pass/fail:** the policy is in enforce mode at the intended scope; the report shows coverage and mode
   as designed.

---
### Rollback
- **Return to test mode** with `DLPSPO-Set-DlpPolicy.ps1 -Action Test -Commit` (or
  `Set-DlpCompliancePolicy ... -Mode TestWithoutNotifications`) to stop enforcement immediately while
  keeping the policy for tuning.
- **Disable / delete the policy** (`Set-DlpCompliancePolicy ... -Mode Disable`, or remove it) to stop it
  entirely.
- **Narrow the scope** back to the pilot to reduce blast radius, or add an **exception** to release a
  false-positive site/group. Keep `DLP Scope – Map` as the record of the intended state.

### Order of operations
`Assess policies + info types → design content + sharing + actions + exceptions → create policy in test
mode on pilot → pilot + tune in test mode → validate → enforce deliberately (approved) → expand scope →
report coverage`


---


# 5. Testing Guide — SharePoint Online DLP (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to generate representative activity on a pilot site — and the policy is in **test mode**, so no
real sharing is blocked. Validate on `SPO DLP – Pilot Sites – Stage1` before enforcing or expanding.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `DLPSPO-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement present and connected; the DLP/compliance role reported; the DLP
capability signal reported; existing policies listed. Every gap (e.g. an advanced classifier unavailable →
deferred) is **recorded, not guessed**.

## Test 2 — Discovery inventory is complete
**Do:** Run `DLPSPO-Discover.ps1`.
**Expected:** Every DLP policy and rule is listed with whether it covers **SharePoint** and/or
**OneDrive**, each policy's **mode** (test/enforce), and the available **sensitive information types** —
matching the Purview portal.

## Test 3 — Create dry-run makes no changes
**Do:** Run `DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -WhatIf`.
**Expected:** It states the policy/rule/scope it *would* create (test mode) plus the reverse action and
changes nothing; a follow-up `Get-DlpCompliancePolicy` shows no new policy until `-Commit`.

## Test 4 — Policy exists in test mode, scoped to the pilot
**Do:** After `-Commit`, run `Get-DlpCompliancePolicy -Identity "SPO-OneDrive DLP - Policy"` and
`Get-DlpComplianceRule`.
**Expected:** The policy exists, covers exactly the pilot locations (SharePoint and/or OneDrive as
designed), its rule matches the intended sensitive info type + sharing condition, and the mode is
**test** (e.g. TestWithoutNotifications) — enforcing nothing.

## Test 5 — The rule matches the intended sensitive content
**Do:** Upload a test document containing the sensitive info type (e.g. a fake credit-card number in the
correct format) to a pilot site.
**Expected:** The DLP reports / Activity Explorer show a **match** for the document in test mode — the
policy detects the content it was designed to detect.

## Test 6 — The sharing condition is evaluated
**Do:** Share the matching test document **externally** from a pilot site.
**Expected:** In test mode the policy records what it **would** restrict (and where a **policy tip** would
appear) for the external-sharing condition — without blocking the share.

## Test 7 — Validation gate passes on the pilot (test mode)
**Do:** Run `DLPSPO-Validate.ps1`.
**Expected:** PASS for each gate — the policy exists, covers the intended locations, the rule matches the
intended content/sharing condition, and the policy is in **test mode** (not prematurely enforcing). Any
FAIL names the specific issue.

## Test 8 — False positives are tuned out
**Do:** Review test-mode matches for legitimate documents that shouldn't match; add an **exception** or
tighten the condition; re-review.
**Expected:** After tuning, legitimate content no longer matches while the intended sensitive content
still does — an acceptable false-positive rate before enforcement.

## Test 9 — Enforce dry-run makes no changes and is reversible
**Do:** Run `DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -WhatIf`.
**Expected:** The dry-run states it *would* switch the policy to **enforce** plus the reverse action (back
to test) and changes nothing; a follow-up `Get-DlpCompliancePolicy` shows the mode unchanged.

## Test 10 — Enforcement blocks as designed (deliberate, after approval)
**Do:** Only after validation and approval: enforce with `-Commit`, then attempt to share a matching
document externally from an in-scope site as a normal user.
**Expected:** The external share is **restricted/blocked** per the rule, the user sees the **policy tip**,
and an **admin alert** fires. An authorized/excepted case still works. (Verify against your configuration.)

## Test 11 — Reporting evidence is produced
**Do:** Run `DLPSPO-Report.ps1 -CsvPath .\SpoDlpReport.csv`.
**Expected:** `SPO DLP – Coverage Report` lists each policy/rule, its SharePoint/OneDrive locations, mode,
and match conditions — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `SPO DLP – Pilot Sites – Stage1` — policy present in test mode, matching the intended
content and sharing conditions with false positives tuned out, policy tips and alerts behaving as designed
— before moving to enforce or expanding. Enforcement is enabled only as a deliberate, approved step; any
deferred (licensing-gated) capability is recorded explicitly, not silently skipped.


---


# 6. Troubleshooting — SharePoint Online DLP (Microsoft Purview)

Symptoms, likely causes, and fixes for SharePoint/OneDrive DLP. Stay in **test mode** while diagnosing —
reproduce on `SPO DLP – Pilot Sites – Stage1` before enforcing or expanding, and never flip a policy to
enforce to "test" a theory.

## The policy matches nothing / no matches in reports
- **Propagation delay.** New DLP policies take time (often up to ~1 hour, longer at scale) to activate and
  begin evaluating. Confirm the policy exists and wait before concluding failure.
- **Wrong sensitive info type / too-high count.** Verify the exact SIT name (`DLPSPO-Discover.ps1` lists
  them) and that your test content actually matches it in the right format, and that `minCount` isn't set
  higher than your test document contains.
- **Location not in scope.** Confirm the site/account is in the policy's SharePoint/OneDrive locations.
- **Test content not indexed yet.** DLP evaluates on content processing; a just-uploaded document may not
  be evaluated instantly. Wait and re-check the reports.

## The policy blocks legitimate content (false positives)
- **Condition too broad.** Tighten the sensitive info type (raise confidence/count) or add supporting
  conditions so common formats don't trigger it.
- **Add an exception.** Except the site/group/condition that legitimately holds the content, or scope the
  policy away from it. This is expected tuning — do it in **test mode** before enforcing.
- **Still in test mode?** If you're seeing *would-block* entries, that's test mode reporting impact, not a
  live block — which is exactly the point of piloting in test mode first.

## Enforcement is blocking users unexpectedly
- **Enforced too early.** Enforcement should follow a validated test-mode pilot. If a policy is blocking
  legitimate work, return it to test mode immediately: `DLPSPO-Set-DlpPolicy.ps1 -Action Test -Commit` (or
  `Set-DlpCompliancePolicy ... -Mode TestWithoutNotifications`), then tune.
- **Missing exception.** A legitimate case wasn't excepted. Add the exception, re-validate in test mode,
  then re-enforce.

## Policy tips don't appear
- **Notifications off / wrong mode.** Policy tips show in **enforce** mode and **test-with-notifications**
  mode, not in test-without-notifications. Confirm the mode and that the rule's user notification / policy
  tip is enabled.
- **Tip text not configured.** Complete the policy-tip text in the portal (it isn't asserted by the
  script). Verify the rule's notification settings.
- **Client/surface support.** Tip display varies by surface (SharePoint web, sync client, Office). Verify
  the specific surface supports tips for the scenario.

## `DLPSPO-Set-DlpPolicy.ps1 -Commit` fails
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded
  (`Get-Command Get-DlpCompliancePolicy` resolves).
- **Insufficient role.** Creating DLP policies needs Compliance Administrator / DLP Compliance Management.
  Confirm in Purview → Roles & scopes / Permissions.
- **Parameter shape by module version.** `-ContentContainsSensitiveInformation`, `-AccessScope`, and
  `-Mode` values vary across ExchangeOnlineManagement versions. Verify against your version; update the
  module if it's far behind.
- **Bad SIT name.** A name in `-SensitiveTypes` must exactly match a `Get-DlpSensitiveInformationType`
  entry. Copy the exact `Name`.

## `DLPSPO-Validate.ps1` reports the mode wrong or a property mismatch
- **Module-version property shape.** Location and mode properties are exposed under different names across
  module versions. Confirm the intended state in the portal (Data Loss Prevention → the policy) and treat
  the validator line as informational where the portal disagrees; note the module version.

## OneDrive isn't covered even though I set it
- **OneDrive location value.** OneDrive is scoped as `All` (or by account) separately from SharePoint.
  Confirm `-IncludeAllOneDrive` was used (or the OneDrive location is set in the portal) and that the
  policy's OneDrive location is populated in `DLPSPO-Discover.ps1`.

---
### When to stop and escalate
- A required capability is unavailable on your licensing/tenant (an advanced classifier/condition) —
  record it **deferred** and route the licensing decision to the owner; do not design around an
  unavailable feature.
- **Which content is sensitive and which sharing is acceptable** is a stakeholder determination
  (compliance/security/privacy), not a technical fix — capture it in `DLP Scope – Map` and defer the
  determination.
- If match or enforcement behavior can't be reconciled with the policy, keep it in test mode on the pilot,
  gather `DLPSPO-Validate.ps1` + `DLPSPO-Report.ps1` output as evidence, and raise with Microsoft support
  before enforcing or expanding.


---


# 7. Best Practices — SharePoint Online DLP (Microsoft Purview)

- **Test mode first; enforce deliberately.** The single most important discipline: create every DLP policy
  in **test mode**, review what it *would* match and block on real content, tune it, and enforce only
  after approval. Enforcing an untuned policy blocks legitimate collaboration and fills the help desk.
- **Match on content, not just location.** DLP's value is inspecting what a document *contains* — sensitive
  information types, labels, keywords. Lead with content conditions so a customer-PII document is protected
  wherever it lands, not just in one locked-down site.
- **Which content is sensitive is a compliance determination.** The sensitive info types, labels, and
  sharing conditions come from compliance/security/privacy. Configure the rules they specify; capture the
  determinations and approvers in `DLP Scope – Map`.
- **Use policy tips to teach, not just block.** A tip at the moment of sharing ("this document contains
  regulated data — external sharing is restricted") prevents mistakes and trains users. Design the tip
  text deliberately; it's the most visible part of the policy.
- **Tune false positives before enforcing.** Every false positive that blocks legitimate work erodes trust
  in DLP. Use the test-mode pilot to find and except them (or tighten conditions) so enforcement lands on
  real sensitive content only.
- **Right-size the sharing conditions.** "Block all external sharing everywhere" is rarely the intent; the
  intent is usually "don't let *sensitive* content be shared externally." Combine the content condition
  with the sharing condition so the block is targeted.
- **Pilot on a limited scope first.** Prove the policy on `SPO DLP – Pilot Sites – Stage1` before scoping
  to the estate. Match behavior and false-positive rates are easier to reason about on a bounded scope.
- **Coordinate with sensitivity labels and lifecycle.** DLP can *use* a sensitivity label as a condition,
  and it complements — but doesn't replace — retention/cleanup and item labeling. Deploy them together and
  keep each doing its own job.
- **Design notifications and alerts, not just blocks.** User notifications, admin alerts, and incident
  reports are what make DLP operable. Decide recipients and thresholds up front so a match produces a
  response, not just a log line.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; enforcement behind its own explicit `-Action Enforce`.
  Sign in interactively; no credentials or secrets in a script or a document.
- **Re-report and re-tune on a schedule.** New sensitive content and sharing patterns appear constantly.
  Re-run `DLPSPO-Report.ps1` and review matches periodically so `SPO DLP – Coverage Report` stays a live
  evidence artifact and the policy stays accurate.
- **Keep determinations with their owners.** The solution configures and evidences DLP; which content is
  sensitive, which sharing is acceptable, and any regulatory obligation are determinations for compliance,
  security, and privacy. Keep that separation explicit.


---


# 8. Deliverables Summary — SharePoint Online DLP (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | SharePoint/OneDrive DLP for sensitive content and sharing/external access; test mode first, enforce deliberately; how DLP differs from labels and lifecycle (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess policies, design content + sharing + actions, create the policy in test mode on the pilot, pilot + tune, validate, enforce deliberately, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| DLP policy | `SPO-OneDrive DLP – Policy` |
| Detection rule | `SPO DLP – External Sharing Rule` |
| Pilot scope | `SPO DLP – Pilot Sites – Stage1` |
| Scope/design map | `DLP Scope – Map` |
| Coverage report | `SPO DLP – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLPSPO-Discover.ps1` | Reports current state: every DLP policy and rule, whether each covers SharePoint/OneDrive, each policy's mode (test/enforce), and the available sensitive information types — Security & Compliance PowerShell; read-only |
| `DLPSPO-Check-Prereqs.ps1` | Prerequisite/health helper: module, connection, the DLP/compliance role signal, and existing policies — PASS/GAP per signal; read-only |
| `DLPSPO-Set-DlpPolicy.ps1` | Configuration/Remediation: creates `SPO-OneDrive DLP – Policy` + `SPO DLP – External Sharing Rule` scoped to the pilot **in test mode** (`-Action CreatePolicy`), and — as deliberate separate steps — switches to **enforce** (`-Action Enforce`) or back to **test** (`-Action Test`); **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; no secrets in code |
| `DLPSPO-Validate.ps1` | Validation: PASS/FAIL that the policy exists, covers the intended locations, its rule matches the intended content/sharing condition, and the policy is in **test mode** (not prematurely enforcing) — read-only |
| `DLPSPO-Report.ps1` | Coverage report — each policy/rule, its SharePoint/OneDrive locations, mode, and match conditions — written to CSV as `SPO DLP – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
SharePoint and OneDrive sharing governed from Purview — documents inspected for sensitive content and
external sharing restricted where the content warrants it — proven in test mode on a limited pilot before
any enforcement, with the determination of which content is sensitive and which sharing is acceptable left
to the compliance, security, and privacy owners who make it.
