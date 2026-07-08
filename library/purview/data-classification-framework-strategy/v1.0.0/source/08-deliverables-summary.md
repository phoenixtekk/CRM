# 8. Deliverables Summary — Data Classification Framework & Strategy

## What you receive
A complete, self-guided package to design and stand up an **organization-wide data classification
framework** in Microsoft Purview — a small set of sensitivity tiers, a written classification
standard, and a **crosswalk** mapping each tier to its sensitivity label, DLP posture, and retention
treatment — configured as a coherent reference implementation, piloted in test/simulation, and
validated, using only the Microsoft Purview portal and Security & Compliance PowerShell.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The tier model, the classification standard concept, the tier→label→DLP→retention crosswalk, the naming convention, scope boundaries vs. the deep build solutions, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (licensing across labels/DLP/retention, least-privilege roles for all three families, S&C PowerShell, an agreed tier model, per-tier conditions, encryption prerequisites, pilot ring) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess posture → design tier model + crosswalk (the standard) → build tier labels (`-WhatIf`→commit) → publish to pilot → build DLP baseline in **test** → build + publish retention labels → validate crosswalk coherence → measure coverage → expand + enforce. Each step named, gated, and reversible. |
| **Testing & Validation Guide** | 11 pass/fail tests — tier labels, visibility, encryption, DLP-in-test, DLP matching, retention application + safe disposition, crosswalk coherence (no orphans), live-vs-standard, and coverage evidence. |
| **Best Practices** | Tier-model design, the crosswalk discipline, protection/DLP, retention deferral, program/change management, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (cmdlet not recognized, labels not visible, encryption not enforcing, DLP enabled too early, orphan tiers, retention not applying) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell); read-only or `-WhatIf` by
default, writes gated behind `-Commit`, and the DLP baseline created in **test** mode. No credentials
in code.

| Script | Role | Default |
|---|---|---|
| `CLSFRAME-Discovery.ps1` | **Posture assessment** — inventory existing sensitivity labels, label policies, DLP policies + mode, and retention labels/policies, and report which framework tiers already have an artifact per control family. | Read-only |
| `CLSFRAME-FrameworkConfig.ps1` | **Framework config/remediation helper** — create the tier labels, publish the label policy (pilot → broad), build the tier-aligned DLP baseline **in test mode** (then enforce from test), and create + publish tier retention labels. | `-WhatIf` |
| `CLSFRAME-Crosswalk.ps1` | **Crosswalk reporting** — export the live tier→label→DLP→retention crosswalk from the tenant (CSV/console) to compare against the signed-off standard. | Read-only |
| `CLSFRAME-Validation.ps1` | **Coherence validation** — check, per tier, that the label, DLP posture, and retention label all exist and are consistently named (no orphans); DLP still in test. | Read-only |
| `CLSFRAME-Coverage.ps1` | **Scope/health + coverage helper** — health-check the framework artifacts and, where licensed, pull labeling activity (`Export-ActivityExplorerData`) to measure how content classifies per tier. | Read-only |

## Outcomes
- A signed-off **classification standard** — tier definitions, handling rules, and a complete crosswalk — that DLP, labels, and retention all align to.
- The **tier labels** built and published to a pilot ring, with encryption proven to enforce on protected tiers.
- A **tier-aligned DLP baseline** validated in **test** mode before any enforcement.
- **Tier-aligned retention labels** published to the pilot, with disposition proven safe.
- Repeatable read-only tooling to export the live crosswalk, validate coherence, and re-baseline the framework over time.

## Explicitly out of scope (deferred)
- **The tier model itself, DLP enforcement decisions, retention schedules, records declarations, and regulatory applicability** — determinations owned by governance/compliance/records/privacy/legal; this solution provides the framework method, the crosswalk, and the configuration + evidence, not the determination.
- **Deep build solutions** — the exhaustive auto-labeling build, full DLP policy development, and the records retention file plan/schedule are separate Purview solutions that plug into this framework.
- Any capability your **licensing/tenant** does not include — verify before relying on advanced DLP conditions or activity/content explorer coverage reporting.
