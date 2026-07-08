# Deliverables Summary — Microsoft Purview Architecture & Design

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What the architecture delivers — the capability map, RBAC model, scoping strategy, naming standard, and phase roadmap — the phase model, the role-separation model, and the Assess→Design→Configure→Pilot→Validate→Expand approach. |
| **Requirements** (`02-requirements.md`) | Architecture-specific prerequisites — licensing baseline and what it gates, readable role groups + agreed separation, the in-scope capability/phase decision, scoping-strategy inputs (adaptive vs static, admin units, workloads), the naming standard, compliance/records/privacy/legal owners, the PowerShell/Graph toolchain, and a pilot ring with change control. |
| **Implementation** (`03-implementation.md`) | Ordered steps: baseline the tenant, map capabilities to licensing/phases, design the RBAC model + scoping strategy + naming standard, stand up the foundation guardrails, validate, then execute the roadmap phase by phase — with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Ten pass/fail gates from licensing and the capability map through RBAC separation, least privilege, scoping and the pilot ring, naming and simulation-first discipline, to the posture report and safe automation defaults. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common design/foundation failure modes (a capability missing from the portal, role-group names that differ, SoD conflicts, adaptive scope unavailable, naming drift, connection/permission issues) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | Map-to-licensing-first, architect separation of duties, scoping as first-class, the pilot ring, simulation-first as a designed pattern, naming before the first object, sequenced phases, living architecture, and privacy-by-design for the sensitive domains. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft Graph**
(`Connect-MgGraph`). The Purview architecture is **portal-managed**; these tools assess the estate,
scaffold the RBAC and scope guardrails, validate the design, and report — they do not replace the portal.

| Script | Type | What it does |
| --- | --- | --- |
| **`PURVARCH-Discovery.ps1`** | Read-only | **Baseline / discovery**: reports subscribed SKUs and an **indicative** capability-availability mapping (via Graph), the current compliance **role groups** and their membership, existing **labels / DLP / retention policies** and **adaptive scopes**, and the **audit** state — the `PA Design Baseline – Tenant – Assess` snapshot. Changes nothing. |
| **`PURVARCH-Configuration.ps1`** | `-WhatIf` default | **RBAC-model configuration helper**: validates the designed role-group membership and composes `Add-RoleGroupMember` / `Remove-RoleGroupMember` to apply least-privilege, separated membership. **Runs with `-WhatIf` by default** and prints exactly what it would change; `-Commit` applies. Builds no capability policy — those are separate, piloted changes. |
| **`PURVARCH-Validation.ps1`** | Read-only | **Design-conformance checker**: reports separation-of-duties conflicts (`PA RBAC SoD – Conflicts`), least-privilege posture, capability-vs-licensing coverage, pilot-ring/adaptive-scope presence, and objects that do **not** conform to the naming standard — as pass/fail lines aligned to `05-testing.md`. |
| **`PURVARCH-Report.ps1`** | Read-only | **Design-posture rollup**: emits the `PA Capability Map – Tenant – Design` scaffold and the `PA Design Posture – Report` (capability coverage vs licensing, RBAC separation, scope coverage, naming conformance, phase status) to CSV; notes the portal is authoritative. |
| **`PURVARCH-Set-Scope.ps1`** | `-WhatIf` default | **Pilot-ring / scope helper**: previews and (with `-Commit`) creates/populates the pilot group `SG-PA-Pilot` and — where adaptive scopes are in the design — scaffolds the example adaptive scope `AS-PA-Pilot` (`New-AdaptiveScope`, where available), so expansion stays deliberate and reversible. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Tenant baseline snapshot:** `PA Design Baseline – Tenant – Assess`
- **Capability map:** `PA Capability Map – Tenant – Design`
- **RBAC model:** `PA RBAC Model – Tenant – Design`
- **RBAC separation-of-duties conflicts:** `PA RBAC SoD – Conflicts`
- **Scoping plan:** `PA Scoping Plan – Tenant – Design`
- **Naming standard:** `PA Naming Standard – Tenant – Design`
- **Phase roadmap:** `PA Phase Roadmap – Program – Design`
- **Design posture report:** `PA Design Posture – Report`
- **Pilot ring group:** `SG-PA-Pilot`
- **Example adaptive scope (pilot):** `AS-PA-Pilot`
- **Phases:** **0 Foundation & Governance · 1 Know · 2 Protect · 3 Prevent loss · 4 Govern & retain · 5 Advanced (risk)**
- **Future object naming:** `<Purpose> – <Scope> – <Stage>` with **`Sim`** (simulation/test) and **`Prod`** (enforced)

## What this solution deliberately does NOT do

- It does **not** build the capability policies (labels, DLP, retention, insider risk) — those are built
  in **their own solutions**, against this design, and **piloted in simulation/test first**.
- It does **not** enforce anything tenant-wide — the only things it configures are the **foundation
  guardrails** (least-privilege role membership and the pilot ring/scope), and those default to `-WhatIf`.
- It does **not** decide **which regulations apply**, the **retention schedule**, the **records file
  plan**, or the **lawful basis** for insider-risk/communication monitoring — those are
  **compliance/records/privacy/legal** determinations.
- It does **not** invent portal paths, role-group names, or cmdlets — where a surface is portal-only or
  evolving, the tools stop at assessment/scaffolding and say "verify against your licensing/tenant".
