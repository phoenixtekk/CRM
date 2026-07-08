# 8. Deliverables Summary — Sensitivity & Retention Labels (Implementation)

## What you receive
A complete, self-guided package to design, build, pilot, and enforce Microsoft Purview **sensitivity
and retention labels** — taxonomy, protection, publishing, auto-labeling (simulation-first), and
retention labels with adaptive scopes — using only the Microsoft Purview portal and Security &
Compliance PowerShell.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | Sensitivity vs retention labels, taxonomy design, protection options, client vs service-side auto-labeling, adaptive scopes, naming convention, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (licensing for labels/auto-label/adaptive scopes, Information Protection & Records Management roles, S&C PowerShell, classification scheme, encryption prerequisites, adaptive-scope attributes) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess posture → design taxonomy → build sensitivity labels (`-WhatIf`→commit) → publish to pilot ring → auto-label in **simulation** → validate → enforce → build retention labels + adaptive scopes → publish (pilot→adaptive) → validate → expand. Each step named, gated, and reversible. |
| **Testing & Validation Guide** | 11 pass/fail tests — taxonomy, visibility, encryption enforcement, client + service-side auto-labeling, simulation precision, adaptive-scope membership, retention application, and safe disposition. |
| **Best Practices** | Taxonomy, protection, auto-labeling, retention/adaptive-scope, program/change-management, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (labels not visible, encryption not enforcing, simulation stuck, adaptive scope empty, retention not applying) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell); read-only or `-WhatIf` by
default, writes gated behind `-Commit`. No credentials in code.

| Script | Role | Default |
|---|---|---|
| `PURVLABEL-Discovery.ps1` | **Posture assessment** — inventory existing sensitivity labels, label policies, auto-labeling policies + mode, retention labels, retention policies, and adaptive scopes. | Read-only |
| `PURVLABEL-SensitivityConfig.ps1` | **Sensitivity-label + publish-policy + auto-labeling config helper** — create labels (with protection/marking), publish a label policy to a scope, and create service-side auto-labeling **in simulation**, then enforce. | `-WhatIf` |
| `PURVLABEL-SimulationReport.ps1` | **Auto-labeling simulation status + match report** — report a service-side auto-labeling policy's simulation mode/progress and the items it would label. | Read-only |
| `PURVLABEL-RetentionConfig.ps1` | **Retention-label + adaptive-scope config helper** — create retention labels, create adaptive scopes, and publish retention labels to a pilot group or an adaptive scope. | `-WhatIf` |
| `PURVLABEL-Validation.ps1` | **Scope/config health helper** — preview adaptive-scope membership and run a full label/policy/scope health check. | Read-only |

## Outcomes
- A signed-off **label taxonomy** built in the tenant — sensitivity labels (with protection) and retention labels.
- Sensitivity labels **published to a pilot ring**, then broadly, with encryption proven to enforce.
- Service-side auto-labeling **validated in simulation** and only then enforced — precision measured, not guessed.
- Retention labels **published by adaptive scope**, with membership that re-evaluates automatically.
- Repeatable read-only tooling to re-baseline and health-check the label program over time.

## Explicitly out of scope (deferred)
- **Retention schedules, records declarations, file plans, and legal holds** — determinations owned by records/compliance/privacy/legal; this solution provides the configuration method and evidence, not the schedule.
- **DLP policy authoring**, insider risk, communication compliance, and broader data governance — separate Purview solutions.
- Any capability your **licensing/tenant** does not include — verify before relying on auto-labeling or adaptive scopes.
