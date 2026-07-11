# 6. Troubleshooting — Security Optimization Assessment: Defender for Endpoint

Common issues when running the read-only assessment, each as **symptom → cause → fix**. None of these fixes change tenant security configuration — they fix the *assessment run*.

## `SOAMDE-Validate.ps1` fails at "connect to Graph"
- **Symptom:** `Connect-MgGraph` errors, or a consent prompt cannot be completed.
- **Cause:** The Microsoft.Graph modules are missing/old, or admin consent for the read scopes has not been granted.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser` (R5), then reconnect with the read scopes in Implementation Stage 1. For unattended runs, ensure the `SOA-MDE-Reader – Tenant – Assess` app registration has admin-consented read-only permissions.

## Validate reports "no machines returned" but the portal shows devices
- **Symptom:** Advanced hunting / machine list is empty from the script, yet **Assets → Devices** is populated.
- **Cause:** The identity has Graph read but **not** the MDE (WindowsDefenderATP) read role, or unified Defender RBAC is on and the assessor is not in a read-only role group. *Verify current RBAC model.*
- **Fix:** Assign **Security Reader** in the Defender portal RBAC (or add the app's `Machine.Read.All` / `AdvancedHunting.Read.All` and admin-consent). Re-run Validate.

## Validate flags a write scope present
- **Symptom:** Validate fails specifically on the "no write scope" assertion.
- **Cause:** The assessor holds an admin/manage role (e.g. Security Administrator) — over-privileged for an assessment.
- **Fix:** Reduce the identity to **Security Reader** / **Global Reader** before running. An assessment must not hold write access; this is by design, not a bug.

## An entire area comes back empty in Discovery
- **Symptom:** One area file (e.g. ASR, tamper protection) is empty while others populate.
- **Cause:** Either the feature/plan is **not licensed/enabled** in the tenant, or a specific read permission for that surface is missing.
- **Fix:** Check licensing/plan (Global Requirement G4) — an unlicensed feature is a **finding** (score it N-A and list it), not a run error. If it is a permission gap, add the specific read scope and re-run. *Verify current plan/feature mapping.*

## Onboarding coverage looks impossibly high (e.g. 100%)
- **Symptom:** Coverage shows near-total onboarding that the owner disputes.
- **Cause:** The denominator is MDE's own inventory, not the **expected** device count (R4) — devices that never onboarded are invisible to MDE, so they cannot lower a self-referential percentage.
- **Fix:** Re-run `SOAMDE-Coverage.ps1 -ExpectedDeviceCount <n>` with the authoritative count from Intune/AD/CMDB. The gap will now include never-onboarded devices.

## Advanced-hunting query returns fewer results than expected / times out
- **Symptom:** KQL-based checks under-report or the query errors on volume.
- **Cause:** Data **retention** limits how far back hunting sees, or the query window/scope is too broad for the tenant size.
- **Fix:** Narrow the time window in the scope file, or accept the retention limit and note it in the report. *Verify current advanced-hunting retention for your licensing.*

## Scorecard marks a feature as Fail that the owner says is intentionally not used
- **Symptom:** A deliberately-unused control scores as a Fail finding.
- **Cause:** The assessment cannot know an organizational decision to not use a feature.
- **Fix:** Record it as an **accepted exception** in the review (Stage 7). Risk-acceptance is the customer's decision; annotate it so it is not re-flagged as new each run.

## Report findings don't match the portal on spot-check (Gate 5 fail)
- **Symptom:** A top finding reads differently in the portal than in the report.
- **Cause:** Stale discovery data (portal changed after the run) or a scope mismatch between the run and the portal filter.
- **Fix:** Re-run `SOAMDE-Discovery.ps1` immediately before reporting for a fresh snapshot, and confirm the portal view uses the same scope. Never deliver a report that fails the reconcile spot-check.

## Two runs aren't comparable (trend broken)
- **Symptom:** The posture score jumps in a way that doesn't reflect real change.
- **Cause:** The scope or baseline changed between runs.
- **Fix:** Pin scope and baseline in `SOAMDE-Scope – Fleet – Assess.json` and reuse it; only change them deliberately and note it in the report.
