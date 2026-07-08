# 1. Solution Overview — Microsoft Purview SOX Compliance Program

## What this solution is
The Sarbanes-Oxley Act (SOX) holds a company's leadership accountable for the integrity of financial
reporting — and, in practice, for the **IT general controls (ITGCs)** around the systems and data that
produce those reports: who can access financial data, how changes are controlled, whether activity is
logged, and whether records are retained. When an external auditor tests those controls, the recurring
failure is not that the controls don't exist — it's that they were never **mapped to a tool**, never
**configured consistently**, and there is **no evidence** to hand over. This solution delivers a
SOX-aligned program **inside Microsoft Purview**: it **maps** the relevant ITGC objectives (access to
programs and data, change management, IT operations, segregation of duties, records retention) to
concrete Purview controls, **configures** those controls — a financial-data **sensitivity label**, a
**DLP policy piloted in simulation**, a **retention policy** for SOX records, **unified audit** with a
retention policy scoped to financial-data access, and least-privilege **roles** — and produces the
**audit evidence** an ICFR review will ask for. It uses only the **Microsoft Purview portal**,
**Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online PowerShell**, and
**Microsoft Graph** — no third-party tooling.

## Why this matters
- **SOX is evidenced, not asserted.** An auditor tests whether a control operated over the period — that requires an artifact (a policy that was in force, an audit trail of access, a change log). Purview is where several of those artifacts naturally live; this solution makes them exist and be exportable.
- **ITGCs are the common audit finding.** Access-to-data, change-management, and IT-operations controls are where financially-relevant IT deficiencies concentrate. Classifying financial data, restricting and monitoring its access, controlling policy change, and retaining the audit trail address exactly those.
- **Audit is not retroactive.** The unified audit log only holds what was captured after logging was enabled. If financial-data access wasn't being logged during the period under review, the evidence simply isn't there — so the foundation is confirmed first, before anything else.
- **The controls are licensing-dependent and evolving.** Advanced DLP, auto-labeling, long-term audit retention, and **Compliance Manager** assessment templates require **Microsoft 365 E5** or the **E5 Compliance** add-on; some are in preview and the Purview portal changes. This solution confirms what your tenant actually has rather than assuming, and flags **"verify your licensing/tenant"** where availability varies.

## How it works
1. **Assess the current state.** Confirm unified audit logging is on, inventory any existing SOX-relevant labels / DLP / retention / audit-retention policies and Purview role assignments, and check the licensing that gates the advanced controls.
2. **Map SOX objectives to Purview controls.** With your SOX/ICFR owners and external-audit expectations, agree which ITGC objective each Purview control satisfies — the mapping is the backbone of the program and of the **Compliance Manager** assessment.
3. **Configure the controls — pilot-first.** Create the financial-data sensitivity label, the DLP policy **in simulation/test mode**, the retention policy on a limited pilot scope, and the audit retention policy for financial-data access — every write previewed with `-WhatIf` and scoped to a pilot ring before any enforcement.
4. **Validate operation and evidence.** Confirm each control exists and is in its expected state, DLP is capturing matches in simulation, labels apply, audit shows financial-data access, and each **evidence runbook** returns the artifact an auditor will request.
5. **Expand to enforcement.** Once the pilot passes, move DLP from simulation to enforce, extend label/retention/audit coverage to full scope, and schedule the read-only discovery/report chain so control drift is caught between audits.

## The SOX control map this solution configures (Purview → ITGC objective)
| Purview control (named artifact) | SOX / ITGC objective it evidences |
|---|---|
| `Financial – SOX Reporting – Confidential` (sensitivity label) | **Access to programs & data** — financial reporting data is classified so protection and monitoring can key off it. |
| `DLP – SOX Financial Data – Simulation` (DLP policy, simulation first) | **Access to programs & data** — prevents/monitors exfiltration of classified financial data; simulation provides evidence of exposure before enforcement. |
| `Retention – SOX Financial Records – Governed` (retention policy) | **Records retention** — retains financially-relevant records for the schedule your records/legal function sets (duration is their determination). |
| `Audit Retention – Financial Data Access – SOX` (audit log retention policy) | **IT operations / monitoring** — the who/what/when access trail is captured and kept for the review period. |
| Least-privilege Purview roles + privileged-action audit | **Segregation of duties & change management** — configuration change is restricted and logged. |
| `SOX ICFR – Purview Controls – Assessment` (Compliance Manager) | **Control mapping & evidence** — the Purview controls above rolled up as ICFR improvement actions with evidence (verify template availability for your licensing). |

## Evidence runbooks (the artifacts an auditor requests)
- `Evidence – Financial Data Access – Runbook` — who accessed labeled financial content, over a period.
- `Evidence – Control Change Management – Runbook` — who changed a DLP / label / retention / role configuration.
- `Evidence – Access Provisioning – Runbook` — role/group additions granting access to financial data.

## What you can control
- Which data is **classified** as SOX-relevant financial reporting data (the label and its scope).
- Whether the financial-data **DLP** policy is in **simulation** or **enforce**, and what it acts on.
- Which record types / operations / users get **extended audit retention**, and for how long (within licensing).
- The **pilot scope** (`SOX Pilot – Finance Ring – Stage1`) validated before any tenant-wide enforcement.
- The **control-to-objective mapping** and which evidence runbooks are in scope.

## Limitations (be honest with buyers)
- **This is not an audit or an attestation.** The solution configures Purview controls and produces evidence; it does not opine on SOX compliance, materiality, or ICFR design/operating effectiveness — that is the work of management, internal audit, and the external auditor.
- **Regulatory, records-retention, and legal determinations are deferred.** SOX record-retention periods (e.g. audit-workpaper retention under §802), which data is financially relevant, legal holds, and control-design decisions belong to your **compliance, records, internal-audit, and legal** functions — this solution provides the technical method and evidence, not the determination.
- **Premium features are license-gated.** Advanced DLP, auto-labeling, long-term audit retention, and Compliance Manager templates require **E5 / E5 Compliance**; some are preview. **Verify your licensing/tenant.**
- **Audit is not retroactive.** Enabling logging today creates no history for the prior period. Value accrues from the enablement date forward.
- **Purview is one layer of ITGC coverage.** It addresses data classification, DLP, retention, and the M365 audit trail; it does **not** replace application-level access controls in your ERP/financial systems, SoD tooling, or change-management systems — coordinate the program with those.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Financial-data sensitivity label | `Financial – SOX Reporting – Confidential` |
| Financial-data DLP policy (simulation first) | `DLP – SOX Financial Data – Simulation` |
| SOX records retention policy | `Retention – SOX Financial Records – Governed` |
| Financial-access audit retention policy | `Audit Retention – Financial Data Access – SOX` |
| Compliance Manager assessment | `SOX ICFR – Purview Controls – Assessment` |
| Financial-data-access evidence runbook | `Evidence – Financial Data Access – Runbook` |
| Control-change evidence runbook | `Evidence – Control Change Management – Runbook` |
| Access-provisioning evidence runbook | `Evidence – Access Provisioning – Runbook` |
| Program evidence scorecard export | `SOX Program – Purview Controls – Report` |
| Pilot validation scope | `SOX Pilot – Finance Ring – Stage1` |

## The standard deployment model
> Assess the current audit/licensing/control state → design the SOX-to-Purview control map → configure
> the label, DLP (simulation), retention, and audit controls → **pilot** on a limited finance ring in
> simulation/test mode → validate each control operates and its evidence is producible → expand to
> enforcement tenant-wide. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**
