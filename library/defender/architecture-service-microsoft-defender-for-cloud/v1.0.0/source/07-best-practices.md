# 7. Best Practices — Architecture Service: Microsoft Defender for Cloud

Field-proven guidance for designing Defender for Cloud so it scales consistently, stays governed, and doesn't surprise you on cost.

## Enable at management-group scope, not subscription by subscription
- The whole point of the design is **inheritance**: enable plans at `MDC Scope – Platform MG – Prod` so every current and future subscription is protected automatically. Per-subscription enablement is exactly the drift this solution exists to prevent.
- Use the MG hierarchy and rollout **waves** to control blast radius — a plan enabled at a high node protects *and bills* every descendant.

## Design before you deploy — and keep the decision record
- Write `MDC Architecture Decision Record – Platform – Prod` first: the onboarding model, plan-per-wave matrix, RBAC, multicloud, export, and cost model. A rollout without a design record is how RBAC sprawl and cost surprises happen.
- Keep the record current as the architecture evolves — it is the map the next engineer (and the next audit) relies on.

## Deploy what-if first, always
- Every Bicep deployment runs `ARCMDC-Deploy.ps1 -WhatIf` (`az deployment mg what-if`) first; review the predicted changes; only then `-Apply`. Never blind-apply infrastructure that enables paid plans across an estate.
- Treat `main.bicep` as a **reference to adapt** to your naming/policy standards, source-controlled and peer-reviewed, not a one-off.

## Keep RBAC least-privilege by scope
- Map roles to jobs: **Security Reader** (read posture), **Security Admin** (manage plans/policies), **Owner/Contributor** at scope (enable paid plans), **Management Group Contributor** (deploy). Grant at the **narrowest** MG node and prefer PIM eligible activation over standing access.

## Make governance and exemptions explicit
- Use `MDC Governance – Platform MG – Prod` to assign owners and due dates so recommendations are accountable at scale. Every exemption is **justified and time-bound** — never a silent, permanent suppression. *Whether an exemption is acceptable is the security/compliance team's decision.*

## Export once, centrally, to the SIEM
- Stream recommendations, Secure Score, and alerts to a **central** Log Analytics workspace and onward to the SIEM (`MDC Continuous Export – Platform MG – Prod`). One central export beats per-subscription exports for trending, hunting, and correlation.

## Model cost before you roll out, and name a budget owner
- Paid plans bill per resource/node/transaction. Use `ARCMDC-Report.ps1 -Mode Cost` to estimate from real counts, sequence expensive plans into later waves, and get a **named finance owner** to accept the spend. **Whether a cost is acceptable is finance's decision** — the model informs it.
- **Verify current plan pricing and availability in your tenant** — the model is an estimate, not a quote.

## Add multicloud after the Azure pilot is solid
- Connect AWS/GCP (`MDC Connector – AWS Prod – Prod` / `– GCP Prod – Prod`) in their designed wave, once the Azure onboarding model, RBAC, and export are proven. Multicloud connectors give posture and the available plans — not a substitute for each cloud's deep native controls.

## Where to go next
Once the architecture is deployed and inheriting, natural next steps in the catalog:
- **Microsoft Defender for Cloud — CSPM & Secure Score Remediation** to *operate* posture and drive Secure Score on the platform this design stands up.
- **Microsoft Defender for Cloud — Workload Protection Plans** to deepen the CWPP (Servers/Storage/Containers/SQL) coverage the waves enable.
- **Azure Security Baseline & Governance** to enforce secure configuration with Azure Policy guardrails alongside Defender for Cloud.
- The **Sentinel** solutions to turn the continuous-export/SIEM feed into hunting and SOAR.
