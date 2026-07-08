# Deliverables Summary — Microsoft Purview PCI-DSS Compliance Program

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What the program delivers, the PCI-DSS → Purview control map, the role-separation model, the named artifacts, and the Assess→Design→Configure→Pilot(simulate)→Validate→Expand model. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites — licensing (PCI-DSS premium template + advanced DLP/audit), PCI-DSS version/SAQ/CDE scope, least-privilege role separation, unified audit logging, the Credit Card Number SIT, the DLP/label design (simulation-first), action owners/evidence, toolchain, pilot scope + change control. |
| **Implementation** (`03-implementation.md`) | Ordered steps: assess, design the control map/scope, configure roles + audit logging + the PCI-DSS assessment + the cardholder-data DLP **in simulation** + the label, validate, then enforce and expand — with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Ten pass/fail gates from role separation, licensing, and audit logging through DLP detection-in-simulation, precision, label, evidence, and reporting/safety — the gate to enforce and expand. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (template not available, DLP not matching / over-matching, audit logging off, label not appearing, role/permission issues, false PAN matches) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | QSA-scopes-the-CDE, simulation-first-DLP, tune-for-precision, audit-is-Req-10, least-privilege, evidence-is-the-deliverable, control-mapping, never-store-real-PAN, and version/template-update guidance. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft Graph**
(`Connect-MgGraph`). Compliance Manager assessment/evidence *authoring* is a portal action; these tools
handle readiness, the cardholder-data DLP (in simulation), verification, reporting, and scoping.

| Script | Type | What it does |
| --- | --- | --- |
| **`CMPPCI-Discovery.ps1`** | Read-only | Readiness + **role-separation** assessment: reads licensing SKUs (Graph), inventories the Compliance role groups and flags conflicting combinations (`PCI Roles – Separation Evidence`), checks whether **unified audit logging** is enabled (Req 10), confirms the **Credit Card Number** SIT (Req 3), and reports any existing Credit Card Number DLP policy/label and its mode. |
| **`CMPPCI-Configuration.ps1`** | `-WhatIf` default | **Cardholder-data DLP + action-plan** builder: with `-Commit`, creates `DLP-PCI-CardholderData` in **simulation (`TestWithNotifications`) mode** with the `DLP-PCI-CardholderData-Rule` matching the Credit Card Number SIT across the in-scope workloads, and writes the local `PCI Action Plan – Pilot` / `PCI Evidence – Register` tracking artifacts. Defaults to `-WhatIf`, printing exactly what it would create; makes **no enforcing** change. |
| **`CMPPCI-Validation.ps1`** | Read-only | **Technical-evidence** validator: confirms audit logging enabled + retention (Req 10), the DLP policy present and **in simulation mode** with the Credit Card Number rule (Req 3), the sensitivity label published, and role separation — the cross-check behind the assessment's improvement actions. |
| **`CMPPCI-Report.ps1`** | Read-only | **PCI posture** report: rolls up the control-to-evidence map, audit state, DLP mode + a simulation-activity summary from the unified audit log, role separation, and licensing to CSV for a leadership rollup; notes the portal Compliance Manager export as authoritative. |
| **`CMPPCI-Set-Scope.ps1`** | `-WhatIf` default | **Role/scope + enforcement** helper: previews and (with `-Commit`) applies role-group membership changes and — explicitly gated — moves `DLP-PCI-CardholderData` from **simulation to enforce** (`Set-DlpCompliancePolicy -Mode Enable`) so expansion/enforcement stays deliberate and reversible. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **PCI-DSS assessment:** `PCI Assessment – Baseline – Pilot` → `PCI Assessment – Production`
- **Cardholder-data DLP (simulation-first):** policy `DLP-PCI-CardholderData`, rule
  `DLP-PCI-CardholderData-Rule` (Credit Card Number SIT)
- **Cardholder-data label:** `Label-PCI-CardholderData`
- **Tracking artifacts:** `PCI Action Plan – Pilot`, `PCI Evidence – Register`, `PCI Control Map –
  Record`, `PCI Scope – Record`, `PCI Posture – Report`, `PCI Roles – Separation Evidence`
- **Pilot scope group:** `SG-PCI-Pilot`

## What this solution deliberately does NOT do

- It does **not** scope your **Cardholder Data Environment**, choose your **SAQ/version**, or decide
  whether the evidence **satisfies PCI-DSS** — those are **QSA / compliance / legal** determinations.
- It does **not** enforce the cardholder-data DLP until it has been **piloted in simulation** and
  validated; enforcement is an explicit, gated, reversible step.
- It does **not** implement the PCI-DSS requirements Purview can't cover — firewalls, segmentation,
  physical security, anti-malware, vulnerability/penetration testing — those are tracked as **evidence
  links** to their owning systems.
- It does **not** invent portal paths, cmdlets, or sensitive-information-type names — where authoring is
  portal-only (assessments, evidence, labels) the tools stop at readiness/validation and say so.
- It does **not** store or log real cardholder data; DLP validation uses **synthetic test card
  numbers** only.
