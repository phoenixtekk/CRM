# 3. Design & Implementation Guide — Architecture Service: Microsoft Defender for Cloud

Follow these steps **in order**. Steps 1–2 produce the **reference design** (the decision/design record); Steps 3–7 **deploy it in waves** with the included Bicep, **what-if first**, in the **Azure portal** (`https://portal.azure.com`) and the Azure CLI/PowerShell. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and IaC parameter.

> **Model:** Design the reference, validate it on the **pilot scope** `MDC Scope – Pilot MG – Pilot` with `what-if`, confirm inheritance and coverage, then expand wave by wave across the management-group hierarchy and to AWS/GCP. Every deployment is **`what-if` / plan first** and approval-gated. **Which standards, exemptions, and costs are acceptable are the compliance / security / finance teams' decisions.**

## Naming (set once, reuse verbatim)
- Platform (target) management group: `MDC Scope – Platform MG – Prod`
- Pilot management group / subscription: `MDC Scope – Pilot MG – Pilot`
- Continuous export: `MDC Continuous Export – Platform MG – Prod`
- Governance rule (recommendation ownership): `MDC Governance – Platform MG – Prod`
- Multicloud connectors: `MDC Connector – AWS Prod – Prod`, `MDC Connector – GCP Prod – Prod`
- Design/decision record: `MDC Architecture Decision Record – Platform – Prod`

## Step 1 — Assess: map the estate, current state, and cost inputs
1. `portal.azure.com` → **Management groups**. Map the hierarchy and where subscriptions sit; identify the target node `MDC Scope – Platform MG – Prod` and the pilot `MDC Scope – Pilot MG – Pilot`.
2. Run `ARCMDC-Discovery.ps1` to capture, read-only: the MG hierarchy, per-subscription Defender-for-Cloud plan tiers, registered providers, Log Analytics workspaces, existing connectors, and resource counts by type (the cost drivers).
3. Run `ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline` to record the current coverage baseline, and `ARCMDC-Report.ps1 -Mode Cost` for an indicative paid-plan estimate from the discovered counts.

## Step 2 — Design: produce the reference architecture and decision record
1. Write the **decision/design record** `MDC Architecture Decision Record – Platform – Prod` capturing:
   - **Onboarding model** — which MG node plans are enabled at, and how inheritance covers current + future subscriptions.
   - **Plan-per-wave matrix** — foundational CSPM (all), Defender CSPM, and each workload plan (Servers, Storage, Containers, Key Vault, App Service, SQL, …) mapped to a rollout **wave**. *Verify current plan availability/pricing.*
   - **RBAC model** — Security Reader (read posture) / Security Admin (manage plans+policies) / Owner or Contributor at scope (enable paid plans) / Management Group Contributor (deploy) — least privilege by scope.
   - **Multicloud** — which AWS accounts / GCP projects connect, and in which wave.
   - **Continuous export / SIEM** — what is exported (recommendations, Secure Score, alerts) to which workspace and onward to the SIEM.
   - **Cost model** — the drivers and the indicative estimate, with the named budget owner.
2. Parameterize the included **`main.bicep`** to match the design (target MG, plans per wave, workspace, export). This is the deployable form of the design.

## Step 3 — Pilot deploy: enable plans on the pilot scope (what-if first)
1. **Preview** the Bicep against the pilot scope — run `ARCMDC-Deploy.ps1 -Scope 'MDC Scope – Pilot MG – Pilot'` (defaults to **`-WhatIf`**, i.e. `az deployment mg what-if`). Review exactly which plans would be set.
2. When the what-if is understood and approved, re-run with **`-Apply`** to enable the wave-1 plans on the pilot scope only.
3. Confirm the **Microsoft.Security** provider is registered on pilot subscriptions (the deployment/policy can drive this) — `ARCMDC-Validate.ps1`.

## Step 4 — Wire RBAC and governance on the pilot
1. Assign the **least-privilege roles** from the design at the pilot scope (Security Reader / Security Admin / Owner-Contributor).
2. **Microsoft Defender for Cloud → Governance rules → Create** → `MDC Governance – Platform MG – Prod` at the pilot scope: assign owners and due dates so recommendations are accountable. Structure the **exemption** policy (justified, time-bound) — *whether an exemption is acceptable is the security/compliance team's decision.*

## Step 5 — Stand up continuous export / SIEM on the pilot
1. **Microsoft Defender for Cloud → Environment settings → (pilot scope) → Continuous export** → create `MDC Continuous Export – Platform MG – Prod` exporting **recommendations, Secure Score, and alerts** to the central Log Analytics workspace.
2. Confirm the workspace feeds the **SIEM** (data connector / workspace ingestion). Run `ARCMDC-Validate.ps1` → confirms export configured and data path present.

## Step 6 — Validate the pilot (inheritance, coverage, RBAC, export)
1. Run `ARCMDC-Validate.ps1` → confirms plans enabled at the pilot scope, **inheritance** working (a subscription under the pilot MG shows the inherited plan), providers registered, governance rule present, and continuous export configured.
2. Run `ARCMDC-Report.ps1 -Mode Coverage -BaselinePath .\arcmdc-baseline.json` → confirms coverage rose on the pilot scope, and `-Mode Cost` to compare actual-vs-estimated drivers. Complete the **Testing Guide** before expanding.

## Step 7 — Expand: roll out waves across the hierarchy (and multicloud)
1. Re-target `main.bicep` at `MDC Scope – Platform MG – Prod` and deploy **wave by wave** — always `ARCMDC-Deploy.ps1` (`-WhatIf`) first, then `-Apply` — so new and existing subscriptions inherit each wave's plans.
2. Add **AWS/GCP connectors** (`MDC Connector – AWS Prod – Prod`, `MDC Connector – GCP Prod – Prod`) in their designed wave, after the Azure pilot is validated. *Verify current connector requirements.*
3. Roll the RBAC model, governance rule, and continuous export out to the expanded scope.
4. Re-baseline with `ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline` after each wave and track coverage/cost drift. Update the decision record as the architecture evolves.

---
### Order of operations
`Assess estate + cost → design (decision record + Bicep) → pilot deploy plans (what-if→apply) → RBAC + governance → continuous export/SIEM → validate inheritance/coverage → expand waves across the MG hierarchy (+ AWS/GCP)`
