# 6. Troubleshooting Guide — Microsoft Defender for Cloud

Common field issues across all four phases, in **symptom → cause → fix** form. Run
`MDCFULL-Discovery.ps1` and `MDCFULL-Validate.ps1` first — most causes surface there.

---

## Phase A — Architect

### What-if shows unexpected changes
**Symptom:** `MDCFULL-Deploy.ps1 -WhatIf` predicts changes beyond the intended plan enablements (or on
the wrong scope).
**Cause:** The Bicep parameters target the wrong management group, include plans not in the current wave,
or drift from the design record.
**Fix:** Re-parameterize `main.bicep` to the pilot scope and wave-1 plans only; reconcile against
`MDC Architecture Decision Record – Platform – Prod`; re-run the what-if until it shows **only** the
intended changes. Do **not** `-Apply` until it is clean.

### Plan not enabling at MG scope
**Symptom:** After `-Apply`, plans still show Off/Free at `MDC Scope – Pilot MG – Pilot`.
**Cause:** The deployment identity lacks **Owner / Contributor + Security Admin** at the MG scope, the
**Microsoft.Security** provider isn't registered, or the plan isn't available in the region/tenant.
**Fix:** Confirm the identity's role at the MG node (Requirement 2.2); register the provider; *verify the
plan's availability/pricing in your tenant.* Re-run `MDCFULL-Deploy.ps1 -Apply` and `MDCFULL-Validate.ps1`.

### Inheritance not applying
**Symptom:** A subscription under the pilot MG shows Free / no inherited plan.
**Cause:** The plan was set at **subscription** scope (or a lower MG) instead of the intended MG node, the
subscription overrides inheritance with its own setting, or the provider isn't registered on it.
**Fix:** Confirm the plan is set at the **management-group** scope; remove any conflicting per-subscription
override; register **Microsoft.Security** on the subscription. Re-check with `MDCFULL-Validate.ps1`.

### Provider not registered
**Symptom:** `MDCFULL-Validate.ps1` reports **Microsoft.Security** not registered on a subscription.
**Cause:** Never registered, or a new subscription joined without it.
**Fix:** `Register-AzResourceProvider -ProviderNamespace Microsoft.Security`, or let the MG-scope Azure
Policy auto-register it. Allow a few minutes and re-validate.

### RBAC sprawl / missing governance
**Symptom:** Over-broad roles (e.g. Owner where Security Reader suffices) or no governance rule at scope.
**Cause:** Roles granted ad-hoc during rollout, or Step A4 skipped.
**Fix:** Re-align role assignments to the least-privilege model; grant at the narrowest MG node; create
`MDC Governance – Platform MG – Prod` with owners/due dates and time-bound exemptions. Re-run
`MDCFULL-Validate.ps1`. *Exemption acceptability is the security/compliance team's decision.*

### Cost exceeds the model
**Symptom:** Actual MDC spend is well above `MDCFULL-Report.ps1 -Mode Cost`'s estimate.
**Cause:** A plan was enabled at a higher MG node than intended (billing more descendant resources),
resource counts grew, or a costly workload plan landed in an early wave.
**Fix:** Check where each plan is enabled in the MG hierarchy; move expensive plans to later waves or a
narrower scope; re-run the cost report with current counts; confirm with the budget owner. *Whether the
cost is acceptable is finance's decision.* Rollback: set the plan back to Free or remove the MG-scope
assignment.

---

## Phase B — Protect

### Plan will not enable (subscription scope)
**Symptom:** B1 fails — a workload plan stays **Off** or the enablement errors.
**Cause:** The account lacks **Security Admin / Owner** on the subscription, `Microsoft.Security` is not
registered, or a policy blocks the change.
**Fix:** Confirm the role (IAM); register the provider; check for a blocking Azure Policy. Re-run
`MDCFULL-Deploy.ps1 -SubscriptionId <pilot> -Plans … -Apply` and `MDCFULL-Validate.ps1 -Plan All`.

### Server agent not provisioned
**Symptom:** B2 fails — pilot servers show no MDE/monitoring agent, or detection is inactive.
**Cause:** Auto-provisioning is off, the monitoring agent/extension failed to deploy, or a non-Azure
server is not Arc-connected.
**Fix:** In **Defender plans → Servers → Settings**, enable auto-provisioning of the MDE integration and
monitoring agent; connect non-Azure servers via **Azure Arc**; check the extension deployment status on
the VM. *Verify current agent/extension requirements.* Re-run `MDCFULL-Validate.ps1 -Plan Servers`.

### Continuous export no data
**Symptom:** B3 fails — no alerts/recommendations/Secure Score land in `MDC Continuous Export – Platform
MG – Prod`, or the SIEM receives nothing.
**Cause:** Export is not configured, points at the wrong workspace, exports the wrong data types, no
alerts have fired yet, or the SIEM connector isn't wired.
**Fix:** Confirm **Environment settings → Continuous export** targets the workspace and exports Security
alerts + recommendations + Secure Score; confirm workspace permissions and the SIEM ingestion path; allow
warm-up and generate a benign alert (Phase D). Re-run `MDCFULL-Validate.ps1 -Plan Export`.

### Alert noise / too many alerts
**Symptom:** The pilot alert queue is overwhelming.
**Cause:** No alert tuning yet, or a benign workload behavior repeatedly triggers a detection.
**Fix:** Create **scoped, documented** suppression rules (`MDC Alert Suppression – Benign FP – Prod`) only
for genuinely benign patterns, set the notification severity threshold, and fix the underlying
misconfiguration where possible (CSPM). Re-run `MDCFULL-Report.ps1 -Mode Alerts`.

### Response workflow auto-remediated
**Symptom:** A workload was changed automatically during the pilot.
**Cause:** `MDC Workload Response – Tenant – Prod` was configured to remediate rather than notify.
**Fix:** Reset the workflow/Logic App to **notify / ticket-only** (Step B5), confirm with the SOC, and
re-validate (`MDCFULL-Validate.ps1 -Plan Workflow`). *The auto-remediation decision is the security
team's.*

---

## Phase C — Enable the team

### No workload alerts to triage
**Symptom:** Lab 2 has an empty Security alerts queue.
**Cause:** Plans newly enabled and warming up, or no threats/tests have occurred.
**Fix:** Confirm at least one plan is On; use the portal **sample alerts** action (pilot only) to
generate benign alerts; allow warm-up. Re-run `MDCFULL-Discovery.ps1`.

### Saved query returns nothing / ARG access denied
**Symptom:** A `MDCFULL-LabPack.kql` section returns no rows or errors on access.
**Cause:** The attendee lacks **Reader** (ARG honors resource RBAC), Secure Score hasn't populated, or an
ARG `securityresources` type/column shifted.
**Fix:** Grant Reader on the pilot; allow assessment warm-up; *verify current ARG schema in your tenant*;
for Defender-alert sections use **Advanced hunting** with an advanced-hunting-read role.

### Preview rehearsal appears to change something
**Symptom:** The Lab 5 `-WhatIf` rehearsal looks like it enabled a plan.
**Cause:** It was run **without** `-WhatIf` (the default is preview, but a `-Apply` slipped in).
**Fix:** The rehearsal must be `MDCFULL-Deploy.ps1 … ` **without** `-Apply` — it changes nothing. If a
plan was enabled, disable it (`MDCFULL-PoC.ps1 -Action Teardown` or set to Free in the portal).

---

## Phase D — Prove value (PoC)

### Plan not enabling
**Symptom:** CSPM or the workload plan does not turn **On** for the pilot subscription.
**Cause:** Insufficient role (needs Security Admin/Contributor/Owner), wrong subscription selected, or a
policy blocks the change.
**Fix:** Confirm your role (**Access control (IAM)**); `Set-AzContext` to the correct subscription; re-run
`MDCFULL-PoC.ps1 -Action Assess` and check the reported gaps.

### Signal not generated
**Symptom:** Sample alerts, the test resource, or EICAR did not generate.
**Cause:** The sample-alert action targeted the wrong subscription, the test-resource deployment failed
(naming/quota), or the pilot VM is not covered by Defender for Servers.
**Fix:** Create sample alerts against the pilot subscription; confirm the test resource deployed in
`MDC PoC – Pilot RG – Pilot`; confirm the VM is covered before using EICAR. Re-run `MDCFULL-PoC.ps1
-Action TestSignal`.

### No recommendation / No Secure Score / No security alert / No compliance data
**Symptom:** D3 fails — one or more of the four observations is missing.
**Cause:** Assessment/alert pipeline is still warming up, the resource isn't misconfigured in an assessed
way, the workload plan is off, the account lacks read permission, or the default benchmark isn't applied.
**Fix:** Allow warm-up (minutes to hours); confirm the test resource has the intended misconfiguration
(e.g. public blob access); confirm the workload plan is **On** and **Security Reader** is held; confirm
the Microsoft Cloud Security Benchmark is applied. *Some standards are plan-gated — verify availability.*
Re-run `MDCFULL-Validate.ps1 -PoC`.

### Teardown left residue
**Symptom:** After teardown, the test resource remains or the plan is still **On** (still billing).
**Cause:** Teardown ran in `-WhatIf` only, or a delete/disable failed on a permission.
**Fix:** Run `MDCFULL-PoC.ps1 -Action Teardown` **without** `-WhatIf`; confirm the plan shows **Off** in
**Environment settings → Defender plans** (this stops billing); delete `MDC PoC Test Resource – Pilot RG –
Pilot`; resolve the `MDC-PoC-TESTSIGNAL` alerts; re-confirm with `MDCFULL-Validate.ps1 -PoC`.

---

## All phases — script/auth

### Script or deployment cannot authenticate
**Symptom:** `MDCFULL-*.ps1` fails on connect/returns access-denied, or the MG deployment errors on
auth/scope.
**Cause:** The Az modules (`Az.Accounts`, `Az.Security`, `Az.Resources`, `Az.ResourceGraph`,
`Az.OperationalInsights`, `Az.Storage`) are missing, the account isn't signed in to the right
subscription/tenant, or it lacks the required role/MG-scope rights.
**Fix:** Let the script install the modules (it checks on run); `Connect-AzAccount` and `Set-AzContext` to
the right subscription; confirm **Security Reader** (read) / **Security Admin + Contributor** or MG-scope
Owner (change); for pipeline runs use a scoped deployment service principal. Re-run.
