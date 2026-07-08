# 8. Deliverables Summary — Mandatory vs Recommended Labeling Policy Design

## What you receive
A complete, self-guided package to **decide and configure where a sensitivity label is required versus
suggested** in Microsoft Purview — mandatory labeling, default labels, downgrade justification, and
recommended (prompt) labeling — piloted on a ring, validated, then expanded, using only the Microsoft
Purview portal and Security & Compliance PowerShell.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The four policy levers (mandatory, default, downgrade justification, recommended prompts), the mandatory-vs-recommended decision matrix, the naming convention, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (an existing label taxonomy, licensing for recommended labeling, Information Protection role, S&C PowerShell, a pilot ring, an agreed default classification and downgrade rule, and the per-app friction decision) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess posture → design the matrix → create/select the pilot policy → set the default label → enable mandatory (per-app) → require downgrade justification → configure recommend prompts on labels → validate friction → expand to the broad policy → report. Each step named, gated, and reversible; `-WhatIf` before every commit; pilot-first (no simulation mode). |
| **Testing & Validation Guide** | 10 pass/fail tests — effective settings, default application, mandatory prompts, per-app Outlook friction, downgrade justification + audit evidence, recommend (never force), policy-conflict check, and broad == accepted pilot. |
| **Best Practices** | Choosing mandatory vs recommended, no-simulation rollout discipline, defaults/downgrade/evidence, avoiding policy conflicts, program/change-management, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (mandatory not prompting, Outlook blocking send, default not applying, recommend forcing instead of suggesting, downgrade silent, policy conflicts) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell); read-only or `-WhatIf` by
default, writes gated behind `-Commit`. No credentials in code.

| Script | Role | Default |
|---|---|---|
| `IPMANREC-Discovery.ps1` | **Posture assessment** — inventory label policies, each policy's advanced settings (mandatory / default / Outlook) and scope, and each label's Office-app auto-labeling mode (Automatic vs Recommend). | Read-only |
| `IPMANREC-PolicyConfig.ps1` | **Configuration / remediation helper** — create the pilot policy, set the default label, enable/disable mandatory labeling (with per-app Outlook relaxation), require downgrade justification, and set a label to **Recommend** with a prompt message. | `-WhatIf` |
| `IPMANREC-Validation.ps1` | **Effective-settings validation** — confirm a policy's resolved advanced settings (mandatory, default, downgrade, Outlook) and a label's recommend mode match the signed-off design. | Read-only |
| `IPMANREC-Reporting.ps1` | **Posture matrix / evidence** — export the mandatory-vs-recommended matrix across all policies and labels (default label per policy, mandatory + downgrade state, recommend/automatic per label) to CSV. | Read-only |
| `IPMANREC-Health.ps1` | **Scope/health helper** — flag conflicting settings across overlapping policies, inconsistent default labels, policy-priority resolution, and pilot-scope sanity. | Read-only |

## Outcomes
- A signed-off **mandatory-vs-recommended matrix** configured in the tenant — mandatory where risk justifies friction, recommended where a nudge is enough.
- A **default label** so no new content is silently unclassified, and **downgrade justification** producing an audit trail.
- **Recommended-label prompts** that suggest the right label without forcing it.
- Settings **piloted on a ring** and validated for friction before broad expansion (the safe substitute for a non-existent simulation mode).
- Repeatable read-only tooling to report the posture and catch policy conflicts over time.

## Explicitly out of scope (deferred)
- **The label taxonomy, encryption, content marking, and retention labels** — assumed to exist (see the taxonomy/labels solutions); this solution designs the *policy behaviour* over them.
- **Service-side auto-labeling at scale, DLP policy authoring, insider risk, and communication compliance** — separate Purview solutions.
- **Which populations *should* be mandated, the enterprise default classification, and downgrade rules** — information-governance determinations owned by compliance/security/records; this solution provides the configuration method and evidence.
- Any capability your **licensing/tenant** does not include — verify before relying on recommended (client-side) labeling with advanced conditions.
