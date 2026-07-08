# 8. Deliverables Summary — Microsoft Purview Adoption Program

Everything included in this solution and exactly how each piece is used to **drive real adoption of Microsoft
Purview controls — champions, comms, and behavior change — not just configuration**.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The adoption model — champions network, communications campaign, behavior-change/wave rollout, and adoption measurement — and where the compliance *determinations* stay with compliance/records/legal. |
| **Requirements Guide** | The nine adoption-specific prerequisites (implemented controls to adopt, program roles + change/comms owner, toolchain + audit/directory scopes, wave plan + pilot ring, champions roster, comms plan, adoption baseline, KPI set + wave gate, change control) — each with Verify / Implement-if-missing — over the six category requirements. |
| **Implementation Guide** | Part A to design and stand up the program once; Part B the per-wave heartbeat as five named runbooks (RB-01…RB-05) with pass/fail and rollback. |
| **Testing & Validation Guide** | Six tests with explicit pass/fail + rollback and an acceptance gate proving the program drives and measures behavior (surface baselined, adoption signal reads, coverage flagged, ring expansion safe, KPIs + wave gate render, the cadence fires). |
| **Troubleshooting Guide** | The common adoption failures — audit-search/scope errors, empty or mis-bucketed signal, roster/ring diff mismatches, comms CSV parsing, ring-expansion gating — with causes and fixes. |
| **Best Practices** | Durable practices for behavior change/rollout, champions, communications, measurement, and automation safety. |
| **Executive Summary** | A one-page brief for leadership on why adoption — not config — is what makes Purview controls real and defensible. |

## PowerShell tools (5) — Security & Compliance PowerShell / Microsoft Graph
All are **read-only or `-WhatIf` by default**; the one that writes gates every change behind `-Commit`, a wave
gate, and a change record. None contain credentials or secrets — they use interactive modern auth.

| Script | Role | What it does | Default |
|---|---|---|---|
| **OPSADOPT-Discovery.ps1** | Discovery / baseline | Inventories the **adoption surface** — published sensitivity labels, label policies (with scope), and DLP/retention policy modes — and saves/compares an adoption baseline. | Read-only |
| **OPSADOPT-Report.ps1** | Reporting / signal | Reads the **unified audit log** for actual behavior — sensitivity-label apply/change/remove events and DLP match/override counts — optionally scoped to a ring, and computes labeling coverage + override rate. | Read-only |
| **OPSADOPT-Validation.ps1** | Validation | Diffs the expected **champions roster** and intended wave membership against actual **champions-group** and **ring-group** membership, flagging coverage gaps and unexpected members. | Read-only |
| **OPSADOPT-KpiReport.ps1** | Reporting / KPIs | Composes the adoption KPI dashboard — labeling coverage, DLP override/false-positive rate, champion coverage, comms reach, trend vs baseline — from live signal plus the comms-reach CSV, and renders the **wave-gate** verdict. | Read-only |
| **OPSADOPT-Remediation.ps1** | Config / rollout | The one write tool — **expands** the adoption ring by the next wave (or rolls a wave back) via Microsoft Graph group membership — `-WhatIf` first, `-Commit` writes and stamps the change record. | `-WhatIf` (safe) |

## Named adoption artifacts (created and reused verbatim)
`Adoption Baseline – Purview – <date>` · `Champions Roster – Purview – Adoption` · `Champions – Purview –
Adoption` · `Adoption Ring – Purview – WaveN` · `Comms Plan – Purview – Adoption` · `Comms Reach – Purview –
Adoption` · `KPI Dashboard – Purview – Adoption` · `Wave Gate – Purview – Adoption` · `Change Record –
Purview – Adoption`.

## Adoption cadences
Weekly adoption measurement + comms reinforcement and champions check-in · per-wave gate review · per-wave
ring expansion (change-controlled) · monthly trend review and scope reassessment.

## Outcome
Microsoft Purview controls **actually adopted** — labels applied, DLP prompts respected, behavior changed —
piloted in a ring, measured, reinforced by champions and comms, gated on adoption KPIs, and expanded wave by
wave, so the capability is **in place, in use, and defensible** rather than configured-but-ignored. The
compliance determinations remain with the accountable governance functions; this solution supplies the
adoption method, the champions/comms program, and the evidence that people use the controls.

## Boundaries (what this solution does not decide)
- **Which labels exist and what they mean, retention schedules, records file plans, legal holds** — determined
  by compliance/records/legal; this program drives *use* of the published controls.
- **Insider-risk / communication-compliance case outcomes** — HR/legal determinations; adoption metrics are
  aggregate, privacy-by-design, and never an individual case action.
- **Regulatory applicability** — compliance/legal own the determination; the program evidences adoption of
  the technical controls.
- **Capability availability** — Purview is heavily licensing-gated and evolving, and audit signal varies by
  workload/plan; verify each feature, audit availability, and portal path for your own tenant.
