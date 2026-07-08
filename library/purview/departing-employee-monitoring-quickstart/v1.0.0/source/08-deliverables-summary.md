# Deliverables Summary — Departing-Employee Data-Theft Monitoring Quickstart

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What the quickstart delivers, the HR/privacy sensitivity, the departing-user model (template, trigger, indicators, HR connector, alerts→cases), and the guardrails. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites — licensing, the role groups + strict separation, anonymization posture, exfiltration indicators, endpoint onboarding, the HR-connector trigger, pilot scope, HR/legal engagement + lawful basis, change control. |
| **Implementation** (`03-implementation.md`) | Ordered steps: guardrails and role separation **first**, then indicators, the HR-connector trigger, the one policy from template, pilot, validate, expand — with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from role separation and anonymization through a sanctioned test leaver → scored alert → audited case and the HR/legal hand-off. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (no alerts, stale HR connector, device indicators not firing, role/permission issues, anonymization confusion) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | Privacy-first, role-separation, determinations-with-HR/legal, reliable-trigger, detection-hygiene, pilot-and-tune, and evidence-integrity guidance. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online**
(`Connect-ExchangeOnline`, for role groups), and/or **Microsoft Graph** (`Connect-MgGraph`). Insider-risk
policy *authoring* is a portal action; these tools handle readiness, verification, planning, scoping, and
reporting.

| Script | Type | What it does |
| --- | --- | --- |
| **`IRMDEPART-Discovery.ps1`** | Read-only | Readiness + **role-separation** + **privacy-settings** assessment: inventories the IRM role groups and their membership, flags any conflicting combinations, reports policy presence where readable, and prompts to confirm the anonymization posture in-portal. |
| **`IRMDEPART-Test-HRConnector.ps1`** | Read-only | **Trigger / indicator readiness** checker: confirms unified audit-log ingestion, reports HR-connector presence/freshness where readable (the departing-user trigger), and lists the portal checks for indicators and device onboarding. |
| **`IRMDEPART-Set-Policy.ps1`** | `-WhatIf` default | **Policy-from-template plan** helper for *Data theft by departing users*: validates that the prerequisites (roles, indicators, trigger source, anonymization) are in place and prints the exact intended policy configuration/plan to apply in the portal; a `-Commit` path only acts where a supported cmdlet exists. |
| **`IRMDEPART-Report.ps1`** | Read-only | **Alert / case rollup** report: summarizes IRM activity readable from the unified audit log (by operation/time) to CSV for a leadership rollup; notes the portal Alerts/Cases dashboards as authoritative; does not de-anonymize. |
| **`IRMDEPART-Set-Scope.ps1`** | `-WhatIf` default | **Scope helper**: previews and (with `-WhatIf:$false`) applies membership changes to the pilot/monitored-leaver group so expansion stays deliberate and reversible. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Pilot scope group:** `SG-Departing-Pilot` (becomes the standing monitored-leaver group at Expand)
- **Priority user group (optional):** `PUG-HighRisk-Leavers`
- **Policy:** `IRM-DepartingUser-DataTheft` — *Data theft by departing users*
- **Role groups (separation):** Insider Risk Management **Admins / Analysts / Investigators / Auditors**
  (avoid the combined **Insider Risk Management** group for operators)

## What this solution deliberately does NOT do

- It does **not** make investigative or disciplinary **determinations** — those are HR/legal's.
- It does **not** disable anonymization or concentrate roles for convenience.
- It does **not** invent portal paths or cmdlets — where policy authoring is portal-only, the tools stop
  at readiness/validation and say so.
- It does **not** decide your **lawful basis** for monitoring — that is a legal determination for your
  jurisdiction(s).
- It is a **focused quickstart** — it delivers the one departing-user policy, not a full insider-risk
  program (data leaks, security-policy violations, communication compliance). It is built on the same
  guardrails, so it can grow into one later.
