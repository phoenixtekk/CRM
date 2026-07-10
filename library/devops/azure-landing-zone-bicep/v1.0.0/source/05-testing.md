# 5. Testing — Azure Landing Zone with Bicep

Validate the landing zone against a **non-production** management group before you expand to production. Each test has an explicit **pass/fail gate**. Reference the scripts by name; they are read-only / what-if except where noted.

## Test 1 — Management-group hierarchy exists
- **How:** `powershell -ExecutionPolicy Bypass -File .\IACBICEP-Validate.ps1 -ManagementGroupId alz -Environment NonProd`, or in the portal open **Management groups**.
- **Pass:** `Platform – Tenant – Prod`, `Landing Zones – Tenant – Prod`, and `Sandbox – Tenant – NonProd` all appear under `alz`.
- **Fail:** Any group missing → re-run Step 3's what-if and check the `deployHierarchy` parameter and your R1 rights.

## Test 2 — Bicep builds and what-if is clean
- **How:** `az bicep build --file main.bicep` then `az deployment mg what-if ... --parameters deployHierarchy=true deployPolicy=true`.
- **Pass:** Build produces no errors; what-if shows **no unexpected deletes** and only the changes you intend.
- **Fail:** Build errors → check the pinned Bicep version (R2). Unexpected deletes in what-if → **stop**; do not deploy until you understand them.

## Test 3 — Guardrails assigned in AUDIT (not deny yet)
- **How:** `IACBICEP-Validate.ps1` reports every policy assignment and its effect; or **Policy → Assignments** at the management-group scope.
- **Pass:** `Guardrails Baseline – Landing Zones – Audit` exists with effect **Audit**.
- **Fail:** Effect already **Deny** during pilot → revert to audit (you have promoted too early). Assignment missing → re-run Step 4.

## Test 4 — Audit compliance picture is understood
- **How:** `az policy state trigger-scan --management-group alz`, then `IACBICEP-Report.ps1 -ManagementGroupId alz`.
- **Pass:** The report lists non-compliant resources; every one is either a real finding to fix or an intended exemption. No surprises.
- **Fail:** Compliance state still `NotStarted` → wait and re-scan (evaluation is not instantaneous). Unexpected non-compliance → resolve or exempt **before** considering deny.

## Test 5 — Least-privilege RBAC baseline
- **How:** `IACBICEP-Validate.ps1` reports the custom role and standing Owner count; or **Access control (IAM) → Role assignments**.
- **Pass:** `Landing Zone Contributor – Platform – Baseline` is assigned at `Platform – Tenant – Prod`; standing Owner assignments are only the intended break-glass account(s).
- **Fail:** Extra standing Owners → plan their controlled removal (Step 5). Custom role missing → re-run the RBAC module.

## Test 6 — Hub-spoke connectivity and DNS
- **How:** `IACBICEP-Validate.ps1` checks peering state and DNS-zone links; or **Virtual networks → Peerings**.
- **Pass:** `Hub Network – Connectivity – Prod` and `Spoke Network – Workload01 – NonProd` exist; peerings are **Connected** both directions; the private DNS zones are linked to the hub.
- **Fail:** Peering `Disconnected` → address-space overlap or a one-sided peering (R5); re-check ranges and re-deploy the network module.

## Test 7 — Deployment stack tracks and can roll back
- **How:** `az stack mg show --name "alz-stack – Sandbox – NonProd" --management-group-id alz`.
- **Pass:** The stack lists its managed resources; a `what-if` of an `az stack ... delete`/`update` shows exactly what would be removed/reverted.
- **Fail:** Stack not found → you deployed with plain `az deployment` instead of `az stack`; redeploy via the stack so rollback is available.

## Test 8 — Pipeline enforces what-if and approval
- **How:** Push a trivial parameter change on a branch; open a PR; watch the pipeline.
- **Pass:** **Validate** and **What-If** run automatically and post the preview; the **Deploy** stage **pauses at the approval gate** (R7) and only proceeds after an approver signs off.
- **Fail:** Deploy runs without pausing → the environment approval check is not attached to the production stage; fix in the pipeline environment configuration.

## Exit criteria
All eight tests pass against the non-production management group, the audit compliance picture is clean or fully exempted, and the pipeline pauses for approval — **only then** expand to production and (after the soak period) promote guardrails to deny.
