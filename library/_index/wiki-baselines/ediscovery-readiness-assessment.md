# eDiscovery Readiness Assessment — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: EDREADY

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — eDiscovery Readiness Assessment (Microsoft Purview)

## Outcome
Your organization has an **evidenced, defensible answer to "if a legal hold or regulatory request
landed today, could we respond?"** Instead of discovering gaps mid-litigation, you hold a **readiness
scorecard** across four domains — **roles, holds/preservation, data-source scope, and process** — a
**prioritized gap register** with owners, and **proof** that the capability actually works: a hold
placed, a search run, and preservation confirmed on a **dedicated test account**, then cleaned up. The
gaps that quietly break real matters — over-privileged or unstaffed roles, an audit log that is off,
uncovered inactive mailboxes, missing Teams/M365-Group scope, no intake or sign-off process — are
found and fixed **before** the stakes are real.

## Approach
The assessment follows a pilot-first model — **Assess → Design → Configure → Pilot (readiness proof
in test) → Validate → Expand.** It inventories the current state read-only, scores each domain **Not
Ready → Partial → Ready** into a scorecard and gap register, remediates **dry-run first** (enabling
the audit log, putting operators in the least-privilege **eDiscovery Manager/Administrator** role
groups, adopting the intake/naming/change-control artifacts), and then **rehearses the capability
non-destructively** on a scratch test account — create case, place hold, run search, confirm
preservation, **remove the hold**. Everything is named to a standard
(`eDiscovery Readiness – Proof – Pilot`) and the same names flow through the tests and the five
included PowerShell tools. It is deliberately distinct from **operating** matters — a separate
eDiscovery Administration solution runs real cases end to end; this one makes you **ready** to.

## Why it is low-risk
- **Legal owns the determination; IT proves the capability.** Scope, custodians, holds, and
  production are legal/records decisions — this solution supplies the technical readiness evidence,
  never the legal call. The proof runs on a **test account**, never a real custodian.
- **Non-destructive and self-cleaning.** The readiness proof places a hold on a test mailbox and
  **removes it** at the end; nothing real is preserved, and the tenant is left as it was.
- **Least-privilege by design.** Roles are assessed and remediated to the **eDiscovery role groups**,
  not Global Admin, with coverage so no single person is a point of failure.
- **Safe-by-default automation.** Four of the five tools are **read-only**; the remediation tool is
  **`-WhatIf` by default** and requires an explicit `-Commit` — modern authentication, **no
  credentials or secrets in code.**

The result is a capability you can **prove is ready** — least-privilege, defensible, and rehearsed —
at a fraction of the cost of finding out during litigation that it was not.


---


# 1. Solution Overview — eDiscovery Readiness Assessment (Microsoft Purview)

## What this solution is (and is not)
This solution answers one question with evidence: **"If a legal hold or regulatory request landed
today, could we respond — completely, defensibly, and on time?"** It is a **readiness assessment** of
your Microsoft Purview eDiscovery capability across four domains — **roles, holds/preservation,
data-source scope, and process** — that produces a **readiness scorecard, a prioritized gap
register, and a remediation roadmap**, then **proves** the capability with a small, non-destructive
**readiness-proof pilot** on a test account.

> **This is an *assessment*, not the day-to-day operation of matters.** A separate Purview solution —
> **eDiscovery Administration** — covers running real matters end to end (case → search → hold →
> review → export, with KQL query design, review sets, analytics, and defensible export). This
> readiness assessment sits *before* that: it confirms you are configured, licensed, staffed, and
> rehearsed to run matters at all, and it fixes the gaps that would otherwise surface mid-litigation.
> Where operating a matter is in scope, use the eDiscovery Administration solution; this one makes you
> **ready** to.

## Why readiness is the risk
When a hold lands, the clock starts and the standard of conduct is **defensibility** — proof that
preservation was timely and complete. Organizations fail here not because Purview cannot do it, but
because of gaps that were invisible until tested:

- **Roles** granted through Global Administrator (over-privileged) or held by one person (no
  coverage), or nobody in **eDiscovery Manager/Administrator** at all.
- **Preservation** that silently is not working — the **unified audit log is off** (no defensibility
  evidence), **inactive/legacy mailboxes** are not covered, or retention and holds interact in ways
  nobody has verified.
- **Scope** blind spots — Teams messages (which live in mailboxes), M365 Group/Teams sites,
  OneDrive, unindexed or partially-indexed content — that make a collection incomplete.
- **Process** gaps — no matter-intake step, no legal sign-off gate, no naming standard, no
  change-control or evidence-pack routine — so the *first* real matter is improvised.

A readiness assessment surfaces these on a test account and a scorecard, not during discovery in a
live matter.

## The four readiness domains (the rubric)
Each domain is scored **Not Ready → Partial → Ready** with named, evidenced criteria:

1. **Roles & least privilege (R).** Are operators in **eDiscovery Manager**, with a small
   **eDiscovery Administrator** lead group, and **no standing Global Admin** used for matters? Is
   there **coverage** (more than one trained operator — no single point of failure)? Are compliance
   boundaries considered where separation is required?
2. **Holds & preservation (H).** Is the **unified audit log on** (the defensibility evidence)? Can a
   **hold actually preserve** — proven, not assumed? Are **inactive/legacy mailboxes**,
   **litigation-hold** state, and **retention-vs-hold interplay** understood and covered? Is there
   headroom for the number/size of holds you may need?
3. **Data-source scope & coverage (S).** Are all in-scope **workloads** discoverable — Exchange
   (including **Teams chat**, which lives in mailboxes), SharePoint, OneDrive, and **Teams/M365 Group
   sites and files**? Are **unindexed/partially-indexed** items and any third-party/imported data
   accounted for?
4. **Process & defensibility (P).** Is there a **matter-intake** step with a named **legal/records
   owner** who determines scope and holds; a **naming standard**; **change control** and **rollback**
   for holds/exports; and an **evidence-pack** routine (who keeps the audit trail and export
   reports)?

## How it works (the assessment model)
1. **Assess (read-only).** Inventory the current state — role membership, existing cases/holds, audit
   status, licensing signals, inactive mailboxes, retention holds, and workload coverage — with the
   included read-only scripts. Nothing changes.
2. **Design (the scorecard).** Score each domain against the rubric, record every gap in the **gap
   register** with severity and owner, and design the target state and remediation order.
3. **Configure/Remediate (simulation/test first).** Close gaps — add operators to the correct role
   groups, enable the audit log, stand up the naming standard and intake process — using the
   remediation script **dry-run (`-WhatIf`) by default**, committing only with an explicit switch.
4. **Pilot the readiness proof (non-destructive, on a test account).** Prove the capability end to
   end on a **scratch, non-sensitive test account**: create a **readiness-proof case**, place a
   **hold**, run a **scoped search**, confirm preservation, then **remove the proof hold**. This
   rehearses the muscle without touching real custodians — the "pilot in test" gate.
5. **Validate (pass/fail gates).** Re-run the validation script; every rubric gate must pass and the
   audit log must show the proof activity.
6. **Expand (operate).** With gaps closed and the proof passing, you are ready to run live matters —
   using the **eDiscovery Administration** solution — with legal owning every determination.

## The reference design (naming)
Everything created by the readiness proof is named to make it obvious it is a **rehearsal**, and is
removed at the end:
- Proof case: `eDiscovery Readiness – Proof – Pilot`
- Proof hold policy / rule: `Readiness Hold Policy – Proof – Pilot` / `Readiness Hold Rule – Proof – Pilot`
- Proof search: `Readiness Search – Proof – Pilot`
- Proof custodian: a **dedicated test account** (placeholder `readiness-pilot@contoso.com`), never a
  real person.

## What legal owns (and what this solution does not decide)
**Regulatory, records-retention, and legal determinations are deferred to your compliance, records,
privacy, and legal functions.** This solution supplies the **technical method and the evidence** —
whether roles are least-privilege, whether a hold preserves, whether scope is complete — but never
the legal call about what must be held, who is a custodian, what a retention schedule is, or whether
a regulatory obligation applies. The readiness proof runs on a **test account only**; it is a
capability rehearsal, not a real preservation.

## Benefits
- **Know before litigation, not during.** A defensible, evidenced answer to "are we ready?" — with a
  scorecard the business and legal can act on.
- **Fixes the invisible gaps.** Over-privileged roles, audit-off tenants, uncovered inactive
  mailboxes, and missing process — found on a test account, not mid-matter.
- **Least-privilege and safe.** Remediation is dry-run by default; the proof is non-destructive and
  self-cleaning; no Global Admin dependency.
- **A rehearsed muscle.** The team has actually placed a hold and run a search once, in test, before
  the stakes are real.

## Limitations (be honest with buyers)
- **Licensing-gated capability.** Content Search and eDiscovery (Standard) cases/holds are broadly
  available; **eDiscovery (Premium)** (custodians, review sets, analytics, structured export)
  requires **Microsoft 365 E5 / E5 eDiscovery and Audit** — the assessment reports which tier is
  available; **verify your licensing/tenant.** Readiness for *Premium* review workflows is flagged
  where the tier is absent.
- **The portal is evolving.** Microsoft unified the eDiscovery experience in the Purview portal
  (`purview.microsoft.com`); menu paths differ from older screenshots — paths are flagged **"verify
  in your tenant."**
- **Not a substitute for legal judgement.** The assessment evidences capability; scope, custodian,
  hold, and production decisions remain legal/records determinations.
- **Government clouds differ.** GCC High / DoD use different portal hosts (e.g. `*.office365.us`) and
  some features lag Commercial — **verify in your tenant.**

## The standard deployment model
> **Assess → Design → Configure → Pilot (readiness proof in test) → Validate → Expand.** Remediation
> is dry-run first; the readiness proof is non-destructive and runs on a dedicated test account; every
> gate is explicit pass/fail with a documented rollback (remove the proof hold, revert role changes).


---


# 2. Requirements Guide — eDiscovery Readiness Assessment (Microsoft Purview)

These are the prerequisites to run the **assessment and the readiness proof**. They complement — and
do **not** repeat — the six shared **[Purview category Global Requirements](global-requirements-purview.md)**
(compliance licensing, least-privilege Purview roles, S&C PowerShell + Graph toolchain, in-scope data
sources, compliance/records/legal stakeholders, and a pilot scope + change control). Verify each of
the six there first; the solution-specific items below add the eDiscovery detail. Each entry is
**Description · Why · Verify · Implement-if-missing.**

## 2.1 eDiscovery tier / licensing known (Standard vs Premium)
**Description:** Confirmation of which eDiscovery tier the tenant is licensed for. **Content Search**
and **eDiscovery (Standard)** cases and holds are available in most enterprise plans (e.g. Microsoft
365 E3); **eDiscovery (Premium)** — custodians, review sets, analytics/de-duplication, structured
export — requires **Microsoft 365 E5** or the **E5 eDiscovery and Audit** add-on (see category GR #1).
**Why:** Readiness for a Premium *review* workflow cannot be asserted without the Premium tier; the
assessment must record the tier so the scorecard reflects real capability, not aspiration.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; open `https://purview.microsoft.com`
→ **eDiscovery** — if you cannot create custodians/review sets you are on Standard only. Run
`EDREADY-Discovery.ps1` (reports which case types/holds exist). **Plan names and gating change —
verify in your tenant.**
**Implement:** Record the tier in the scorecard. If Premium review capability is required and absent,
assign E5 / E5 eDiscovery and Audit before claiming Premium readiness.

## 2.2 eDiscovery role groups (least privilege) — the assessor's access
**Description:** The assessor needs at least **eDiscovery Manager** to read cases/searches and place
the proof hold, and visibility of **eDiscovery Administrator** membership; reading role membership
needs an appropriate Purview role (category GR #2). No Global Administrator is used to run the proof.
**Why:** The assessment evaluates *whether roles are least-privilege*; the assessor themselves must
operate through the role groups, modelling the target state.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles & scopes → Permissions →
Microsoft Purview solutions → eDiscovery Manager / eDiscovery Administrator**; or PowerShell
`Get-RoleGroupMember "eDiscovery Manager"` / `Get-RoleGroupMember "eDiscovery Administrator"`. Run
`EDREADY-Discovery.ps1`.
**Implement:** Add the assessor to **eDiscovery Manager** (and note the current membership as an
assessment finding). Do **not** grant Global Admin for the assessment.

## 2.3 Unified audit log enabled (defensibility evidence)
**Description:** The Microsoft Purview **unified audit log** is on, so case, search, hold, and export
activity — including the readiness proof — is recorded.
**Why:** The audit trail *is* the evidence of defensibility. A tenant with auditing **off** is a
high-severity readiness gap: preservation actions cannot be proven after the fact.
**Verify:** Purview → **Audit** returns results; or `EDREADY-Discovery.ps1` reads
`UnifiedAuditLogIngestionEnabled`.
**Implement:** Enable auditing (the remediation script can do this with `-Commit`), then allow time
for events to populate. Turning auditing on is itself a scored remediation item.

## 2.4 Data-source scope mapped (workloads + inactive mailboxes)
**Description:** A written map of the workloads a matter would have to cover — **Exchange** mailboxes
(remembering **Teams chat** is stored in mailboxes), **SharePoint** sites, **OneDrive** accounts, and
**Teams / M365 Group** sites and files — plus an inventory of **inactive/legacy mailboxes** and any
third-party/imported data (extends category GR #4).
**Why:** Coverage blind spots (Teams messages, M365 Group sites, inactive mailboxes) are the classic
cause of incomplete collection; readiness means these are known *before* a matter.
**Verify:** A scope note lists the workloads and any out-of-scope items; `EDREADY-Scope.ps1` reports
mailbox coverage, litigation-hold state, and inactive mailboxes.
**Implement:** Enumerate the workloads and inactive mailboxes; capture the map as a scorecard input.

## 2.5 Named legal/records owner + intake process (scope & hold determination)
**Description:** A named legal, compliance, or records owner who **decides** matter scope, custodians,
holds, and production, and a **matter-intake step** where that sign-off is captured before any
configuration (this is the eDiscovery-specific expression of category GR #5).
**Why:** Scope and hold are **legal determinations**, not IT defaults. Readiness is not just technical
— an org with perfect tooling but no intake/sign-off process is **not ready**.
**Verify:** A matter-intake template/record exists with a named legal owner and a hold-instruction
field. Confirmed with the stakeholder, recorded as a Process-domain finding.
**Implement:** Establish the intake step (legal signs off scope + hold before configuration). Absence
is a scored Process gap; the assessment provides the target-state description.

## 2.6 PowerShell modules and connectivity
**Description:** The **ExchangeOnlineManagement** module (provides **Security & Compliance PowerShell**
`Connect-IPPSSession` **and** Exchange Online `Connect-ExchangeOnline`, used by the scope/mailbox
checks) and, for Premium signals, the **Microsoft.Graph.Security** module (category GR #3).
**Why:** The five scripts run through these — compliance objects via S&C PowerShell, mailbox/inactive
coverage via Exchange Online, optional Premium case status via Graph. Graph cmdlet parameters are
version-dependent — **verify in your tenant.**
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Security`;
`Connect-IPPSSession` and `Connect-ExchangeOnline` succeed with modern auth (MFA).
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph.Security -Scope CurrentUser`. **Modern auth only — no stored
credentials or app secrets in scripts.**

## 2.7 Dedicated test account for the readiness proof (non-sensitive)
**Description:** A **dedicated, non-sensitive test account** (for example an IT scratch mailbox) with
a little seeded mail/files, used as the **proof custodian** so the full case → hold → search →
confirm → remove-hold rehearsal never touches a real person.
**Why:** The readiness proof is a **capability rehearsal**; it must run in test. Using a real
custodian would place a real hold — out of scope for an assessment and a legal action in its own right.
**Verify:** A test account exists (placeholder `readiness-pilot@contoso.com`) with seeded content.
**Implement:** Provision the test account, seed a few messages/files, and reserve the proof names from
Section 1's reference design.

## 2.8 Change control + rollback for the proof (and for remediation)
**Description:** A change record covering the readiness-proof hold and any remediation (role-group
changes, enabling audit), with a defined rollback (remove the proof hold/policy, revert role
membership) — the eDiscovery expression of category GR #6.
**Why:** Even a test hold and role changes are configuration changes in a production tenant; they
need an approver, a pilot gate, and a documented rollback.
**Verify:** A change ticket names the approver, the test scope, and the rollback steps.
**Implement:** Record the change; run remediation `-WhatIf` first; place the proof hold only after
sign-off; remove it at the end of the proof.

---
## Checklist
- [ ] Category GR #1–#6 verified (licensing, roles, toolchain, data scope, stakeholders, pilot/change control)
- [ ] eDiscovery **tier** known (Standard vs **Premium/E5**) — `EDREADY-Discovery.ps1` — *verify in tenant*
- [ ] Assessor in **eDiscovery Manager**; **eDiscovery Administrator** membership reviewed; no Global Admin for the proof
- [ ] **Unified audit log** status checked (on = ready; off = high-severity gap) — `EDREADY-Discovery.ps1`
- [ ] Workloads + **inactive mailboxes** mapped — `EDREADY-Scope.ps1`
- [ ] Named **legal/records owner** + **matter-intake** process on record
- [ ] Modules installed (`ExchangeOnlineManagement`, `Microsoft.Graph.Security`); modern auth works
- [ ] **Dedicated test account** for the readiness proof (non-sensitive, seeded)
- [ ] Change control + rollback for the proof hold and remediation


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


# 3. Implementation Guide — eDiscovery Readiness Assessment (Microsoft Purview)

Follow the model **Assess → Design → Configure → Pilot (readiness proof in test) → Validate →
Expand.** The assessment scores four domains — **Roles (R)**, **Holds/preservation (H)**,
**Scope/coverage (S)**, **Process (P)** — each **Not Ready → Partial → Ready**, records every gap in a
**gap register**, remediates **dry-run first**, and then **proves** the capability non-destructively on
a **dedicated test account**. Every proof artifact uses the Section 1 naming and the same names flow
through Testing, Troubleshooting, and the scripts.

Portal: `https://purview.microsoft.com` → **eDiscovery** / **Audit** / **Settings → Roles & scopes**
(Government clouds use a different host, e.g. `*.office365.us` — **verify in your tenant**).
PowerShell: `Connect-IPPSSession` (Security & Compliance) for compliance objects; `Connect-ExchangeOnline`
for mailbox/inactive coverage; `Microsoft.Graph.Security` for optional Premium signals.

> **Legal owns the determination** of scope, custodians, holds, and production. Everything below is
> the technical assessment method and a **test-account rehearsal** — not a real matter, not a real
> preservation. Do not place a hold on a real custodian as part of this assessment.

---

## Stage A — Assess (read-only, nothing changes)
1. **Inventory current state.** Run **`EDREADY-Discovery.ps1`** (read-only). It reports: eDiscovery
   **role-group membership** (Manager/Administrator) and whether Global Admin appears in either;
   existing **cases**, **Content Searches**, and **case-hold policies/rules**; **unified audit log**
   status; and case-type signals for the **tier** (Standard vs Premium). This feeds domains **R** and
   **H**.
2. **Map data-source coverage.** Run **`EDREADY-Scope.ps1`** (read-only). It reports mailbox count and
   **litigation-hold** state, **inactive/legacy mailboxes**, and any existing retention holds, and
   lists the workloads to confirm (Exchange incl. **Teams chat in mailboxes**, SharePoint, OneDrive,
   Teams/M365 Group sites). This feeds domain **S**.
3. **Interview for process.** With the named legal/records owner (Requirement 2.5), confirm whether a
   **matter-intake** step, **naming standard**, **change control/rollback**, and **evidence-pack**
   routine exist. This feeds domain **P**.

**Gate A (pass/fail):** discovery + scope reports captured and the process interview complete — you
have the raw current state for all four domains. Fail → resolve access/module gaps (Requirements
2.2, 2.6) and re-run.

---

## Stage B — Design (the scorecard + gap register)
4. **Score each domain against the rubric.** Using the Stage-A evidence, score **R/H/S/P** as **Not
   Ready / Partial / Ready** with the named criteria:
   - **R — Roles:** operators in **eDiscovery Manager**; a small **eDiscovery Administrator** lead
     group; **no standing Global Admin** for matters; **coverage ≥ 2** trained operators.
   - **H — Holds/preservation:** **audit log on**; a hold can be **proven** to preserve (Stage D);
     **inactive mailboxes** and **litigation-hold**/retention interplay understood and covered.
   - **S — Scope/coverage:** all in-scope workloads discoverable, **Teams messages and M365 Group
     sites** included, **unindexed/imported** data accounted for.
   - **P — Process:** **matter-intake + legal sign-off**, **naming standard**, **change
     control/rollback**, **evidence-pack** ownership all present.
5. **Record every gap.** For each below-Ready criterion, add a **gap-register** row: domain, finding,
   severity (High/Med/Low), owner, and remediation action. Audit-off and Global-Admin-for-matters are
   **High** by default.
6. **Design the target state and order.** Sequence remediation: enable audit and fix roles first
   (they gate everything and the proof), then scope/process. `EDREADY-Reporting.ps1` renders the
   scorecard + gap register.

**Gate B:** a completed scorecard and a prioritized gap register with owners. Fail → gather missing
evidence and re-score.

---

## Stage C — Configure / Remediate (simulation/-WhatIf first)
7. **Remediate the gaps — dry-run by default.** Run **`EDREADY-Remediation.ps1`** with **`-WhatIf`**
   (the default) to preview every change; re-run with **`-Commit`** only after sign-off (Requirement
   2.8). It can:
   - **Enable the unified audit log** (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
     $true`) — closing the highest-severity H gap.
   - **Add named operators** to **eDiscovery Manager** / the **eDiscovery Administrator** lead group
     (`Add-RoleGroupMember`) — closing R gaps and building coverage.
   - **Stand up the readiness-proof case + hold** shell (see Stage D) named to the Section 1 pattern.
   It **never removes** holds or role members silently, and it prints every action it would take.
8. **Adopt the process artifacts.** Put the **matter-intake template**, **naming standard**, and
   **change-control/rollback** and **evidence-pack** routine in place (documentation deliverables) —
   closing P gaps. These need no tenant change, only adoption.

**Gate C:** audit log **on**; role groups least-privilege with coverage; process artifacts adopted.
Fail → complete remediation (re-run `-WhatIf`, then `-Commit`).

---

## Stage D — Pilot: the readiness proof (non-destructive, test account only)
Prove the capability end to end on the **dedicated test account** (Requirement 2.7), never a real
custodian. This is the "pilot in test" gate — a rehearsal that is removed at the end.
9. **Create the proof case.** `New-ComplianceCase -Name "eDiscovery Readiness – Proof – Pilot"
   -CaseType eDiscovery` (portal: **eDiscovery → Cases → Create a case**). `EDREADY-Remediation.ps1
   -Commit` can create it.
10. **Place the proof hold on the test account.** Create `Readiness Hold Policy – Proof – Pilot`
    (`New-CaseHoldPolicy` over the **test mailbox only**) and `Readiness Hold Rule – Proof – Pilot`
    (`New-CaseHoldRule`). `EDREADY-Remediation.ps1` builds these dry-run first; `-Commit` applies.
    Portal: case → **Holds → Create**.
11. **Run the proof search.** Create and start `Readiness Search – Proof – Pilot`
    (`New-ComplianceSearch`/`Start-ComplianceSearch`) scoped to the test mailbox with a simple query
    matching the seeded content. Portal: case → **Searches → New search**.
12. **Confirm preservation.** As the test account, delete a seeded held item and confirm it remains
    recoverable/preserved (recoverable items / preservation hold). This is the proof that a hold
    **actually preserves** in your tenant.
13. **Remove the proof hold (clean up).** Delete `Readiness Hold Rule – Proof – Pilot` then
    `Readiness Hold Policy – Proof – Pilot` (`Remove-CaseHoldRule` / `Remove-CaseHoldPolicy`), leaving
    the tenant as it was. The **capability is proven; nothing is left preserving.**

**Gate D (the core readiness gate):** proof case created; hold placed and **proven** to preserve on
the test account; scoped search returned the seeded items; proof hold **removed**. Fail any → the
capability is not demonstrably ready — fix and re-run before claiming readiness.

---

## Stage E — Validate
14. Run the **testing procedures in `05-testing.md`** and **`EDREADY-Validation.ps1`** — every rubric
    gate (R/H/S/P) must return **pass**, and the audit log must show the proof activity.
    `EDREADY-Reporting.ps1` produces the final evidence pack (scorecard, gap register closed-state,
    proof audit records).

**Gate E:** all validation gates pass; audit shows the proof case/hold/search. Fail → remediate and
re-validate.

---

## Stage F — Expand (operate for real)
15. **You are ready to run live matters.** With gaps closed and the proof passing, operate real
    matters using the **eDiscovery Administration** solution — legal owning every determination.
    Re-run this assessment **periodically** (e.g. quarterly, and after a tenant/licensing change) so
    readiness does not drift.

---

## Rollback (documented before you commit anything)
- **Proof hold:** delete `Readiness Hold Rule – Proof – Pilot` then `Readiness Hold Policy – Proof –
  Pilot` (`Remove-CaseHoldRule` / `Remove-CaseHoldPolicy`) — it only ever covered the **test
  account**, so removal releases nothing real. This is a normal step of Stage D.
- **Proof case/search:** searches are non-destructive; `Remove-ComplianceSearch` and
  `Remove-ComplianceCase` remove the rehearsal artifacts.
- **Role change:** `Remove-RoleGroupMember` to revert an added operator.
- **Audit log:** enabling auditing is not reverted (it is a readiness improvement); if you must,
  `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $false` — **not recommended.**


---


# 5. Testing & Validation — eDiscovery Readiness Assessment (Microsoft Purview)

Run these to **validate readiness** after remediation and the readiness proof. Each test maps to a
rubric domain (**R/H/S/P**), states the **procedure** and the **expected pass/fail**, and where noted
is produced by `EDREADY-Validation.ps1` / `EDREADY-Reporting.ps1`. The proof artifacts are the
Section 1 names on the **test account**.

## Test 1 (R) — Roles are least-privilege, with coverage
**Procedure:** Run `EDREADY-Validation.ps1`; or Purview → **Settings → Roles & scopes** → check
**eDiscovery Manager** / **eDiscovery Administrator** membership.
**Pass:** Operators are in eDiscovery Manager; a small lead group is in eDiscovery Administrator;
**no Global Admin** appears in either group; **≥ 2** trained operators (coverage).
**Fail:** Global Admin is used for matters, no members in the role groups, or a single operator (no
coverage) — see Requirement 2.2 / Implementation Stage C.

## Test 2 (H) — Unified audit log is on
**Procedure:** Run `EDREADY-Validation.ps1` (reads `UnifiedAuditLogIngestionEnabled`); or Purview →
**Audit** returns results.
**Pass:** Auditing is **enabled**; a search for recent activity returns records.
**Fail:** Auditing off (high-severity gap — enable via `EDREADY-Remediation.ps1 -Commit`, Requirement
2.3).

## Test 3 (H) — A hold actually preserves (the readiness proof)
**Procedure:** With `Readiness Hold Policy – Proof – Pilot` / `Readiness Hold Rule – Proof – Pilot`
**enabled** on the **test account**, delete a seeded held item and confirm it is still
recoverable/preserved. `EDREADY-Validation.ps1` confirms the proof policy/rule are enabled over the
test mailbox.
**Pass:** The hold policy/rule are enabled over the test mailbox and the deleted item remains
preserved and discoverable — preservation demonstrably works.
**Fail:** Hold shows disabled/error, or the item is permanently gone (see Troubleshooting) — the
capability is **not** proven.

## Test 4 (H) — Proof hold removed (clean up verified)
**Procedure:** After the proof, run `EDREADY-Validation.ps1` (or `Get-CaseHoldPolicy`) and confirm
`Readiness Hold Policy – Proof – Pilot` no longer exists.
**Pass:** The proof hold and rule are gone; nothing is left preserving on the test account.
**Fail:** The proof hold still exists (remove per Implementation Step 13 / Rollback) — a rehearsal
must not leave a standing hold.

## Test 5 (S) — Scope/coverage is complete
**Procedure:** Run `EDREADY-Scope.ps1`; review workload coverage, **inactive/legacy mailboxes**, and
that **Teams messages (in mailboxes)** and **M365 Group/Teams sites** are accounted for.
**Pass:** Every in-scope workload is discoverable and mapped; inactive mailboxes are inventoried; no
known workload is missing from the scope note.
**Fail:** A workload is unaccounted for (e.g. Teams chat, M365 Group sites, inactive mailboxes) — a
coverage blind spot (Requirement 2.4 / Implementation Step 2).

## Test 6 (S) — Proof search returns the seeded content
**Procedure:** Inspect `Readiness Search – Proof – Pilot` statistics (`EDREADY-Reporting.ps1` or
portal search **Statistics**); preview a sample.
**Pass:** Item count is in the expected order of magnitude for the seeded test content; preview shows
the on-topic seeded items — search over the held location works.
**Fail:** Zero hits when content was seeded, or an implausible count (query/location scope wrong).

## Test 7 (P) — Process artifacts exist
**Procedure:** Confirm the **matter-intake template** (with named legal owner + hold instruction),
the **naming standard**, the **change-control/rollback**, and the **evidence-pack** routine are
adopted.
**Pass:** All four process artifacts exist and are owned; a matter could be intaken today with legal
sign-off before configuration.
**Fail:** Any missing — an org with tooling but no process is **not ready** (Requirement 2.5 /
Implementation Step 8).

## Test 8 (all) — Audit trail of the proof present
**Procedure:** Run `EDREADY-Reporting.ps1` (audit section) or Purview → **Audit** and search for the
proof case/hold/search activity.
**Pass:** Audit records exist for the proof case creation, hold placement/removal, and search —
defensibility evidence is being captured.
**Fail:** No audit activity (auditing off — Test 2 — or insufficient time to populate).

## Test 9 — Licensing/tier recorded honestly
**Procedure:** `EDREADY-Discovery.ps1` case-type/tier signals vs the licensing in Requirement 2.1.
**Pass:** The scorecard records the actual tier (Standard vs **Premium/E5**); any Premium *review*
readiness claim is backed by E5 licensing.
**Fail:** The scorecard claims Premium review readiness without the tier — **verify in your tenant**
and correct.

---
## Validation gate summary (all must pass to declare readiness)
- [ ] Roles least-privilege **with coverage**, no Global Admin (Test 1)
- [ ] **Audit log on** (Test 2)
- [ ] **Hold proven** to preserve on the test account (Test 3) and **proof hold removed** (Test 4)
- [ ] **Scope/coverage complete** — Teams, M365 Groups, inactive mailboxes (Test 5)
- [ ] Proof **search** returns seeded content (Test 6)
- [ ] **Process artifacts** adopted (Test 7)
- [ ] **Audit trail** of the proof present (Test 8)
- [ ] **Tier/licensing** recorded honestly (Test 9)


---


# 6. Troubleshooting — eDiscovery Readiness Assessment (Microsoft Purview)

Common readiness failure modes, what causes them, and how to resolve — keyed to the four domains and
the named proof artifacts. Re-run the read-only scripts (`EDREADY-Discovery.ps1`, `EDREADY-Scope.ps1`,
`EDREADY-Validation.ps1`) after each fix to confirm the gate flips to pass.

## Unified audit log is OFF (high-severity H gap)
- **Symptom:** `EDREADY-Discovery.ps1` / `EDREADY-Validation.ps1` report
  `UnifiedAuditLogIngestionEnabled = False`; the Audit solution returns nothing.
- **Cause:** Auditing was never enabled, or was disabled. Without it, preservation actions cannot be
  proven — the defensibility evidence does not exist.
- **Resolve:** `EDREADY-Remediation.ps1 -EnableAudit -Commit` (or Purview → **Audit → turn on**). Then
  **wait** — events take time to populate; re-run validation later. Enabling auditing is a one-way
  readiness improvement; do not disable it.

## No members in the eDiscovery role groups / matters run as Global Admin (R gap)
- **Symptom:** `eDiscovery Manager` / `eDiscovery Administrator` show `(no members)`, or the discovery
  script flags a member who is **also a Global Admin**.
- **Cause:** eDiscovery access was never delegated, or was granted via Global Admin (over-privileged).
- **Resolve:** Add operators with `EDREADY-Remediation.ps1 -AddManagers <upns> -Commit` and the
  lead(s) with `-AddAdministrators <upn> -Commit`; remove standing Global-Admin use for matters. Grant
  eDiscovery **only** through the role groups.

## Only one trained operator (coverage gap, R)
- **Symptom:** Validation flags fewer than two `eDiscovery Manager` members.
- **Cause:** Single point of failure — one person on leave stops a hold.
- **Resolve:** Add and **train** at least a second operator; document who does what. Coverage is part
  of readiness, not just having *a* role holder.

## The readiness-proof hold does not preserve (H — the core proof fails)
- **Symptom:** `Readiness Hold Policy – Proof – Pilot` shows disabled/error, or a deleted seeded item
  on the **test account** is permanently gone (Test 3 fails).
- **Cause:** The hold was not enabled, the policy did not target the test mailbox, replication had not
  completed, or the account is unlicensed for the hold.
- **Resolve:** Confirm the policy/rule exist and are **enabled** over the **test mailbox**
  (`Get-CaseHoldPolicy`/`Get-CaseHoldRule`); allow time for the hold to take effect before deleting a
  test item; verify the test account's licensing. Rebuild with `EDREADY-Remediation.ps1 -BuildProof
  -ProofMailbox <test> -Commit` if needed. Do **not** conclude readiness until preservation is proven.

## Proof hold still present after the assessment (H — cleanup gap)
- **Symptom:** Post-assessment, `Readiness Hold Policy – Proof – Pilot` still exists (Test 4 fails).
- **Cause:** The Stage-D cleanup step was skipped.
- **Resolve:** Remove it — `Remove-CaseHoldRule 'Readiness Hold Rule – Proof – Pilot'` then
  `Remove-CaseHoldPolicy 'Readiness Hold Policy – Proof – Pilot'`. A rehearsal must not leave a
  standing hold; it only ever covered the test account, so removal releases nothing real.

## Inactive / legacy mailboxes not covered (S blind spot)
- **Symptom:** `EDREADY-Scope.ps1` lists inactive mailboxes; the scope note does not account for them.
- **Cause:** Inactive/legacy mailboxes are a classic preservation blind spot — content persists but is
  easy to forget.
- **Resolve:** Inventory every inactive mailbox and confirm whether it is in scope; ensure in-scope
  ones would be covered by a hold. Record the decision in the scope note (a legal/records call on
  what is in scope).

## Teams / M365-Group content missing from scope (S gap)
- **Symptom:** The scope note covers mailboxes but not **Teams chat**, **Teams files**, or **M365
  Group** sites; a collection would under-collect.
- **Cause:** A mailbox-only mental model. **Teams chat lives in mailboxes**; **Teams files and M365
  Group content live in SharePoint/OneDrive.**
- **Resolve:** Add Teams (chat via mailboxes) and M365 Group/Teams sites (SharePoint/OneDrive) to the
  scope note and confirm they are discoverable in the portal — **verify in your tenant.**

## Premium features (custodians / review sets / analytics / export) absent (tier)
- **Symptom:** You cannot create custodians or review sets; Premium readiness cannot be claimed.
- **Cause:** The tenant/operators are licensed for **Standard** only; Premium requires **E5 / E5
  eDiscovery and Audit** (Requirement 2.1).
- **Resolve:** Record the **actual tier** in the scorecard (do not claim Premium review readiness
  without it). If a Premium review workflow is required, assign the licensing, then re-assess. **Plan
  names and gating change — verify in your tenant.**

## Process artifacts missing (P — "tooling but not ready")
- **Symptom:** No matter-intake template, no legal sign-off gate, no naming standard, no change
  control/rollback, no evidence-pack owner (Test 7 fails).
- **Cause:** Readiness was treated as purely technical.
- **Resolve:** Adopt the four process artifacts (documentation deliverables). An org with perfect
  tooling but no intake/sign-off process is **not ready** — scope and holds are legal determinations
  that must be captured *before* configuration.

## PowerShell connect / module errors
- **Symptom:** `Connect-IPPSSession` or `Connect-ExchangeOnline` fails; cmdlets not found.
- **Cause:** Module not installed, or legacy/basic auth.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; connect with **modern
  auth/MFA**. For Premium signals also `Install-Module Microsoft.Graph.Security`. **Never** store
  credentials or app secrets in the scripts (Requirement 2.6).

## Insufficient role to read config
- **Symptom:** Discovery/scope scripts report "could not read" for audit config, mailboxes, or role
  membership.
- **Cause:** The assessor lacks the Purview/Exchange role to read that object.
- **Resolve:** Grant the least-privilege read role (category GR #2 / Requirement 2.2) and re-run — do
  not escalate to Global Admin to work around it.

## Government cloud paths differ
- **Symptom:** Portal paths/hosts in this guide do not match your tenant.
- **Cause:** GCC High / DoD use different hosts (e.g. `*.office365.us`) and some features lag
  Commercial.
- **Resolve:** Use your cloud's portal host and **verify in your tenant**; the cmdlets are the same,
  the paths and availability may differ.


---


# 7. Best Practices — eDiscovery Readiness Assessment (Microsoft Purview)

Durable practices for keeping the eDiscovery capability **ready, least-privilege, and defensible** —
so the next real matter is routine, not a scramble.

## Readiness is a state you maintain, not a project you finish
- **Re-assess periodically.** Readiness drifts — people leave the role groups, licensing changes,
  new workloads appear. Re-run this assessment **quarterly** and after any tenant/licensing change,
  re-scoring R/H/S/P and updating the gap register.
- **Track the scorecard over time.** A rising number of Ready domains (and a shrinking gap register)
  is the evidence of a maturing capability; show it to legal and leadership.
- **Rehearse before you need it.** Run the **readiness proof on the test account** at least once per
  assessment cycle. A team that has placed a hold and run a search this quarter responds faster when
  a real hold lands.

## Least privilege and coverage (domain R)
- **Grant eDiscovery through the role groups, never Global Admin.** eDiscovery can read anyone's mail
  and files; operators belong in **eDiscovery Manager**, a small lead group in **eDiscovery
  Administrator** — Global Admin is not an eDiscovery role.
- **Avoid the single point of failure.** Keep **at least two** trained operators; document who does
  what. One person on leave should not stop a hold.
- **Consider compliance boundaries early.** In multi-region/multi-agency tenants, decide *before* a
  matter whether an eDiscovery team may search everyone — the boundary is a legal/HR determination
  implemented as a compliance security filter.

## Preservation you can prove (domain H)
- **Keep the unified audit log on — always.** It is the defensibility evidence; auditing off is the
  single highest-severity readiness gap. Do not disable it.
- **Prove, don't assume.** "We have holds" is not readiness; "we placed a hold on a test account,
  deleted a held item, and it survived" is. The proof is the point.
- **Cover the easy-to-miss data.** **Inactive/legacy mailboxes**, litigation-hold state, and the
  **retention-vs-hold interplay** are where preservation silently fails — inventory and verify them.
- **Understand headroom.** Know the practical limits on the number/size of holds you may run, so a
  large matter does not surprise you.

## Complete scope (domain S)
- **Remember where content really lives.** **Teams chat is stored in mailboxes**; **Teams files** and
  **M365 Group** content live in SharePoint/OneDrive. A mailbox-only mental model under-collects.
- **Account for unindexed/partially-indexed items and imported/third-party data** in the scope note —
  they do not vanish because a search missed them.
- **Map, then verify.** A written scope note is necessary but not sufficient; confirm the workloads
  are actually discoverable in the tenant.

## Process and defensibility (domain P)
- **Legal owns the determination; IT executes and evidences it.** Scope, custodians, holds, and
  production are legal/records decisions. Readiness means the **intake step** captures that sign-off
  *before* configuration — never improvise scope.
- **Name everything to a standard.** A consistent naming convention (`<Purpose> – <Matter> – <Stage>`)
  makes matters auditable and the audit trail legible.
- **Change control and rollback for holds and exports.** Even a test hold is a production change;
  every hold/export has an approver, a pilot gate, and a documented rollback.
- **Own the evidence pack.** Decide who keeps the audit trail and export reports, and for how long —
  the evidence of a defensible collection is only useful if someone retains it.

## Safe automation
- **Dry-run first, commit deliberately.** The remediation script is **`-WhatIf` by default**; read
  every previewed action before `-Commit`. Discovery/scope/validation/reporting are **read-only**.
- **Modern auth, no secrets.** Connect with `Connect-IPPSSession` / `Connect-ExchangeOnline` using
  modern auth/MFA; **never** put credentials or app secrets in scripts.
- **Keep docs and automation in lockstep.** The scripts print the same artifact names used in the
  Implementation and Testing guides — when you change a name, change it in both.

## Know the boundaries
- **Verify licensing/tenant, don't assume.** Premium (custodians/review sets/analytics/export) is
  E5-gated and the portal evolves; record the actual tier and flag version-dependent paths.
- **Government clouds differ.** GCC High / DoD use different hosts and some features lag — verify.
- **This assessment makes you ready; it does not run matters.** Operate real matters with the
  **eDiscovery Administration** solution, with legal in control of every determination.


---


# 8. Deliverables Summary — eDiscovery Readiness Assessment (Microsoft Purview)

## Documentation
- **01 – Solution Overview** — what a readiness assessment is (and how it differs from operating
  matters via the eDiscovery Administration solution), why readiness is the risk, the four-domain
  rubric (**Roles / Holds / Scope / Process**), the assessment model, the reference naming for the
  readiness proof, and what legal owns.
- **02 – Requirements Guide** — the solution-specific prerequisites (eDiscovery tier/licensing,
  least-privilege assessor roles, audit log, data-source + inactive-mailbox scope, named legal owner +
  intake, modules, a dedicated **test account** for the proof, change control) with Verify / Implement
  steps and a checklist — referencing the six shared **Purview category Global Requirements**.
- **03 – Implementation Guide** — the ordered **Assess → Design → Configure → Pilot (readiness proof
  in test) → Validate → Expand** build: inventory current state, score R/H/S/P into a **scorecard +
  gap register**, remediate **dry-run first**, prove the capability **non-destructively on a test
  account** (case → hold → search → confirm preservation → remove hold), validate, then operate — with
  pass/fail gates and rollback.
- **05 – Testing & Validation** — nine procedures with expected pass/fail (roles least-privilege +
  coverage, audit on, hold **proven** to preserve, proof hold **removed**, scope complete, search
  returns seeded content, process artifacts adopted, audit trail present, tier recorded honestly) and
  a gate summary.
- **06 – Troubleshooting** — common readiness failure modes and resolutions (audit off, no role-group
  members / Global-Admin dependency, hold not preserving on the proof, inactive-mailbox coverage gaps,
  missing Teams/M365-Group scope, Premium features absent, proof cleanup).
- **07 – Best Practices** — durable practices for a ready, least-privilege, defensible capability that
  is re-assessed and rehearsed rather than assumed.
- **Executive Summary** — the outcome (an evidenced answer to "are we ready?"), the approach, and why
  it is low-risk.

## PowerShell scripts (5) — safe-by-default (read-only or `-WhatIf`; modern auth; no secrets)
1. **`EDREADY-Discovery.ps1`** — **read-only current-state inventory.** Reports eDiscovery role-group
   membership (Manager/Administrator, and whether Global Admin appears), existing cases / Content
   Searches / case-hold policies, unified-audit-log status, and case-type/tier signals — the raw
   evidence for the **Roles** and **Holds** domains.
2. **`EDREADY-Remediation.ps1`** — **gap remediation, dry-run (`-WhatIf`) by default.** Previews (and
   with **`-Commit`** applies) enabling the unified audit log, adding named operators to the eDiscovery
   role groups, and standing up the **readiness-proof** case + hold on the test account
   (`New-ComplianceCase` / `New-CaseHoldPolicy` / `New-CaseHoldRule`). Never removes holds or members
   silently; prints every action.
3. **`EDREADY-Validation.ps1`** — **read-only rubric validation.** Runs the R/H/S/P gate checks — roles
   least-privilege + coverage, audit on, proof hold enabled then removed, scope accounted for — and
   emits pass/fail for each, matching Section 5.
4. **`EDREADY-Reporting.ps1`** — **read-only scorecard / gap register / evidence pack.** Renders the
   readiness scorecard and gap register and summarizes the proof search statistics, hold status, and
   eDiscovery audit activity — the deliverable evidence pack.
5. **`EDREADY-Scope.ps1`** — **read-only scope/health helper.** Reports mailbox coverage and
   litigation-hold state, **inactive/legacy mailboxes**, existing retention holds, and the workload
   checklist (Exchange incl. Teams chat, SharePoint, OneDrive, Teams/M365 Group sites) — the
   **Scope/coverage** domain evidence.

All scripts print clear, named output referencing the same artifact names (`eDiscovery Readiness –
Proof – Pilot`, `Readiness Hold Policy – Proof – Pilot`, `Readiness Search – Proof – Pilot`) used in
the Implementation and Testing guides, so the docs and automation stay in lockstep. **Regulatory,
records, and legal determinations are deferred to the relevant governance functions** — the scripts
provide method and evidence, not the determination.
