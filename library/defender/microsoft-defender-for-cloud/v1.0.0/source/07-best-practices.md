# 7. Best Practices — Microsoft Defender for Cloud

Field-proven guidance for keeping the whole Defender for Cloud lifecycle designed, protective, tuned,
and cost-aware.

## Design before you deploy — and keep the decision record
- Write `MDC Architecture Decision Record – Platform – Prod` first (onboarding model, plan-per-wave
  matrix, RBAC, multicloud, export, cost model). A rollout without a design record is how RBAC sprawl
  and cost surprises happen. Keep it current as the architecture evolves — it is the map the next
  engineer and the next audit rely on.

## Enable at management-group scope, not subscription by subscription
- The whole point is **inheritance**: enable plans at `MDC Scope – Platform MG – Prod` so every current
  and future subscription is protected automatically. Per-subscription enablement is exactly the drift
  this solution exists to prevent. Use the MG hierarchy and rollout **waves** to control blast radius —
  a plan enabled at a high node protects *and bills* every descendant.

## Deploy what-if first, always; treat the Bicep as a reference to adapt
- Every Bicep deployment runs `MDCFULL-Deploy.ps1 -WhatIf` (`az deployment mg what-if`) first; review the
  predicted changes; only then `-Apply`. Never blind-apply infrastructure that enables paid plans across
  an estate. Source-control and peer-review `main.bicep`; verify the built-in initiative/definition ids
  in your tenant — they are versioned.

## Treat cost as a first-class decision, and name a budget owner
- Workload plans and Defender CSPM are **billed per resource/node/transaction**. Get cost approval for
  the pilot, track drivers with `MDCFULL-Report.ps1 -Mode Cost`, sequence expensive plans into later
  waves, and get a **named finance owner** to accept the spend. **Whether a cost is acceptable is
  finance's decision** — the model informs it. *Verify current plan pricing and availability in your
  tenant — the model is an estimate, not a quote.*

## Pair CWPP with CSPM, don't substitute — cross-reference the posture solution
- Workload protection **detects** attacks; CSPM **reduces** the attack surface. Keep both. Driving Secure
  Score, working the recommendation backlog, agentless scanning, and attack-path remediation at scale is
  the catalog's **Defender for Cloud — CSPM & Secure Score Remediation** solution — hand posture
  operations to it rather than duplicating that program here. Fixing posture lowers the alerts CWPP has
  to raise.

## Provision the Servers agents properly
- Defender for Servers detection is only as good as its **agents**. Confirm the MDE integration and
  monitoring agent auto-provision and stay healthy, and connect non-Azure servers via **Azure Arc** so
  multicloud/on-prem workloads are covered.

## Tune alerts so the SOC trusts them; keep response notify-first
- Untuned CWPP alerts become noise. Create **scoped, documented** suppression rules (`MDC Alert
  Suppression – Benign FP – Prod`) only for genuinely benign patterns, set sensible severities, and route
  high-severity alerts to the SOC. Start `MDC Workload Response – Tenant – Prod` as **notify / ticket-
  only** — auto-remediation of a production workload is disruptive and belongs to the SOC's decision,
  made only after the alerts are trusted.

## Export once, centrally, to the SIEM
- Stream recommendations, Secure Score, and alerts to a **central** workspace and onward to the SIEM
  (`MDC Continuous Export – Platform MG – Prod`). One central export beats per-subscription exports for
  trending, hunting, and correlation — and it is what feeds the labs' trend query and the SOC.

## Make governance and exemptions explicit
- Use `MDC Governance – Platform MG – Prod` to assign owners and due dates so recommendations are
  accountable at scale. Every exemption is **justified and time-bound** — never a silent, permanent
  suppression. *Whether an exemption is acceptable is the security/compliance team's decision.*

## Train against the pilot, preview-first; and prove value benignly
- Teach the team on the pilot with everything read-only or `-WhatIf`; only the facilitator demonstrates a
  change, and only in preview. Prove value with the **benign PoC** (sample alerts + a benign misconfig
  test resource + EICAR) — never a real attack, real malware, or exposed data — and **disable the paid
  plan at teardown** to stop billing. Diarise the teardown so a plan is never left on by accident.

## Add multicloud after the Azure pilot is solid
- Connect AWS/GCP (`MDC Connector – AWS Prod – Prod` / `– GCP Prod – Prod`) in their designed wave, once
  the Azure onboarding model, RBAC, and export are proven. Multicloud connectors give posture and the
  available plans — not a substitute for each cloud's deep native controls.

## Defer the decisions to the owners
- Which regulatory standards apply, whether a gap/exemption/cost is acceptable, remediation and
  incident-response approval, and production change control are **the customer's** compliance / finance /
  security / operations determinations. This solution delivers the technical build — the architecture,
  the workload protection, the trained team, and the proof — not the decision.

## Where to go next
Once MDC is architected, protecting workloads, team-run, and proven, natural next steps in the catalog:
- **Microsoft Defender for Cloud — CSPM & Secure Score Remediation** — the posture *program*: drive
  Secure Score, work the recommendation backlog, agentless scanning, and the remediation cadence at
  scale on the platform this solution stands up.
- **Microsoft Defender XDR — Unified Onboarding** to correlate cloud workload alerts with Endpoint,
  Identity, Office, and Cloud Apps.
- The **Microsoft Defender for Endpoint** — MDE powers Defender for Servers
  detection.
- The **SOC onboarding — Sentinel + Defender XDR** and **advanced KQL threat-hunting** solutions to turn
  the continuous-export/SIEM feed into hunting and SOAR.
- **Azure Security Baseline & Governance** to enforce secure configuration with Azure Policy guardrails
  alongside Defender for Cloud.
