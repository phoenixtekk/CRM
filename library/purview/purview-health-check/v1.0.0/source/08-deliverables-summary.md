# Deliverables Summary — Microsoft Purview Health Check

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What the health check delivers, the three domains (Policy / Coverage / Roles), the Healthy→At Risk→Gap rubric, the assessment model, and the read-only-plus-one-safe-fix boundary. |
| **Requirements** (`02-requirements.md`) | Health-check-specific prerequisites — read access to the in-scope surfaces, the S&C PowerShell / Exchange Online / Graph toolchain, the in-scope workload map and intended capability baseline (the yardsticks), the role-review/insider-risk privacy boundary, domain owners, change control for the audit-log fix, and stakeholder routing for determinations. |
| **Implementation** (`03-implementation.md`) | Ordered steps: run the read-only inventory + coverage/role review, score the rubric, build the Remediation Register, produce the scorecard, plan remediation `-WhatIf` (commit only the audit-log re-enable), route everything else to its owning capability, re-score, and make it recurring — with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Ten pass/fail gates from read access and inventory completeness through per-domain scoring, the audit-log determination, the privacy boundary, register completeness, and the post-remediation re-score. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common health-check failure modes (surface unreadable / false Gap, cmdlet not available, audit-log status ambiguous, coverage mis-mapped, role read incomplete, licensing vs drift confusion) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | Score against intent, read-only first, "stuck in test" is drift, coverage is where risk hides, audit log is foundational, least privilege as a metric, respect privacy, severity+owner, defer determinations, make it recurring, verify against tenant. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online**
(`Connect-ExchangeOnline`), and/or **Microsoft Graph** (`Connect-MgGraph`). The health check **reads and
scores**; the one direct write (re-enabling the unified audit log) is gated behind `-Commit`.

| Script | Type | What it does |
| --- | --- | --- |
| **`OPSHEALTH-Discovery.ps1`** | Read-only | **Estate inventory**: enumerates DLP policies (with **Mode**), sensitivity labels + label policies, retention/lifecycle policies + retention labels, unified-audit-log status (via Exchange Online), insider-risk policy **presence + privacy posture** (posture only), and compliance role groups. Changes nothing — the raw material for scoring. |
| **`OPSHEALTH-ScopeCheck.ps1`** | Read-only | **Coverage + least-privilege role review** (the scope/health helper): maps each DLP/retention/label policy to the **workloads** it reaches (Exchange / SharePoint / OneDrive / Teams / endpoints) against the in-scope map, and reviews role groups for **Global Admin sprawl, single-member (SPOF), empty groups, and over-membership**. |
| **`OPSHEALTH-Validate.ps1`** | Read-only | **Validation checker**: reports each check as a pass/fail line aligned to `05-testing.md` — policy enabled/healthy/not-stuck, audit log on, coverage matches intent, role review clean — for scoring and for the post-remediation re-score. |
| **`OPSHEALTH-Remediate.ps1`** | `-WhatIf` default | **Remediation-plan generator**: prints the prioritized plan (finding → severity → owning capability → recommended action) and changes nothing by default. Its **only** commit path, `-EnableUnifiedAuditLog -Commit`, performs the single safe, reversible fix — re-enabling the unified audit log; all other fixes are routed to their owning capability solution to be piloted there. |
| **`OPSHEALTH-Report.ps1`** | Read-only | **Health scorecard rollup**: summarizes per-domain **Healthy / At Risk / Gap** counts and the overall **health rating**, and exports the **Remediation Register** to CSV for a leadership rollup and as the baseline for the next run. |

## Named artifacts (verbatim — used across docs, scripts, and tests)

- **Domains:** **Policy health (P)**, **Coverage (C)**, **Roles (R)**
- **Rating scale:** **Healthy → At Risk → Gap**, rolling up to an overall **health rating**
- **Remediation Register** fields: **Finding · Domain · Rating · Severity (High/Medium/Low) · Owner ·
  Owning capability · Recommended action**
- **The one direct fix:** re-enable the **unified audit log** (`-EnableUnifiedAuditLog -Commit`), safe
  and reversible; everything else is **planned** and routed to its owning capability

## What this solution deliberately does NOT do

- It does **not** enable, enforce, publish, or change **DLP, sensitivity labels, retention/records, or
  insider-risk** configuration — those are high-impact and belong to the owning capability solution,
  **piloted in simulation/test/report-only** first. The health check finds and prioritizes; it does not
  flip.
- It does **not** make **records, retention-schedule, legal-hold, or regulatory determinations** — those
  are compliance/records/privacy/legal's, and such findings are marked **"determination required"**.
- It does **not** expose **insider-risk / communication-compliance case contents** or any person's
  identity — it reports **posture only** on those surfaces.
- It does **not** invent portal paths or cmdlets — where a surface is portal-only or plan-gated, the
  tools say so and defer to **"verify against your licensing/tenant."**
- Its **only** direct write is the reversible **unified-audit-log re-enable**, gated behind `-Commit`.
