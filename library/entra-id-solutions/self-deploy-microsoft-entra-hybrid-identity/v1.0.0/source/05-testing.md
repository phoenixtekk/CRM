# 5. Testing, Knowledge-Check & Take-Home Runbook — Self-Deploy: Microsoft Entra Hybrid Identity

Because this is an self-deploy, "testing" means **validating the labs worked** and **confirming the
team learned** (a knowledge-check). This guide also assembles the **take-home hybrid-identity runbook**.
Reference the scripts by name throughout.

## Part A — Lab validation procedures

### V1. Baseline & prerequisites (Lab 0)
- Run `EKHYBID-Validate.ps1`. **Pass:** Graph module OK, read role sufficient, AD module present (if
  doing AD-side labs), licensing detected — no FAILs.
- Run `EKHYBID-Discovery.ps1`. **Pass:** a baseline prints (engine, sync enabled, last sync time,
  federated/managed domains, UPN flags) with no script errors.

### V2. Engine, anchor, UPN (Labs 1–2)
- The team can point to the sync engine in the portal and state the correct choice for the scenario.
- **Source anchor:** confirmed as `ms-DS-ConsistencyGuid` (or the gap is noted). **UPN hygiene:** the
  `.local` UPN count is **0** (or remediation is noted). **Pass:** all three inspected and recorded.

### V3. Authentication method (Lab 3)
- The team can name the current method and describe the staged-rollout federation→cloud sequence and
  its rollback point. **Pass:** the sequence is written into the runbook correctly.

### V4. Hybrid join + hybrid CA (Labs 4–5)
- Entra → **Devices** shows hybrid-joined device counts; `dsregcmd /status` on a test device is read
  correctly. **Pass:** join state interpreted.
- Entra → **Conditional Access → Policies**; confirm `CA – Hybrid Pilot – Require Compliant/Hybrid
  Device (Report-only)` is **Report-only**, scoped to `Hybrid Identity – Pilot – Lab`, break-glass
  excluded. Sign in as a pilot user, then check **Conditional Access → Insights and reporting
  (report-only workbook)**. **Pass:** the sign-in shows the report-only result *before* any enforcement.

### V5. Health check + scorecard (Labs 6–7)
- Run `EKHYBID-HealthCheck.ps1`. **Pass:** every signal is returned and the team can interpret each
  (last sync time within window, federated-domain count, UPN issues, PTA/SSO hints).
- Run `EKHYBID-Report.ps1 -OutputPath .\EKHYBID-Scorecard`. **Pass:** CSV + HTML produced and open
  cleanly.
- (Optional) Run two or three queries from `EKHYBID-Signals.kql`. **Pass:** queries run without syntax
  errors and return rows (or a clean empty result).

## Part B — Knowledge-check (the team should be able to answer)
1. When do you choose **Entra Connect Sync** over **Entra Cloud Sync**, and vice versa?
2. What is the **source anchor**, which attribute is the modern default, and what goes wrong if it is
   mismatched?
3. Why must UPNs use a **verified, routable** domain? What is the symptom of a `.local` UPN in the cloud?
4. Compare **PHS**, **PTA**, and **Federation** on resilience, security, and maintenance. Why is PHS
   recommended as a **backup** even when another method is primary?
5. Lay out the safe, staged sequence to move a **federated** domain to **cloud authentication**, and
   name the rollback point.
6. Explain **hybrid Entra join**: what advertises the tenant, how a device registers, and what
   `dsregcmd /status` fields you check.
7. What does a healthy hybrid setup look like on the **health check** (last sync time, sync errors,
   federated domains, UPN issues), and what thresholds trigger action?

*(Suggested pass mark: the team answers 6 of 7 without notes.)*

## Part C — Take-home hybrid-identity runbook (fill in during the kit)
Assemble a runbook the team keeps. Capture, for your environment:

- **Baseline** — the `EKHYBID-Discovery.ps1` and `EKHYBID-Report.ps1` output (dated).
- **Engine** — Connect Sync vs Cloud Sync, the host(s), and why.
- **Sync scope** — which OUs/domains are in scope; what is deliberately excluded.
- **Source anchor** — confirmed attribute and any consolidation action needed.
- **UPN hygiene** — verified domain(s), UPN suffix state, and any `.local` remediation.
- **Authentication method** — current method, target method, and the staged-rollout plan with rollback.
- **Hybrid join** — coverage, pending devices, and the enablement plan.
- **Hybrid Conditional Access** — the report-only policy and its ring plan to enforcement.
- **Health-check routine** — the signals, thresholds, and cadence (who runs `EKHYBID-HealthCheck.ps1`
  and how often).
- **Hand-offs** — HYBID for build-out; the source-anchor and Cloud Sync troubleshooting solutions for
  deep fixes; ENTZTCA for the CA baseline; EKIDMOD for the broader modernization journey.

A completed runbook + a passed knowledge-check = the kit's success criteria.
