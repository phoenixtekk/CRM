# Deliverables Summary — Microsoft Purview Insider Risk Management

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What IRM delivers, the HR/privacy sensitivity, the model (policies, indicators, triggers, connectors, alerts→cases), and the guardrails. |
| **Requirements** (`02-requirements.md`) | IRM-specific prerequisites — licensing, the role groups + strict separation, anonymization posture, indicators, endpoint/HR/physical connectors, priority groups, HR/legal engagement + lawful basis, pilot/change control. |
| **Implementation** (`03-implementation.md`) | Ordered steps: guardrails and role separation **first**, then indicators, policies from templates, connectors, analytics/pilot, validate, expand — with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from role separation and anonymization through a sanctioned test alert → audited case and the HR/legal hand-off. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common IRM failure modes (no alerts, stale HR connector, device indicators not firing, role/permission issues, anonymization confusion) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | Privacy-first, role-separation, determinations-with-HR/legal, pilot-and-tune, detection hygiene, and evidence-integrity guidance. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online**
(`Connect-ExchangeOnline`, for role groups), and/or **Microsoft Graph** (`Connect-MgGraph`). IRM policy
*authoring* is a portal action; these tools handle readiness, verification, scoping, and reporting.

| Script | Type | What it does |
| --- | --- | --- |
| **`PURVIRM-Discovery.ps1`** | Read-only | IRM readiness + **role-separation** + **privacy-settings** assessment: inventories the IRM role groups and their membership, flags any conflicting combinations, reports policy/indicator presence where readable, and prompts to confirm the anonymization posture in-portal. |
| **`PURVIRM-Set-PolicyFromTemplate.ps1`** | `-WhatIf` default | Policy-from-template **configuration helper**: validates that a chosen template's prerequisites (roles, indicators, trigger source, anonymization) are in place and prints the exact intended policy configuration/plan to apply in the portal; any write path is gated behind `-Commit` and flagged "verify availability in your tenant". |
| **`PURVIRM-Test-Readiness.ps1`** | Read-only | **Connector / indicator readiness checker**: reports audit-log ingestion, whether device indicators are enabled (and points to device onboarding), HR-connector presence/freshness where readable, and licensing/integration signals. |
| **`PURVIRM-Report.ps1`** | Read-only | **Alert / case rollup report**: summarizes IRM activity readable from the unified audit log (by type/severity/time) to CSV for a leadership rollup; notes the portal Alerts/Cases dashboards as authoritative. |
| **`PURVIRM-Set-Scope.ps1`** | `-WhatIf` default | **Scope / config helper**: previews and (with `-WhatIf:$false`) applies membership changes to the IRM pilot/scope group so expansion stays deliberate and reversible. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Pilot scope group:** `SG-IRM-Pilot`
- **Priority user groups (if used):** `PUG-Executives`, `PUG-Privileged-Admins`
- **Policies:**
  - `IRM-DepartingUser-DataTheft` — *Data theft by departing users*
  - `IRM-DataLeaks-General` — *Data leaks*
  - `IRM-SecurityPolicyViolations` — *Security policy violations*
- **Role groups (separation):** Insider Risk Management **Admins / Analysts / Investigators /
  Auditors** (avoid the combined **Insider Risk Management** group for operators)

## What this solution deliberately does NOT do

- It does **not** make investigative or disciplinary **determinations** — those are HR/legal's.
- It does **not** disable anonymization or concentrate roles for convenience.
- It does **not** invent portal paths or cmdlets — where IRM authoring is portal-only, the tools stop
  at readiness/validation and say so.
- It does **not** decide your **lawful basis** for monitoring — that is a legal determination for your
  jurisdiction(s).
