# 8. Deliverables Summary — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

## What you receive
A complete, self-guided package to govern AI interactions from the **DSPM-for-AI** experience in
Microsoft Purview — visibility into AI usage, sensitivity-label protection Copilot honors, a **DLP-for-AI
policy piloted in test/simulation**, and the recommended **insider-risk / communication-compliance**
detections for risky AI usage — piloted on a ring, validated, then enforced, using the Purview portal,
Security & Compliance PowerShell, and Microsoft Graph.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The DSPM-for-AI levers (visibility/audit, label protection for Copilot, DLP-for-AI, insider-risk/communication-compliance detections, endpoint/browser signals), the naming convention, and the deployment model — with the preview/evolving caveats. |
| **Requirements Guide** | Solution-specific prerequisites (DSPM-for-AI/E5 licensing, least-privilege roles per control, S&C PowerShell + Graph, unified audit enabled, a label taxonomy Copilot can honor, a pilot ring + simulation commitment, optional endpoint/browser onboarding, and a privacy-by-design/case-handling decision) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess → enable audit (visibility) → design the policy set → confirm Copilot honors labels → DLP-for-AI in **test** on the pilot ring → insider-risk + communication-compliance detections (portal, privacy-by-design) → optional consumer-AI egress signals → validate → expand/enforce → operate. Each step named, gated, reversible; `-WhatIf`/simulation first. |
| **Testing & Validation Guide** | 8 pass/fail tests — visibility on, Copilot honors labels, DLP in simulation (never Enable), DLP simulates the right matches, risky-AI detections raise reviewable signals, consumer-AI egress surfaced, enforcement deliberate/reversible, and reports complete. |
| **Best Practices** | Visibility-before-control, simulate-first rollout discipline, privacy-by-design for HR-sensitive detections, operating the program, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (no AI activity, Copilot surfaces content it shouldn't, DLP not matching or blocking too much, detections silent, consumer-AI not surfacing, preview/portal drift) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell) and/or `Connect-MgGraph`;
read-only or `-WhatIf` by default, writes gated behind `-Commit`. No credentials in code. Much of DSPM
for AI is **portal-driven** — the scripts cover what is reliably scriptable and point to the portal for
the rest; no cmdlets are invented.

| Script | Role | Default |
|---|---|---|
| `AIHUB-Discovery.ps1` | **Posture assessment** — report unified-audit state, presence of AI-interaction activity in the audit log, the sensitivity-label taxonomy (that Copilot honors), existing DLP policies + mode, and endpoint/extension readiness signals. | Read-only |
| `AIHUB-Config.ps1` | **Configuration / remediation helper** — enable unified audit, create the DLP-for-AI policy in **TestWithoutNotifications** scoped to the pilot ring (condition: a target label), and change a DLP policy's mode (test ↔ enforce). Portal one-click detections (insider risk / comms compliance) are flagged with exact portal steps. | `-WhatIf` |
| `AIHUB-Validation.ps1` | **Effective-settings validation** — confirm audit enabled, the DLP-for-AI policy is in a **Test** mode (never Enable during pilot), scoped to the pilot ring, and the target label exists. | Read-only |
| `AIHUB-Report.ps1` | **Activity / evidence** — export AI-interaction activity from the audit log and the DLP-for-AI match summary over N days to CSV. | Read-only |
| `AIHUB-Readiness.ps1` | **Scope/health helper** — licensing signal, audit on, endpoint/extension onboarding reminder, DLP-for-AI pilot-scope sanity (stranded-in-test or premature-enforce), and preview flag. | Read-only |

## Outcomes
- **Visibility** into AI usage across the tenant, captured and reportable as evidence.
- **Sensitivity-label protection** Copilot honors, plus a **DLP-for-AI** control that keeps the most
  sensitive labeled content out of AI — piloted in **simulation** before enforcement.
- **Risky-AI detections** (insider risk / communication compliance) configured **privacy-by-design** with
  role separation — raising reviewable signals, outcomes deferred to HR/legal.
- Optional **consumer-AI egress** signals for onboarded devices.
- Repeatable read-only tooling to report AI activity and catch drift over time.

## Explicitly out of scope (deferred)
- **What AI usage is acceptable, which content must be withheld from AI, and case adjudication** —
  governance/compliance/privacy/legal and HR determinations; this solution provides the detection method,
  configuration, and evidence, not the decisions.
- **The label taxonomy, broad DLP program, full insider-risk / communication-compliance programs, and
  eDiscovery** — assumed to exist or covered by separate Purview solutions; this solution configures the
  **AI-specific** governance over them.
- Any capability your **licensing/tenant** does not include or that is **in preview** — verify before
  relying on it; DSPM for AI is new and evolving.
