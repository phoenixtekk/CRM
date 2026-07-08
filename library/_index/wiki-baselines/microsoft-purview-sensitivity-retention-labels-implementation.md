# Microsoft Purview Sensitivity & Retention Labels — Implementation

> **Version 1.0.0** · Category: Purview · Solution code: PURVLABEL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview Sensitivity & Retention Labels (Implementation)

## The problem
Labels are how Microsoft Purview classifies, protects, and governs content — but a bad taxonomy or a
careless auto-labeling rollout breaks user trust fast. Organizations either leave content unlabeled
(no protection, no retention, no way to enforce DLP or encryption) or roll labels out too aggressively
and drown in mislabeling, surprise encryption, and unexpected deletions. Either way the investment in
Purview fails to deliver classified, governed content.

## The solution
A complete, self-guided implementation of **sensitivity and retention labels** — the deep build, not a
broad baseline. It delivers a workable **label taxonomy**, **sensitivity labels with protection**
(encryption, content marking, access control) and publishing policies, **auto-labeling** (client-side
and service-side), and **retention labels** with label policies scoped by **adaptive scopes** — every
high-impact change **piloted in simulation/test before enforcement**, so content is classified and
governed without disrupting users. It uses only the Microsoft Purview portal and Security & Compliance
PowerShell — no third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand (enforce).** Assess the current label posture; design a signed-off taxonomy; build
and publish sensitivity labels to a **pilot ring**; configure service-side auto-labeling **in
simulation** and validate its precision before ever enforcing; build retention labels and **adaptive
scopes**; publish retention to a pilot and then by adaptive scope; validate end to end; then expand
tenant-wide. Five PowerShell tools — read-only or `-WhatIf` by default — automate discovery,
configuration, the simulation match report, and health checks.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five Security & Compliance PowerShell tools: posture assessment, sensitivity-label/publish/auto-label config helper, simulation match report, retention-label/adaptive-scope config helper, and a scope/health helper.
- A named, gated, reversible rollout with explicit pass/fail criteria at every step.

## Business outcome
Content **classified and governed by design** — a sound label taxonomy, sensitivity protection that
travels with the file, auto-labeling proven in simulation before it touches real content, and
retention applied automatically by adaptive scope. Protection and governance **without the user
revolt** — at a fraction of the cost of a bespoke consulting engagement.

## Important boundaries
Retention schedules, records declarations, file plans, and legal holds are **determinations owned by
your records, compliance, privacy, and legal functions** — this solution provides the technical
configuration method and evidence, not the determination. Several capabilities (service-side
auto-labeling, adaptive scopes) are **licensing-dependent** (E5 / E5 Compliance) and the Purview
portal is evolving — availability and paths are flagged "verify your licensing/tenant," never assumed.


---


# 1. Solution Overview — Microsoft Purview Sensitivity & Retention Labels (Implementation)

## What this solution is
Sensitivity and retention labels are how Microsoft Purview **classifies, protects, and governs**
content across Microsoft 365. A **sensitivity label** marks how sensitive an item is and can apply
*protection* — encryption, content marking (header/footer/watermark), and access control. A
**retention label** marks how long an item must be kept (and what happens at the end) so content is
retained or disposed by policy rather than by accident. This solution is a repeatable way to design a
workable **label taxonomy**, build and publish sensitivity labels with protection, turn on
**auto-labeling** (client-side and service-side) **in simulation first**, and stand up **retention
labels** and label policies scoped with **adaptive scopes** — all piloted in simulation/test before
enforcement, using only the Microsoft Purview portal and Security & Compliance PowerShell (no
third-party tooling).

This is the **deep implementation** build for labels specifically — the detailed taxonomy,
protection, publishing, auto-labeling, and retention-label configuration — distinct from a broad
Purview foundation baseline.

## Why this matters
- Labels are the backbone of information protection: DLP, encryption, and data lifecycle all key off them. A weak or inconsistent taxonomy undermines every downstream control.
- Protection applied through a sensitivity label (encryption + rights) **travels with the file** — it stays enforced when content leaves the tenant, unlike a location-only control.
- A careless auto-labeling rollout — mislabeling, surprise encryption, or unexpected deletion from a retention label — breaks user trust fast and generates a flood of tickets. Simulation-first is what makes it safe.
- Retention labels with **adaptive scopes** target the *right* content by attribute (department, location, site property) and re-evaluate membership automatically, so governance keeps pace with the organization instead of drifting.

## The two label types (and where they apply)
| | **Sensitivity label** | **Retention label** |
|---|---|---|
| Answers | *How sensitive is this?* | *How long must we keep this?* |
| Can apply | Encryption, content marking, access control, container settings | Retain, then delete / trigger disposition review / mark as record |
| Applied by | User, client-side auto-label, service-side auto-label | User, service-side auto-apply, or auto-applied by policy |
| Published via | **Sensitivity label policy** (`New-LabelPolicy`) | **Retention label policy** (`New-RetentionCompliancePolicy` + rule) |
| Scoping | Users/groups (label policy) | Static locations **or adaptive scopes** |

## Auto-labeling: client-side vs service-side
- **Client-side auto-labeling** runs in the Office apps (Word/Excel/PowerPoint/Outlook) as the user works. It *recommends* or *automatically applies* a sensitivity label based on conditions configured on the label and surfaced through the label policy. It only affects newly edited content on that client.
- **Service-side auto-labeling** runs in the service across **data at rest** (SharePoint, OneDrive) and **data in transit** (Exchange email). It is configured as an **auto-labeling policy** and, critically, is **run in *simulation* first** — it scans and reports what *would* be labeled without applying anything, so you validate accuracy before enforcing.
- Service-side auto-labeling is **licensing-dependent** (typically Microsoft 365 E5 / E5 Compliance) — **verify your licensing/tenant** before relying on it.

## Adaptive scopes (for retention)
An **adaptive scope** is a dynamic membership query (User, Group, or Site) — e.g. "all users where
Department = Finance" or "all sites where a custom property = Records". A retention policy bound to an
adaptive scope automatically re-evaluates membership on a schedule, so newly matching users/sites are
covered without editing the policy. Adaptive scopes are the recommended alternative to static scopes
for anything that changes over time. Availability/behavior is **licensing- and tenant-dependent** —
**verify your licensing/tenant.**

## Sample label taxonomy (starting point — confirm with your governance owners)
> The taxonomy below is a **technical starting point**; the final label names, protection settings,
> and retention periods are a **records/legal/compliance determination** (see §2 and the deferral
> note). Names here are reused verbatim across the docs and scripts.

**Sensitivity labels (ordered least → most sensitive):**

| Label | Protection |
|---|---|
| `Public` | None — marking only |
| `General` | None — internal marking (footer) |
| `Confidential` (parent) | — grouping only |
| `Confidential \ All Employees` | Encrypt, all internal users, content marking |
| `Confidential \ Trusted People` | Encrypt, specified people, Do-Not-Forward-style rights |
| `Highly Confidential` (parent) | — grouping only |
| `Highly Confidential \ All Employees` | Encrypt + watermark, all internal users |
| `Highly Confidential \ Specified People` | Encrypt, named recipients only, no export |

**Retention labels (periods are placeholders — set by records/legal):**

| Label | Action (to confirm) |
|---|---|
| `Business-General-3yr` | Keep 3 years from modification, then start disposition review |
| `Financial-Records-7yr` | Keep 7 years from creation |
| `Transitory-1yr` | Delete 1 year after creation |
| `Legal-Reference` | Retain, no automatic deletion |

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Type> <Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal:

| Artifact | Name |
|---|---|
| Sensitivity label policy (pilot) | `SL Policy – Pilot – Ring1` |
| Sensitivity label policy (broad) | `SL Policy – Broad – AllUsers` |
| Service-side auto-labeling policy (simulation) | `AL Sim – Financial – SPO+ODB` |
| Service-side auto-labeling policy (email, simulation) | `AL Sim – Financial – Exchange` |
| Retention label policy (pilot) | `RL Publish – Pilot – Ring1` |
| Retention label policy (adaptive) | `RL Publish – Adaptive – FinanceUsers` |
| Adaptive scope (users) | `Scope – Users – Finance` |
| Adaptive scope (sites) | `Scope – Sites – Records` |

## What you can control
- The label taxonomy — names, order, parent/sublabel structure, tooltips.
- Which labels carry protection, and the exact encryption/marking/rights on each.
- Who each sensitivity label policy targets (pilot ring first, then broad).
- Auto-labeling conditions (sensitive info types, keywords, trainable classifiers) — run in simulation, tuned, then enforced.
- Retention label periods and actions (subject to records/legal sign-off) and the adaptive scopes that target them.

## Limitations (be honest with buyers)
- **Licensing gates capability.** Service-side auto-labeling, some adaptive-scope behavior, and certain classifier features require **E5 / E5 Compliance** — **verify your licensing/tenant**; the solution flags each gate rather than assuming.
- **Records, retention schedules, and legal holds are determinations, not technical defaults** — the specific retention periods, records declarations, and hold decisions come from records/legal (see the deferral note in §2). This solution provides the configuration method and evidence.
- **Encryption is high-impact.** A published label that encrypts can block co-authoring, third-party tools, and downstream automation if applied carelessly — always pilot in a small ring first.
- **Auto-labeling has latency and quotas.** Simulation and enforcement scan large volumes over time; results are not instantaneous, and item/throughput limits apply — **verify current limits for your tenant.**
- **The portal is evolving.** Portal paths and some cmdlet parameters change; where a path is version-sensitive it is flagged "verify in your tenant."

## The standard deployment model
> Assess the current label posture → design the taxonomy → build + publish sensitivity labels to a
> **pilot ring** → configure auto-labeling in **simulation** → validate accuracy → build retention
> labels + adaptive scopes → validate → **expand and enforce** tenant-wide.
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**


---


# 2. Requirements Guide — Sensitivity & Retention Labels (Implementation)

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for building sensitivity and retention labels; they build on the
shared **Global Requirements — Microsoft Purview Solutions** (licensing, least-privilege roles,
Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal
stakeholders, and a pilot scope with change control). Read the Global Requirements first; this guide
does not repeat them.

> **Deferral note (records/legal).** The **retention periods, disposition actions, records
> declarations, and any legal holds** referenced here are **determinations owned by your records,
> compliance, privacy, and legal functions** — not technical defaults. This solution provides the
> **configuration method and evidence**; it does not decide the schedule. Confirm every period and
> action with the accountable owner before enforcing.

---

## 2.1 Licensing for labels, protection, and auto-labeling
- **Description:** Manual sensitivity labels, content marking, and encryption are available broadly (Microsoft 365 E3 tier covers manual sensitivity labeling and encryption). **Client-side automatic labeling** and **service-side auto-labeling** for SharePoint/OneDrive/Exchange, along with several advanced classifiers, require **Microsoft 365 E5** or the **E5 Compliance** add-on. Retention labels and retention label policies are available at E3; **adaptive scopes** and advanced retention features are E5-tier.
- **Why required:** The auto-labeling and adaptive-scope steps in this solution will not be available without the right plan.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the relevant feature is visible in the Purview portal (Information Protection → *Auto-labeling*; Data Lifecycle Management → *Adaptive scopes*). **Verify your licensing/tenant** — Microsoft's licensing tables are the authority.
- **How to implement if missing:** Assign/purchase E5 or E5 Compliance for the pilot users before configuring auto-labeling; you can still implement manual labels + publishing at E3.

## 2.2 Information Protection & Records Management roles (least privilege)
- **Description:** The Purview role groups this solution needs: **Information Protection Admin** (create/manage sensitivity labels and label policies and auto-labeling), and **Records Management** or **Compliance Administrator** (create/manage retention labels, retention policies, and adaptive scopes). Global Administrator is **not** required for day-to-day label work.
- **Why required:** Sensitivity-label cmdlets (`New-Label`, `New-LabelPolicy`, `New-AutoSensitivityLabelPolicy`) and retention cmdlets (`New-ComplianceTag`, `New-RetentionCompliancePolicy`, `New-AdaptiveScope`) are gated by these role groups.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm your admin account is in *Information Protection* and *Records Management* (or *Compliance Administrator*).
- **How to implement if missing:** Add the admin to the least-privilege role group under change control; wait for role propagation before running cmdlets.

## 2.3 Security & Compliance PowerShell connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (which provides `Connect-IPPSSession` for Security & Compliance PowerShell) and, where Graph is used for evidence, **Microsoft Graph PowerShell** — with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every configuration cmdlet run through `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-Label` returns without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.4 In-scope workloads and a classification scheme
- **Description:** The **workloads in scope** (Exchange, SharePoint, OneDrive, Teams; endpoints where client-side labeling applies) and the **classification/sensitivity scheme** that drives the taxonomy — the sensitive information types, keywords, or trainable classifiers that define what "Confidential" or "Financial" actually means in your data.
- **Why required:** Auto-labeling rules and retention scoping key off the in-scope workloads and the classification conditions; without an agreed scheme the labels are arbitrary.
- **How to verify:** Confirm the in-scope workloads and the sensitive info types / classifiers with stakeholders; validate the info types exist in Purview → *Data classification → Sensitive info types*.
- **How to implement if missing:** Define the scheme and the priority sensitive info types before authoring auto-labeling rules.

## 2.5 A pilot ring and a simulation-first commitment
- **Description:** A named **pilot ring** (a small group of users/sites) to publish labels to first, and an explicit commitment that **service-side auto-labeling is created in *simulation* mode** and validated before enforcement, and that **encrypting labels and retention (delete) labels are piloted** before broad rollout.
- **Why required:** Encryption and auto-labeling/retention deletion are high-impact and hard to reverse cleanly; the house model requires a simulate/test pass first.
- **How to verify:** Confirm the pilot ring membership (e.g. the group backing `SL Policy – Pilot – Ring1`), a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree the change-control path before publishing anything.

## 2.6 Rights-management (encryption) prerequisites
- **Description:** For sensitivity labels that **encrypt**, the tenant's **Azure Rights Management / unified labeling protection** service must be active, and you must decide the **rights model** (which users/groups get which usage rights — e.g. Co-Author, Reviewer, View-only) per encrypting label.
- **Why required:** An encrypting label cannot be published or will fail to protect if the protection service is not enabled; the rights definition is required input to `New-Label -EncryptionEnabled`.
- **How to verify:** Purview / Microsoft 365 → confirm the protection (Rights Management) service is **activated**; confirm the target groups for each encrypting label's rights exist.
- **How to implement if missing:** Activate the protection service and create/confirm the mail-enabled security groups used in the rights definitions before building encrypting labels.

## 2.7 Adaptive-scope query attributes are populated
- **Description:** For **adaptive scopes**, the directory/site **attributes the query keys off** (e.g. `Department`, `CountryOrRegion`, a SharePoint site property) must be reliably populated on the target users/sites.
- **Why required:** An adaptive scope built on `Department -eq "Finance"` only covers users whose `Department` attribute is actually set; sparse attributes mean silent gaps in retention coverage.
- **How to verify:** Sample the target population and confirm the query attribute is populated; run the scope preview before binding it to a policy.
- **How to implement if missing:** Backfill the attribute (HR sync / directory hygiene) before relying on the adaptive scope; document the coverage assumption.


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


# 3. Implementation Guide — Sensitivity & Retention Labels

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`).
Every write is run `-WhatIf` first, every high-impact policy is **piloted in a small ring**, and
**service-side auto-labeling is created in simulation** before it is ever enforced. Artifact names
follow the `<Type> <Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.
Portal paths are current at authoring — **verify in your tenant**, as the portal is evolving.

> **Model:** Assess the posture, design the taxonomy, publish sensitivity labels to a **pilot ring**,
> auto-label in **simulation**, validate accuracy, build retention labels + adaptive scopes, validate,
> then **expand and enforce.** Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**
>
> **Records/legal deferral:** the retention periods and disposition actions below are **placeholders**
> — confirm each with your records/legal owner before enforcing (see §2 deferral note).

## Step 1 — Assess the current label posture (Assess)
1. Run `PURVLABEL-Discovery.ps1` (read-only). It inventories existing **sensitivity labels** (`Get-Label`), **sensitivity label policies** (`Get-LabelPolicy`), **auto-labeling policies** and their mode (`Get-AutoSensitivityLabelPolicy`), **retention labels** (`Get-ComplianceTag`), **retention policies** (`Get-RetentionCompliancePolicy`), and **adaptive scopes** (`Get-AdaptiveScope`).
2. Review the output: which labels already exist, whether any auto-labeling is already enforced, and whether encryption is already in use. This is your baseline — **do not** duplicate or collide with existing labels.
3. **Gate:** you have a written baseline of every existing label/policy/scope and confirmed no name collisions with the taxonomy you are about to build.

## Step 2 — Design and record the taxonomy (Design)
1. With your governance owners, finalize the sensitivity taxonomy (order least → most sensitive) and the retention taxonomy, using the sample in the Overview as a starting point. Record for **each label**: display name, tooltip, whether it protects (and the exact encryption/marking/rights), and for retention labels the **period + action** (records/legal sign-off).
2. Decide the pilot ring (the group backing `SL Policy – Pilot – Ring1`) and the auto-labeling conditions (sensitive info types / keywords / classifiers) per §2.4.
3. **Gate:** a signed-off taxonomy sheet exists — names, protection, periods, and pilot scope — before any label is created.

## Step 3 — Build the sensitivity labels (Configure, -WhatIf first)
1. Run `PURVLABEL-SensitivityConfig.ps1 -WhatIf` (the default). It prints exactly which labels it would create with `New-Label` — parents (`Confidential`, `Highly Confidential`), sublabels with protection (`Confidential \ All Employees`, etc.), content marking, and encryption/rights — **without making changes**.
2. Review every line: confirm each encrypting label's rights definition targets the correct group (§2.6) and the label order matches the signed-off taxonomy.
3. Re-run `PURVLABEL-SensitivityConfig.ps1 -Commit` to create the labels. Encryption and content marking are set on the labels but **not yet visible to anyone** — labels only appear once published (Step 4).
4. **Gate:** `Get-Label` shows every taxonomy label with the intended protection; none is published yet.

## Step 4 — Publish sensitivity labels to the pilot ring (Pilot)
1. Run `PURVLABEL-SensitivityConfig.ps1 -PublishPolicy -PolicyName "SL Policy – Pilot – Ring1" -PilotGroup "<pilot-group>" -WhatIf`. It shows the `New-LabelPolicy` it would run — publishing the ordered label set to the pilot group only.
2. Re-run with `-Commit` to create `SL Policy – Pilot – Ring1`. Client-side auto-labeling settings (recommend/auto-apply on the label) surface through this policy for pilot users.
3. In the Purview portal (**Information Protection → Label policies**) confirm the policy is published to the pilot group and the labels appear in Office for a pilot user (allow time for client sync).
4. **Gate:** pilot users see the labels in Word/Excel/PowerPoint/Outlook; an encrypting label, applied by a pilot user, actually protects the file (open as an unauthorized user → access denied). Rollback: `Remove-LabelPolicy "SL Policy – Pilot – Ring1"` unpublishes without deleting the labels.

## Step 5 — Configure service-side auto-labeling **in simulation** (Pilot / simulate)
1. Run `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "AL Sim – Financial – SPO+ODB" -ApplyLabel "Confidential \ All Employees" -WhatIf`. It shows the `New-AutoSensitivityLabelPolicy` **in simulation mode** (`-Mode TestWithoutNotifications`) plus the `New-AutoSensitivityLabelRule` (the sensitive-info-type conditions) it would create for SharePoint/OneDrive. **No content is labeled in simulation.**
2. Re-run with `-Commit` to create the simulation policy. Repeat for the Exchange policy (`AL Sim – Financial – Exchange`) if email is in scope.
3. Let the simulation run (it scans in-scope locations over time — **verify current throughput/limits for your tenant**).
4. **Gate:** the auto-labeling policy exists in **simulation** (never enforced yet) and has started scanning — verified in Step 6.

## Step 6 — Validate the simulation match report (Validate)
1. Run `PURVLABEL-SimulationReport.ps1 -PolicyName "AL Sim – Financial – SPO+ODB"`. It reports the policy **simulation status/progress** and the **items matched** — what *would* be labeled — so you can measure precision.
2. Review the matches for false positives (content that should **not** get the label). If precision is poor, tune the auto-labeling **rule** conditions (tighter sensitive info types / higher instance counts / add keywords) and let simulation re-run. Iterate until accuracy is acceptable.
3. **Gate:** the simulation match set is reviewed and accepted by the data owner; false-positive rate is within your agreed threshold. Do **not** proceed to enforce until this gate passes.

## Step 7 — Enforce auto-labeling (Expand)
1. Once simulation is accepted, turn the policy on: `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "AL Sim – Financial – SPO+ODB" -EnforceFromSimulation -WhatIf`, review, then `-Commit`. This flips the policy `-Mode` from simulation to **Enable** — now matching content is actually labeled.
2. Monitor the first enforcement window and confirm labels are being applied as the simulation predicted (re-run `PURVLABEL-SimulationReport.ps1` and spot-check items).
3. **Gate:** enforced labels match the accepted simulation; no unexpected encryption/marking. Rollback: set the policy back to simulation/disabled via the same script with `-DisableAutoLabel`.

## Step 8 — Build retention labels (Configure, -WhatIf first)
1. Run `PURVLABEL-RetentionConfig.ps1 -WhatIf`. It shows the `New-ComplianceTag` calls for each retention label (`Business-General-3yr`, `Financial-Records-7yr`, `Transitory-1yr`, `Legal-Reference`) — with the **period and action confirmed by records/legal** (§2 deferral).
2. Review each: retention action (Keep / Delete / Keep-and-Delete / disposition review), duration, and duration trigger (creation vs modification). **Do not** mark anything as a *record* unless records/legal has declared it so.
3. Re-run with `-Commit` to create the retention labels. They exist but are **not published** yet.
4. **Gate:** `Get-ComplianceTag` lists every retention label with the signed-off period/action; none is published.

## Step 9 — Build the adaptive scopes (Configure, -WhatIf first)
1. Confirm the adaptive-scope query attributes are populated (§2.7).
2. Run `PURVLABEL-RetentionConfig.ps1 -AdaptiveScope -ScopeName "Scope – Users – Finance" -ScopeType User -Query 'Department -eq "Finance"' -WhatIf`, review the `New-AdaptiveScope` it would run, then `-Commit`. Repeat for site scopes (`Scope – Sites – Records`, `-ScopeType Site`) as needed.
3. Run `PURVLABEL-Validation.ps1 -ScopeName "Scope – Users – Finance"` to **preview scope membership** and confirm it resolves the expected population (not empty, not the whole tenant).
4. **Gate:** each adaptive scope resolves the intended, non-empty membership and matches the coverage assumption from §2.7.

## Step 10 — Publish retention labels to a pilot, then by adaptive scope (Pilot → Expand)
1. **Pilot first:** run `PURVLABEL-RetentionConfig.ps1 -PublishRetention -PolicyName "RL Publish – Pilot – Ring1" -PilotGroup "<pilot-group>" -Labels "Business-General-3yr" -WhatIf`, review the `New-RetentionCompliancePolicy` + `New-RetentionComplianceRule -PublishComplianceTag`, then `-Commit`. Confirm pilot users can apply the label in Office/SharePoint.
2. **Then adaptive:** run `PURVLABEL-RetentionConfig.ps1 -PublishRetention -PolicyName "RL Publish – Adaptive – FinanceUsers" -AdaptiveScopeName "Scope – Users – Finance" -Labels "Financial-Records-7yr" -WhatIf`, review, then `-Commit`. The policy binds the label to the adaptive scope and re-evaluates membership automatically.
3. **Gate:** pilot users see and can apply the retention label; the adaptive policy shows the correct scope bound. For any label with a **delete** action, confirm the disposition behavior in a controlled test item before broad reliance. Rollback: `Remove-RetentionCompliancePolicy "<policy>"` unpublishes without deleting the labels.

## Step 11 — Validate end to end and expand (Validate → Expand)
1. Run `PURVLABEL-Validation.ps1 -Full` — it re-checks label/policy health: labels published, auto-labeling enforced and matching simulation, retention policies bound to the right scopes, and adaptive scope membership healthy.
2. Complete the **Testing Guide (§5)**. Only after every gate passes, expand the sensitivity label policy from `SL Policy – Pilot – Ring1` to `SL Policy – Broad – AllUsers` (re-publish to all users) and widen auto-labeling/retention scopes as agreed.
3. **Gate:** all §5 tests pass; broad publish confirmed; a rollback path is documented for each policy.

---
### Order of operations
`Assess posture → Design taxonomy → Build sensitivity labels (-WhatIf → commit) → Publish to pilot ring → Auto-label in SIMULATION → Validate match report → Enforce auto-label → Build retention labels → Build adaptive scopes → Publish retention (pilot → adaptive) → Validate → Expand/enforce broadly`


---


# 5. Testing & Validation Guide — Sensitivity & Retention Labels

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring, and do not enforce auto-labeling, until the
relevant tests pass. All checks use the Purview portal and Security & Compliance PowerShell — the
provided scripts automate the read-only ones.

> **Reminder:** retention periods/actions under test are the records/legal determinations from §2 —
> you are validating that the configuration *behaves as specified*, not deciding the schedule.

## Test 1 — Taxonomy created as designed
- **How:** `PURVLABEL-Discovery.ps1`, or `Get-Label | Format-Table DisplayName,ParentId` and `Get-ComplianceTag | Format-Table Name,RetentionAction,RetentionDuration`.
- **Pass:** every sensitivity label (parents + sublabels, correct order) and every retention label from the signed-off taxonomy exists with the intended protection and period/action.
- **Fail:** missing/extra labels, wrong order, or wrong protection → fix in `PURVLABEL-SensitivityConfig.ps1` / `PURVLABEL-RetentionConfig.ps1` and re-run.

## Test 2 — Sensitivity labels visible to pilot users
- **How:** as a **pilot** user, open Word/Excel/PowerPoint and Outlook; check the Sensitivity button lists the labels. Confirm a **non-pilot** user does **not** see them.
- **Pass:** pilot users see the full ordered label set; non-pilot users see nothing (publish is scoped).
- **Fail:** labels missing for pilot users (allow client sync time) or visible to non-pilot users (policy scope wrong) → re-check `SL Policy – Pilot – Ring1` targeting.

## Test 3 — Encryption/protection actually enforces
- **How:** as a pilot user, apply `Confidential \ Trusted People` (or `Highly Confidential \ Specified People`) to a test document. Attempt to open it as a user **outside** the rights definition.
- **Pass:** the unauthorized user is **denied**; the authorized rights (e.g. Co-Author vs View-only) behave as defined; content marking (header/footer/watermark) appears where configured.
- **Fail:** unauthorized access succeeds, or rights are wrong → the protection service or the label's `EncryptionRightsDefinitions` is misconfigured (§2.6). **Do not publish broadly** until fixed.

## Test 4 — Client-side auto-labeling recommends/applies correctly
- **How:** as a pilot user, create a document containing a matching sensitive info type (e.g. test financial data). Observe whether the label is recommended or auto-applied per the label's configuration.
- **Pass:** the intended label is recommended/applied for matching content and **not** for clearly non-matching content.
- **Fail:** over- or under-labeling → tune the label's auto-labeling conditions and re-test.

## Test 5 — Service-side auto-labeling stays in simulation until accepted
- **How:** `PURVLABEL-SimulationReport.ps1 -PolicyName "AL Sim – Financial – SPO+ODB"`; confirm the policy **Mode** is a simulation/test mode, not Enable.
- **Pass:** the policy is in simulation, has scanned in-scope locations, and produced a match report — **no content was actually labeled**.
- **Fail:** the policy is enforcing before sign-off, or has not scanned → set it back to simulation (`-DisableAutoLabel`) / allow scan time.

## Test 6 — Simulation precision is acceptable before enforcement
- **How:** review the `PURVLABEL-SimulationReport.ps1` match set with the data owner; sample matched items for false positives.
- **Pass:** the false-positive rate is within the agreed threshold and the data owner accepts the match set.
- **Fail:** too many false positives → tune the auto-labeling rule conditions, re-run simulation, re-review. **This is the gate before Step 7 enforcement.**

## Test 7 — Enforced auto-labeling matches the accepted simulation
- **How:** after enforcing (Step 7), re-run `PURVLABEL-SimulationReport.ps1` and spot-check newly labeled items.
- **Pass:** enforced labels match what simulation predicted; no unexpected encryption or marking on user content.
- **Fail:** divergence or surprise protection → roll the policy back to simulation/disabled (`-DisableAutoLabel`) and investigate.

## Test 8 — Adaptive scope resolves the right membership
- **How:** `PURVLABEL-Validation.ps1 -ScopeName "Scope – Users – Finance"` (previews membership) or the portal scope preview.
- **Pass:** the scope resolves the expected, **non-empty** population and does not accidentally include the whole tenant; membership matches the §2.7 coverage assumption.
- **Fail:** empty, too broad, or missing expected members → fix the query or backfill the attribute (§2.7), re-preview.

## Test 9 — Retention label publishes and applies (pilot)
- **How:** as a pilot user, apply `Business-General-3yr` to a test item in SharePoint/Outlook; confirm it appears and is recorded.
- **Pass:** the retention label is available to pilot users and applies to content; the item shows the label.
- **Fail:** label not offered → re-check `RL Publish – Pilot – Ring1` scope and label publishing rule.

## Test 10 — Retention *behavior* is safe (controlled disposition test)
- **How:** for any retention label with a **delete** action, apply it to a **disposable test item** with a short/adjusted trigger in a controlled area (never production records) and confirm the disposition/disposition-review behaves as specified.
- **Pass:** at end of period the item is retained/disposed/sent to review exactly as the records/legal determination specifies.
- **Fail:** unexpected deletion or no disposition → **halt broad reliance**, review the label action/trigger with records/legal before enforcing anywhere real.

## Test 11 — Full health check before expansion
- **How:** `PURVLABEL-Validation.ps1 -Full`.
- **Pass:** labels published to intended scopes, auto-labeling enforced == accepted simulation, retention policies bound to correct static/adaptive scopes, adaptive membership healthy — all green.
- **Fail:** any red → resolve before publishing `SL Policy – Broad – AllUsers` or widening retention/auto-label scope.

---
### Exit criteria (all must be true before broad enforcement)
`Taxonomy built as designed · pilot users see labels · encryption enforces · simulation precision accepted · enforced == simulation · adaptive scopes resolve correctly · retention applies + disposition safe · full health check green · rollback documented per policy`


---


# 6. Troubleshooting Guide — Sensitivity & Retention Labels

Common failure modes, likely causes, and resolutions. Portal paths are current at authoring — the
Purview portal is evolving, so **verify paths in your tenant**. Where a symptom is caused by
licensing, the fix is a plan check, not a config change — **verify your licensing/tenant.**

## A cmdlet is "not recognized" (Get-Label / New-AutoSensitivityLabelPolicy / Get-AdaptiveScope)
- **Cause:** not connected to Security & Compliance PowerShell, or the feature is not licensed in the tenant.
- **Resolve:** run `Connect-IPPSSession` (from the ExchangeOnlineManagement module) first. If the cmdlet still fails after connecting, the capability may require **E5 / E5 Compliance** (service-side auto-labeling, adaptive scopes) — verify the subscription. The provided scripts auto-connect but cannot grant licensing.

## Access denied creating labels or policies
- **Cause:** the admin lacks **Information Protection Admin** (sensitivity) or **Records Management / Compliance Administrator** (retention/adaptive scope) role, or the role has not propagated.
- **Resolve:** add the account to the least-privilege role group (§2.2), sign out/in, allow propagation time, retry.

## Pilot users don't see the sensitivity labels in Office
- **Cause:** label policy not scoped to the user, client not yet synced, or an older Office build.
- **Resolve:** confirm the user is in the group backing `SL Policy – Pilot – Ring1`; verify with `Get-LabelPolicy`. Allow client sync time (can take up to a few hours); confirm a current Microsoft 365 Apps build. Labels only appear once the **policy** is published, not when the label is created.

## An encrypting label doesn't actually protect the file
- **Cause:** the protection (Rights Management) service isn't activated, the rights definition points at a non-existent/empty group, or the label isn't published.
- **Resolve:** confirm the protection service is **activated** (§2.6); confirm the mail-enabled security group in `EncryptionRightsDefinitions` exists and has members; confirm the label is published via a policy. Re-run Test 3 (unauthorized open must be denied).

## Co-authoring or third-party tools break after applying an encrypting label
- **Cause:** encryption + rights that block the collaboration/automation path.
- **Resolve:** this is expected behavior for strong protection — that's why encryption is piloted. Reserve encrypting labels for content that truly needs it; use marking-only labels for lower tiers. Review the rights model with the data owner; ensure required co-authors are in the rights group.

## Service-side auto-labeling "isn't labeling anything"
- **Cause (usually correct behavior):** the policy is in **simulation** (`TestWithoutNotifications`) — it scans and reports but **does not label**. This is by design until precision is signed off.
- **Resolve:** confirm mode with `PURVLABEL-SimulationReport.ps1`. Once precision is accepted (Test 6), enforce with `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -EnforceFromSimulation -Commit`.

## Simulation shows too many matches (false positives)
- **Cause:** the auto-labeling rule conditions are too broad (loose sensitive info types, low instance counts).
- **Resolve:** tighten the rule — higher minimum instance counts, more specific sensitive info types, add supporting keywords, or use a trainable classifier. Let simulation re-run and re-review with the data owner. Do **not** enforce until precision is acceptable.

## Simulation seems "stuck" / no results yet
- **Cause:** service-side scanning processes large volumes over time and is subject to throughput/item limits; results are not instant.
- **Resolve:** allow the scan to progress; re-run `PURVLABEL-SimulationReport.ps1` later. Confirm the in-scope locations actually contain matching content. **Verify current scan limits for your tenant.**

## Adaptive scope resolves 0 objects (or the whole tenant)
- **Cause:** the query attribute is unpopulated (0 objects) or the query is too broad (everyone).
- **Resolve:** preview with `PURVLABEL-Validation.ps1 -ScopeName "<scope>"`. If empty, backfill the query attribute (e.g. `Department`) per §2.7. If too broad, tighten the query. Never bind a retention policy to an unvalidated scope.

## Retention label not offered to users
- **Cause:** the retention label policy isn't scoped to the user/site, or publishing latency.
- **Resolve:** confirm the label is published via `RL Publish – Pilot – Ring1` (pilot) or the adaptive policy; check `Get-RetentionCompliancePolicy` and its rule (`New-RetentionComplianceRule -PublishComplianceTag`). Allow publishing latency before concluding it failed.

## A retention "delete" label deleted content unexpectedly (or didn't dispose)
- **Cause:** wrong action/trigger, or the disposition behavior wasn't tested on disposable content first.
- **Resolve:** **halt broad reliance immediately.** Review the label's `RetentionAction`, `RetentionDuration`, and `RetentionType` (creation vs modification trigger) with records/legal. Only re-enable after Test 10 passes on throwaway items. Remember: retention periods/actions are records/legal determinations, not technical defaults.

## Changes to a label aren't reflected for users
- **Cause:** label/policy edits take time to propagate; existing content keeps the label it was stamped with.
- **Resolve:** allow propagation; re-publish if needed. Note that renaming/reordering labels after publish is disruptive — existing content retains the prior label. Design the taxonomy up front (Best Practices).

## Rolling back a policy safely
- **Sensitivity policy:** `Remove-LabelPolicy "<name>"` unpublishes without deleting the labels.
- **Auto-labeling:** `PURVLABEL-SensitivityConfig.ps1 -AutoLabel -AutoLabelName "<name>" -DisableAutoLabel -Commit` returns it to simulation.
- **Retention policy:** `Remove-RetentionCompliancePolicy "<name>"` unpublishes without deleting the retention labels.
- Removing a **policy** never deletes the underlying **labels** — so rollback is low-risk and reversible.


---


# 7. Best Practices — Sensitivity & Retention Labels

Field-tested practices for building a label program that protects and governs content **without a user
revolt**. These complement the Implementation and Testing guides.

## Taxonomy design
- **Keep it short.** Five to seven top-level sensitivity labels is the practical ceiling — more and users guess or ignore. Use sublabels (parent + children) to add nuance without lengthening the top list.
- **Order by sensitivity, least → most.** Users pick from the ordered list; the order *is* the guidance. Parents used only for grouping should not themselves apply protection.
- **Write plain-language tooltips.** The tooltip is the only in-context help a user gets. "Confidential — share only with named colleagues; do not send outside the company" beats a policy code.
- **Design the taxonomy once, with governance owners.** Renaming or reordering labels after publish is disruptive (existing content keeps the old label). Get the taxonomy signed off before creating labels.

## Protection (encryption & marking)
- **Encrypt deliberately.** Encryption travels with the file and is the strongest control — but it also breaks co-authoring in some paths, third-party tools, and downstream automation. Encrypt only the labels that truly need it, and always pilot first.
- **Define rights by group, not by person.** Point `EncryptionRightsDefinitions` at mail-enabled security groups so membership changes don't require editing the label.
- **Prefer marking for the lower tiers.** `Public`/`General` should mark (footer) but not encrypt — you get visible classification with zero friction.
- **Test the "unauthorized open" every time.** The only proof encryption works is that someone *outside* the rights is denied. Make that Test 3 non-negotiable.

## Auto-labeling
- **Always simulate service-side first.** Never create a service-side auto-labeling policy in Enable mode. Simulation (`TestWithoutNotifications`) scans and reports without touching content — it is the single most important safety control in this solution.
- **Measure precision, then enforce.** Review the simulation match set with the data owner and tune rule conditions (sensitive info types, instance counts, keywords, trainable classifiers) until false positives are acceptable. Enforcing a noisy policy is how you lose user trust.
- **Layer client-side and service-side.** Client-side catches content at creation in Office apps; service-side sweeps data at rest and in transit. Together they cover new and existing content.
- **Watch latency and limits.** Simulation and enforcement scan large volumes over time and are subject to throughput/item limits — **verify current limits for your tenant** and set expectations accordingly.

## Retention & adaptive scopes
- **Retention periods are records/legal's call.** Configure exactly what the accountable owner signs off; never invent a schedule or declare a record without their determination.
- **Prefer adaptive scopes over static scopes** for anything that changes — department, region, site property. Adaptive scopes re-evaluate membership automatically, so coverage doesn't drift as people and sites change.
- **Confirm the query attribute is populated** before trusting an adaptive scope (§2.7). A scope on `Department` silently misses everyone whose `Department` is blank.
- **Pilot delete actions on disposable content only.** Any retention label that deletes must be proven on throwaway test items with a controlled trigger before it goes near real records (Test 10).
- **Keep pilot → adaptive order.** Publish retention labels to a small pilot ring first, validate application and disposition, *then* bind labels to broad adaptive scopes.

## Program & change management
- **Pilot ring, always.** Publish sensitivity labels to `SL Policy – Pilot – Ring1` before `SL Policy – Broad – AllUsers`. The pilot surfaces co-authoring, marking, and encryption issues cheaply.
- **Document a rollback per policy.** Unpublish (`Remove-LabelPolicy` / `Remove-RetentionCompliancePolicy`) removes exposure without deleting labels; know the exact command before you publish.
- **Communicate before broad rollout.** Tell users what the labels mean, what changes (marking/encryption they'll see), and where to get help — the ticket flood comes from surprise, not from labels.
- **Keep least-privilege roles.** Information Protection Admin and Records Management are enough for label work; don't grant Global Admin for day-to-day label operations.
- **Re-baseline periodically.** Run `PURVLABEL-Discovery.ps1` on a cadence to catch label sprawl, orphaned policies, and auto-labeling drift.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` / `Connect-MgGraph`; never embed secrets. Store any exports securely.
- **Read-only or `-WhatIf` by default.** Every provided script defaults to no-change; writes require an explicit `-Commit`. Keep it that way.
- **Verify licensing/tenant before relying on advanced features.** Service-side auto-labeling and adaptive scopes are plan-gated and the portal evolves — flag, don't assume.


---


# 8. Deliverables Summary — Sensitivity & Retention Labels (Implementation)

## What you receive
A complete, self-guided package to design, build, pilot, and enforce Microsoft Purview **sensitivity
and retention labels** — taxonomy, protection, publishing, auto-labeling (simulation-first), and
retention labels with adaptive scopes — using only the Microsoft Purview portal and Security &
Compliance PowerShell.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | Sensitivity vs retention labels, taxonomy design, protection options, client vs service-side auto-labeling, adaptive scopes, naming convention, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (licensing for labels/auto-label/adaptive scopes, Information Protection & Records Management roles, S&C PowerShell, classification scheme, encryption prerequisites, adaptive-scope attributes) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess posture → design taxonomy → build sensitivity labels (`-WhatIf`→commit) → publish to pilot ring → auto-label in **simulation** → validate → enforce → build retention labels + adaptive scopes → publish (pilot→adaptive) → validate → expand. Each step named, gated, and reversible. |
| **Testing & Validation Guide** | 11 pass/fail tests — taxonomy, visibility, encryption enforcement, client + service-side auto-labeling, simulation precision, adaptive-scope membership, retention application, and safe disposition. |
| **Best Practices** | Taxonomy, protection, auto-labeling, retention/adaptive-scope, program/change-management, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (labels not visible, encryption not enforcing, simulation stuck, adaptive scope empty, retention not applying) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell); read-only or `-WhatIf` by
default, writes gated behind `-Commit`. No credentials in code.

| Script | Role | Default |
|---|---|---|
| `PURVLABEL-Discovery.ps1` | **Posture assessment** — inventory existing sensitivity labels, label policies, auto-labeling policies + mode, retention labels, retention policies, and adaptive scopes. | Read-only |
| `PURVLABEL-SensitivityConfig.ps1` | **Sensitivity-label + publish-policy + auto-labeling config helper** — create labels (with protection/marking), publish a label policy to a scope, and create service-side auto-labeling **in simulation**, then enforce. | `-WhatIf` |
| `PURVLABEL-SimulationReport.ps1` | **Auto-labeling simulation status + match report** — report a service-side auto-labeling policy's simulation mode/progress and the items it would label. | Read-only |
| `PURVLABEL-RetentionConfig.ps1` | **Retention-label + adaptive-scope config helper** — create retention labels, create adaptive scopes, and publish retention labels to a pilot group or an adaptive scope. | `-WhatIf` |
| `PURVLABEL-Validation.ps1` | **Scope/config health helper** — preview adaptive-scope membership and run a full label/policy/scope health check. | Read-only |

## Outcomes
- A signed-off **label taxonomy** built in the tenant — sensitivity labels (with protection) and retention labels.
- Sensitivity labels **published to a pilot ring**, then broadly, with encryption proven to enforce.
- Service-side auto-labeling **validated in simulation** and only then enforced — precision measured, not guessed.
- Retention labels **published by adaptive scope**, with membership that re-evaluates automatically.
- Repeatable read-only tooling to re-baseline and health-check the label program over time.

## Explicitly out of scope (deferred)
- **Retention schedules, records declarations, file plans, and legal holds** — determinations owned by records/compliance/privacy/legal; this solution provides the configuration method and evidence, not the schedule.
- **DLP policy authoring**, insider risk, communication compliance, and broader data governance — separate Purview solutions.
- Any capability your **licensing/tenant** does not include — verify before relying on auto-labeling or adaptive scopes.
