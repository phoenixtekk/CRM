# Requirements — Microsoft Purview Health Check

Confirm every prerequisite below **before** you run the health check. Category-level prerequisites
(tenant, licensing model, least-privilege roles, S&C PowerShell / Graph toolchain, in-scope data
sources, compliance/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to running a read-only Purview health check** and turning its findings into a
prioritized, owned remediation register.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> This is a **read-only assessment**. The only requirement that grants write access is R7, and it is
> needed **only** if you intend to use the single safe direct fix (re-enabling the unified audit log)
> — everything else runs read-only. Reviewing insider-risk and role surfaces is **privacy- and
> HR-sensitive**: read the boundaries in R5 and R8 before you look.

---

## R1. Read access to the Purview compliance surfaces you want to assess

**Description:** An account with **read** visibility across the Purview surfaces in scope for the check
— **DLP**, **sensitivity labels / label policies**, **retention / data-lifecycle**, **audit
configuration**, and **role groups**. Least-privilege read roles (e.g. **Compliance Administrator** or
**Compliance Data Administrator** for policy read, **Global Reader** for broad read, and the relevant
**View-Only** role groups) are sufficient for the assessment itself.
**Why:** The health check reads policy, label, retention, audit, and role state; it needs read access
to each surface it scores, but it does **not** need write access to assess.
**Verify:** In the Purview portal, confirm you can open **Data Loss Prevention → Policies**,
**Information Protection → Labels / Label policies**, **Data Lifecycle Management → Retention**, and
**Roles & scopes / Permissions**. `OPSHEALTH-Discovery.ps1` reports what it can and cannot read.
**Implement if missing:** Assign a least-privilege **read** role for the surfaces you intend to score,
under change control. Do **not** over-grant write access "to be safe" — the assessment is read-only.

## R2. Security & Compliance PowerShell + Exchange Online + Graph toolchain

**Description:** The **ExchangeOnlineManagement** module (provides **Security & Compliance PowerShell**
`Connect-IPPSSession` **and** Exchange Online `Connect-ExchangeOnline`, used for the unified-audit-log
status check) and, for role/CA/Graph-side signals, the **Microsoft.Graph** modules (category GR §3),
with a modern-auth / MFA-capable admin.
**Why:** The five scripts run through these — DLP/label/retention/role objects via S&C PowerShell,
unified-audit-log status via Exchange Online, and optional directory-role signals via Graph. Cmdlet and
Graph parameters are version-dependent — **verify in your tenant.**
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph`;
`Connect-IPPSSession`, `Connect-ExchangeOnline`, and `Connect-MgGraph` succeed with modern auth (MFA).
**Implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`. **Modern auth only — no stored credentials or app
secrets in scripts.**

## R3. A defined in-scope workload + data map (what "covered" should mean)

**Description:** A short, agreed list of the **workloads and data sources** Purview is *supposed* to
cover — Exchange, SharePoint, OneDrive, Teams, endpoints/devices — and, where relevant, the
**classification/sensitivity intent** (which labels/SITs matter). This is the **yardstick** the
Coverage (C) domain scores against.
**Why:** "Coverage" is only meaningful relative to an intended scope. Without a target, the check can
report *what is covered* but cannot tell you *what is missing*. (Extends category GR §4.)
**Verify:** A scope note lists the in-scope workloads and any deliberate out-of-scope items;
`OPSHEALTH-ScopeCheck.ps1` reports actual policy coverage per workload to compare against it.
**Implement if missing:** Capture the intended scope with stakeholders (one page is enough) before
scoring Coverage; absence of a target is itself an early finding.

## R4. The intended Purview capability baseline (what *should* exist)

**Description:** A statement of **which Purview capabilities the organization intends to run** —
e.g. "DLP on email + endpoints, sensitivity labels tenant-wide, a 7-year retention policy on
finance sites, unified audit log on, insider risk for departing employees" — so a **missing** policy
can be told apart from a **deliberately-not-adopted** capability.
**Why:** A Gap is only a Gap against intent. A tenant with no insider-risk policy is **healthy** if the
organization never intended insider risk, and a **Gap** if it did. The check needs the intended
baseline to score fairly.
**Verify:** The baseline is written down (even briefly) and confirmed with the compliance owner.
**Implement if missing:** Agree the intended baseline with the compliance/records/security owners.
Where a capability is **unlicensed**, note it as a **licensing decision**, not a drift Gap.

## R5. Role-review boundaries and privacy posture for sensitive surfaces

**Description:** Agreement on **how** the role review and any insider-risk read are conducted:
least-privilege, no snooping into case contents, and — for insider risk / communication compliance —
respecting **role separation** and **privacy-by-design** (report presence and privacy posture, never
case detail or any person's identity beyond what a role is authorized to see).
**Why:** Insider Risk and Communication Compliance are **HR/privacy-sensitive**. A health check must
report *that* the capability is configured and its **privacy guardrails are on** — not *what* it found
about anyone. The role review itself touches who-can-see-what and must be handled carefully.
**Verify:** Confirm with HR/privacy that the check reports **posture only** on sensitive surfaces, and
that the role reviewer is authorized. `OPSHEALTH-Discovery.ps1`/`OPSHEALTH-ScopeCheck.ps1` report IRM
**presence + privacy posture** only.
**Implement if missing:** Agree the boundary in writing before assessing insider-risk or communication
-compliance surfaces. When in doubt, report **posture**, not content.

## R6. A named owner for each domain (so findings become actions)

**Description:** A named **owner** for each remediation domain — typically **DLP**, **Information
Protection (labels)**, **Data Lifecycle / Records**, **Audit**, **Insider Risk**, and **Identity /
Roles** — so every entry in the Remediation Register has someone accountable to close it.
**Why:** A health check that produces findings nobody owns changes nothing. Severity + owner is what
turns the register into a roadmap. (Aligns with category GR §5.)
**Verify:** Each domain in the register maps to a named owner; the compliance/records/privacy/legal
determinations sit with the correct governance function, not with IT.
**Implement if missing:** Assign owners before you circulate the register; unowned High-severity
findings are the ones that rot.

## R7. Change control for the single safe direct fix (audit-log re-enable) and for downstream remediation

**Description:** A **change record** covering (a) the one direct fix this solution may commit —
**re-enabling the unified audit log** — and (b) the downstream remediations that the owning capability
solutions will perform (which they pilot in **simulation/test/report-only** under their own change
control). Re-enabling the unified audit log is a **write** action; it needs an approver even though it
is safe and reversible.
**Why:** Even a safe re-enable is a configuration change in a production tenant; and the higher-impact
remediations (DLP/labels/retention/insider-risk) are high-impact and must be piloted, never flipped on
from a health check.
**Verify:** A change ticket names the approver and the rollback for the audit-log re-enable;
`OPSHEALTH-Remediate.ps1` runs `-WhatIf` (plan only) until you pass `-Commit`.
**Implement if missing:** Record the change; run the remediation planner `-WhatIf` first; commit the
audit-log re-enable only after sign-off; route all other fixes to their owning solution.

## R8. Compliance, records, privacy & legal stakeholders (determinations stay with them)

**Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
stakeholders whose policies the configuration must satisfy — so that any finding touching a
**retention schedule, records file plan, legal hold, regulatory obligation, or insider-risk/
communication-compliance policy** is routed to them for the **determination**, not decided by the
assessor.
**Why:** The health check provides the **technical** state and evidence; **whether** a retention
schedule is right, a hold is required, or a regulation applies is a **legal/records/compliance
determination** (category GR §5). Several surfaces are HR/legal-sensitive.
**Verify:** Confirm the applicable policies, the records schedule owner, and named approvers before the
register's regulatory/records/legal items are actioned.
**Implement if missing:** Identify the owners and capture the requirements; mark such register entries
**"determination required"** and route them accordingly.

---
## Checklist

- [ ] Category GR §1–§6 verified (licensing, roles, toolchain, data scope, stakeholders, pilot/change control)
- [ ] **Read** access to the in-scope surfaces (DLP, labels, retention, audit, roles) — `OPSHEALTH-Discovery.ps1`
- [ ] Modules installed (`ExchangeOnlineManagement`, `Microsoft.Graph`); modern auth works on all three connects
- [ ] **In-scope workload + data map** captured (the Coverage yardstick) — R3
- [ ] **Intended capability baseline** written down (missing vs not-adopted vs unlicensed) — R4
- [ ] Role-review + insider-risk **privacy boundary** agreed (posture only, role separation) — R5
- [ ] A **named owner** per domain (DLP / Labels / Lifecycle / Audit / Insider Risk / Roles) — R6
- [ ] Change control for the **audit-log re-enable** and downstream remediation — R7
- [ ] Compliance/records/privacy/legal stakeholders engaged; determinations routed to them — R8
