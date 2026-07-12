# 3. Implementation Guide — Microsoft Defender for Cloud

Follow the phases **in order**: **A) Architect → B) Protect (workload plans) → C) Enable the team →
D) Prove value**, then **Expand**. Most work is in the **Azure portal**
(`https://portal.azure.com → Microsoft Defender for Cloud`) with **Az PowerShell** helpers and the
reference **Bicep**; alerts also surface in the unified Defender portal (`security.microsoft.com`).
Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and
IaC parameter.

> **Model:** Design the reference, validate it on the **pilot scope** `MDC Scope – Pilot MG – Pilot` with
> `what-if`, enable and tune the workload plans on the pilot subscription, train the team on the pilot,
> run a benign PoC, and only then expand wave by wave across the hierarchy and to AWS/GCP. Every
> deployment is **`what-if` / plan first**, paid plans are **cost-gated**, and automated **response**
> stays notify/approval-gated. Never blind-apply infrastructure or auto-remediate a production workload
> to "test." **Posture remediation (Secure Score backlog) is the CSPM & Secure Score Remediation
> solution — cross-reference it, do not duplicate it here.**

## Naming (set once, reuse verbatim)
- Platform (target) management group: `MDC Scope – Platform MG – Prod`
- Pilot management group / subscription: `MDC Scope – Pilot MG – Pilot`
- Pilot subscription for workload plans: `MDC Workload Plans – Pilot Subscription – Pilot`
- Design/decision record: `MDC Architecture Decision Record – Platform – Prod`
- Continuous export: `MDC Continuous Export – Platform MG – Prod`
- Governance rule: `MDC Governance – Platform MG – Prod`
- Multicloud connectors: `MDC Connector – AWS Prod – Prod`, `MDC Connector – GCP Prod – Prod`
- Alert suppression rule: `MDC Alert Suppression – Benign FP – Prod`
- Response workflow (Logic App): `MDC Workload Response – Tenant – Prod`
- Hunting saved query: `MDC Workload Alert Validation – Tenant – Validate`
- Lab artifacts: `SecureScore-Shortlist – Cloud Lab – Pilot`, `Recommendations – Cloud Lab – Pilot`, `Alerts-Triage – Cloud Lab – Pilot`, `SecureScore-Trend – Cloud Lab – Pilot`, `Compliance-Evidence – Cloud Lab – Pilot`
- PoC objects: `MDC PoC – Pilot RG – Pilot`, `MDC PoC Test Resource – Pilot RG – Pilot`, `MDC PoC Scorecard – Pilot Sub – Validate`, tag `MDC-PoC-TESTSIGNAL`

---

# Phase A — Architect (design + reference Bicep)

## Step A1 — Assess: map the estate, current state, and cost inputs
1. `portal.azure.com → Management groups`. Map the hierarchy and where subscriptions sit; identify the
   target node `MDC Scope – Platform MG – Prod` and the pilot `MDC Scope – Pilot MG – Pilot`.
2. Run `MDCFULL-Discovery.ps1` to capture, read-only: the MG hierarchy, per-subscription Defender-for-
   Cloud plan tiers, registered providers, Log Analytics workspaces, existing AWS/GCP connectors, agent
   coverage, and resource counts by type (the cost drivers).
3. Run `MDCFULL-Report.ps1 -Mode Coverage -SaveBaseline` to record the current coverage baseline, and
   `MDCFULL-Report.ps1 -Mode Cost` for an indicative paid-plan estimate. *Verify current pricing.*

## Step A2 — Design: produce the reference architecture and decision record
1. Write `MDC Architecture Decision Record – Platform – Prod` capturing:
   - **Onboarding model** — which MG node plans are enabled at, and how inheritance covers current +
     future subscriptions.
   - **Plan-per-wave matrix** — foundational CSPM (all), Defender CSPM, and each workload plan (Servers,
     Containers, Databases, Storage, Key Vault, App Service, Resource Manager) mapped to a rollout
     **wave**. *Verify current plan availability/pricing.*
   - **RBAC model** — Security Reader (read posture) / Security Admin (manage plans+policies) / Owner or
     Contributor at scope (enable paid plans) / Management Group Contributor (deploy) — least privilege
     by scope.
   - **Multicloud** — which AWS accounts / GCP projects connect, and in which wave.
   - **Continuous export / SIEM** — what is exported (recommendations, Secure Score, alerts) to which
     workspace and onward to the SIEM.
   - **Cost model** — the drivers and the indicative estimate, with the named budget owner.
2. Parameterize the included **`main.bicep`** to match the design (target MG, plans per wave, workspace,
   export). This is the deployable form of the design — a **reference to adapt**, not a blind apply.

## Step A3 — Pilot deploy: enable plans on the pilot scope (what-if first)
1. **Preview** the Bicep against the pilot scope — `MDCFULL-Deploy.ps1 -ManagementGroupId '<pilotMgId>'
   -Wave 1` (defaults to **`-WhatIf`**, i.e. `az deployment mg what-if`). Review exactly which plans
   would be set — expect **only** the intended wave-1 enablements at the pilot scope.
2. When the what-if is understood and approved, re-run with **`-Apply`** to enable the wave-1 plans on
   the pilot scope only.
3. Confirm **Microsoft.Security** is registered on the pilot subscriptions (the deployment/policy can
   drive this) — `MDCFULL-Validate.ps1`.

## Step A4 — RBAC and governance on the pilot
1. Assign the **least-privilege roles** from the design at the pilot scope (Security Reader / Security
   Admin / Owner-Contributor).
2. **Microsoft Defender for Cloud → Governance rules → Create** → `MDC Governance – Platform MG – Prod`
   at the pilot scope: assign owners and due dates so recommendations are accountable. Structure the
   **exemption** policy (justified, time-bound). *Whether an exemption is acceptable is the
   security/compliance team's decision.*

---

# Phase B — Protect (workload protection plans / CWPP)

## Step B1 — Enable the workload plans on the pilot subscription
1. Choose the pilot subscription and record it as `MDC Workload Plans – Pilot Subscription – Pilot`
   (a subscription under `MDC Scope – Pilot MG – Pilot`). Confirm **cost approval** for the pilot scope.
2. Azure portal → **Microsoft Defender for Cloud → Environment settings → [pilot subscription] →
   Defender plans**. Turn **On** the plans in scope at the appropriate tier: **Servers** (P1 or P2),
   **Containers**, **Databases** (SQL / open-source / Cosmos DB), **Storage**, **Key Vault**,
   **App Service**, **Resource Manager**. *Verify current plan tiers and pricing.*
3. Preview and apply with the preview-gated helper: `MDCFULL-Deploy.ps1 -SubscriptionId '<pilot>' -Plans
   Servers,Containers,StorageAccounts,SqlServers` (safe **`-WhatIf`** preview by default; `-Apply` to
   enable per-subscription via `Az.Security`).
4. Run `MDCFULL-Validate.ps1 -Plan All` to confirm the plans are **On** on the pilot subscription.

## Step B2 — Wire Defender for Servers (MDE + agents)
1. **Environment settings → [pilot] → Defender plans → Servers → Settings** — confirm the **Defender for
   Endpoint** integration and monitoring-agent auto-provisioning are **On**. Connect non-Azure servers
   via **Azure Arc**. *Verify current agent/extension requirements.*
2. Run `MDCFULL-Validate.ps1 -Plan Servers` to confirm agent/MDE coverage across the pilot servers.

## Step B3 — Configure continuous export
1. **Environment settings → [pilot] → Continuous export** — export **Security alerts, recommendations,
   and Secure Score** to `MDC Continuous Export – Platform MG – Prod` (and optionally the SIEM/Event
   Hub).
2. Confirm export is active and data begins landing in the workspace.
3. Run `MDCFULL-Validate.ps1 -Plan Export` to confirm continuous export is configured.

## Step B4 — Tune alerts (suppression + notifications)
1. **Microsoft Defender for Cloud → Security alerts** — review the alerts appearing on the pilot; for
   known-benign patterns create the suppression rule `MDC Alert Suppression – Benign FP – Prod` (scoped,
   documented — never over-broad).
2. **Environment settings → [pilot] → Email notifications** — set the recipients and the severity
   threshold so the SOC gets high-severity alerts.
3. Run `MDCFULL-Report.ps1 -Mode Alerts` to capture the current alert inventory and suppression posture.

## Step B5 — Add a notify-only response workflow
1. **Microsoft Defender for Cloud → Workflow automation → Add workflow automation** — create
   `MDC Workload Response – Tenant – Prod` triggered on high-severity alerts, calling a Logic App that
   **notifies / creates a ticket** (Teams, email, ITSM). **No auto-remediation** during the pilot.
2. Run `MDCFULL-Validate.ps1 -Plan Workflow` to confirm the workflow exists and is notify-only.
3. *The decision to add any auto-remediation is the SOC/security team's — this guide leaves the workflow
   notify/approval-gated.*

---

# Phase C — Enable the team (labs, runbook, knowledge-check)

Run the labs in order against the **pilot subscription**. All steps are **read-only or preview-first /
`-WhatIf`**; any plan-enable or Fix is **facilitator-driven, `-WhatIf` first, and approval-gated**. The
KQL pack is `MDCFULL-LabPack.kql` (run ARG sections in **Resource Graph Explorer**, Defender-alert
sections in **Advanced hunting**). *Microsoft moves portal blades periodically — verify current
navigation in your tenant.*

## Lab 0 — Readiness check (Assess)
1. Open **Microsoft Defender for Cloud → Overview** for the pilot subscription. Confirm Secure Score
   shows a value and at least one Defender plan is On.
2. Run `MDCFULL-Discovery.ps1 -SubscriptionId '<pilot sub id>'` and `MDCFULL-Validate.ps1 -SubscriptionId
   '<pilot sub id>'` — confirm plan tiers, Secure Score, provider registration, and connectors report,
   and readiness checks pass.

## Lab 1 — Secure Score & recommendations
**Goal:** read the score, prioritize recommendations by impact, interpret a Fix.
1. **Defender for Cloud → Secure Score** — discuss what the weighted score represents and where the
   points are.
2. **Recommendations** — sort by **Potential score increase / impact**; walk 3–5 top items (what is
   wrong, which resources, the **Fix** action — *do not apply it yet*).
3. Discuss risk beyond raw score: an **attack-path**-linked or internet-exposed finding outranks an
   isolated low-severity one.
4. In **Resource Graph Explorer**, run the **Recommendations** section of `MDCFULL-LabPack.kql`; **Save
   as `Recommendations – Cloud Lab – Pilot`**.
5. Start the `SecureScore-Shortlist – Cloud Lab – Pilot` — top recommendations by impact/effort.
   **Remediation and change approval belong to the customer's cloud-ops/security functions — this is the
   CSPM & Secure Score Remediation solution's program.**

## Lab 2 — Workload-protection alerts
**Goal:** understand the Defender plans and triage a security alert.
1. **Environment settings → [pilot] → Defender plans** — review which CWPP plans exist and what each
   protects. *Several are paid — verify pricing/availability.*
2. **Security alerts** — if empty, use the portal **sample alerts** action (pilot only) to generate
   benign alerts.
3. Triage one alert: severity, affected resource, the **MITRE** tactic/technique, the activity, and the
   first response step.
4. In Advanced hunting / ARG, run the **Alerts triage** section of `MDCFULL-LabPack.kql`; **Save as
   `Alerts-Triage – Cloud Lab – Pilot`**.
5. Discuss the hand-off: MDC alerts flow to Defender XDR / Sentinel; the SOC owns the incident decision.

## Lab 3 — Regulatory compliance
**Goal:** read the compliance dashboard and export evidence — read-only.
1. **Defender for Cloud → Regulatory compliance** — review the standards assigned and pass/fail
   controls.
2. Pick one standard; drill into a failing control to see mapped recommendations and affected resources.
3. Export the compliance report/evidence (PDF/CSV where offered) as `Compliance-Evidence – Cloud Lab –
   Pilot` — read-only.
4. **Boundary:** *which* standards apply and whether a gap/exemption is acceptable are the **compliance
   team's** determination — the labs show how to read and evidence, not what to certify.

## Lab 4 — Multicloud connectors
**Goal:** understand how AWS/GCP connectors extend posture.
1. **Environment settings** — if an AWS/GCP connector exists, open it; review the account, enabled
   plans, and its recommendations in the unified list.
2. If none exists, walk the **concept**: a connector uses a cross-cloud role/identity to read the other
   cloud's config, mapping its findings into the same Secure Score/recommendation model.
3. Discuss scope honestly: multicloud here is **high-level posture**; deep per-cloud workload protection
   is a larger, separate effort.

## Lab 5 — Remediation cadence & reporting (preview-first)
**Goal:** build a prioritized shortlist, rehearse an enable/Fix in `-WhatIf`, produce a trend report.
1. Finalize `SecureScore-Shortlist – Cloud Lab – Pilot`: top 3–5 items with owner candidates and effort.
2. **Rehearse a change in preview (facilitator):** run `MDCFULL-Deploy.ps1 -SubscriptionId '<pilot sub
   id>' -Plans StorageAccounts` with **`-WhatIf`** (default) to see what enabling a plan *would* do — it
   makes **no** change. Discuss the real enable path and the rollback.
3. Run `MDCFULL-Report.ps1 -SubscriptionId '<pilot sub id>' -Mode Coverage` to produce a Secure-Score +
   recommendations report. Save the ARG trend query as `SecureScore-Trend – Cloud Lab – Pilot`.
4. Capture the operating cadence: how often to review score, who owns recommendations, and how drift is
   caught (continuous export / the trend query).
5. **Boundary:** the labs **do not enforce** posture changes. Enabling plans and applying Fixes at scale
   follow the customer's change process and the **CSPM & Secure Score Remediation** solution.

## Wrap-up
1. Confirm the take-home artifacts: the three saved queries, the shortlist, the compliance export, and
   the ops-notes.
2. Run the **knowledge-check** in `05-testing.md` (Part B).

---

# Phase D — Prove value (guided, benign proof-of-concept)

Run the PoC on **one pilot subscription** with the pilot RG `MDC PoC – Pilot RG – Pilot`. All signal is
**benign** (sample alerts + a benign misconfigured test resource + EICAR). Every change is **`-WhatIf`-
gated**; teardown **disables the paid plan to stop billing**. No other subscription is touched.

## Step D1 — Assess readiness (read-only)
1. `Connect-AzAccount` and select the pilot subscription.
2. Run `MDCFULL-PoC.ps1 -Action Assess` (a `-WhatIf` preview) — previews Azure roles, the pilot
   subscription, current plan state, and candidate resources.
3. Create/confirm the pilot RG `MDC PoC – Pilot RG – Pilot`. **Confirm the cost owner accepts the short
   Defender-plan billing window.**

## Step D2 — Enable CSPM + one workload plan on the pilot subscription
1. **Environment settings → (pilot subscription) → Defender plans** — turn on **CSPM** (foundational
   free; Defender CSPM paid — *verify pricing/availability*) and **one** workload plan (e.g. Defender for
   Servers or Storage) for the pilot subscription only.
2. Or run `MDCFULL-Deploy.ps1 -SubscriptionId '<pilot>' -Plans StorageAccounts -Apply` (preview-gated).
3. Confirm the plans show **On** for the pilot subscription.

## Step D3 — Generate benign test signal
1. Run `MDCFULL-PoC.ps1 -Action TestSignal -ResourceGroup 'MDC PoC – Pilot RG – Pilot' -DeployTestResource`
   (`-WhatIf` previews). It performs only **benign, documented** actions tagged `MDC-PoC-TESTSIGNAL`:
   - **Sample security alerts** — **Security alerts → Sample alerts** → select the pilot subscription →
     Create (Microsoft-provided, benign).
   - **Benign misconfiguration (CSPM)** — deploy `MDC PoC Test Resource – Pilot RG – Pilot` (e.g. a
     storage account with public blob access) so a **recommendation** is raised. It holds **no real
     data**.
   - **Workload threat (optional)** — on a pilot VM covered by Defender for Servers, drop the **EICAR**
     test file for a benign Defender-for-Servers alert.
2. **Never** attack real resources, deploy real malware, or expose real data. Note each signal's time
   for the scorecard latency comparison.

## Step D4 — Validate and demonstrate the detections
1. Run `MDCFULL-Validate.ps1 -PoC` — confirms (read-only) the **recommendation**, **Secure Score**,
   **security alerts** (sample + EICAR), and **regulatory-compliance** data.
2. In the portal, walk the demo: **Recommendations → Secure Score → Security alerts → Regulatory
   compliance** — the headline-capability demo for stakeholders.
3. Confirm nothing outside the pilot subscription was affected.

## Step D5 — Score against your criteria
1. Run `MDCFULL-PoC.ps1 -Action Scorecard -CriteriaPath .\criteria.json -OutFile 'MDC PoC Scorecard –
   Pilot Sub – Validate.json'` — maps each observation to your pass/fail criteria.
2. Review the scorecard with stakeholders — the decision artifact.

## Step D6 — Tear down (clean rollback + stop billing)
1. Run `MDCFULL-PoC.ps1 -Action Teardown -WhatIf` first to preview, then without `-WhatIf`.
2. Teardown **deletes** the test resource `MDC PoC Test Resource – Pilot RG – Pilot`, **disables** the
   Defender workload plan (sets it back to Free) on the pilot subscription **to stop billing**, and
   **resolves/dismisses** the `MDC-PoC-TESTSIGNAL` sample alerts.
3. Keep the scorecard as your record. Re-run `MDCFULL-Validate.ps1 -PoC` to confirm the plan is Off and
   the test resource is gone.

---

# Expand (across the hierarchy and multicloud)
1. **Plans (IaC):** re-target `main.bicep` at `MDC Scope – Platform MG – Prod` and deploy **wave by
   wave** — always `MDCFULL-Deploy.ps1` (`-WhatIf`) first, then `-Apply` — so new and existing
   subscriptions inherit each wave's plans, watching cost.
2. **Agents/export:** confirm agent provisioning and continuous export on each new subscription.
3. **Alerts/workflow:** extend the suppression rule and `MDC Workload Response – Tenant – Prod` tenant-
   wide; only after validation consider approval-gated auto-remediation with the SOC.
4. **RBAC/governance:** roll the RBAC model and `MDC Governance – Platform MG – Prod` out to the expanded
   scope.
5. **Multicloud:** add `MDC Connector – AWS Prod – Prod` / `MDC Connector – GCP Prod – Prod` in their
   designed wave, after the Azure pilot is validated. *Verify current connector requirements.*
6. **Team & posture:** apply the enablement runbook to onboard new engineers, and hand the Secure-Score
   remediation cadence to the **CSPM & Secure Score Remediation** solution.
7. Re-baseline with `MDCFULL-Report.ps1 -Mode Coverage -SaveBaseline` after each wave and track
   coverage/cost drift. Update the decision record as the architecture evolves.

---
### Order of operations
`Architect (assess estate + cost → design record + Bicep → pilot deploy plans what-if→apply → RBAC +
governance) → Protect (enable workload plans on pilot sub → Servers MDE/agents → continuous export →
tune alerts → notify-only response workflow) → Enable the team (Labs 0–5 + knowledge-check) → Prove value
(benign PoC: enable → signal → validate/demo → score → teardown that disables paid plans) → Expand waves
across the MG hierarchy (+ AWS/GCP)`
