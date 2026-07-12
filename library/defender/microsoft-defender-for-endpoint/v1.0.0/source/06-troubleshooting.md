# 6. Troubleshooting Guide — Microsoft Defender for Endpoint

Common field issues, in **symptom → cause → fix** form, grouped by workstream. Run `MDEFULL-Discovery.ps1` and the relevant `MDEFULL-Validate.ps1 -Check <area>` first — most causes surface there.

---

## Deploy & coverage

### Device not onboarding
**Symptom:** A pilot device stays "Can be onboarded" in **Assets → Devices** and reports no EDR signal (A-Test 1 / B-Test 5).
**Cause:** The onboarding profile is not assigned, the Intune MDE connector is off, the device cannot reach the Defender service endpoints, or the platform channel (macOS profile / Linux package) did not complete.
**Fix:** Confirm the device is in `MDE Device Group – Pilot Ring – Pilot` and `MDE Onboarding – Pilot Ring – Pilot` is assigned; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**; verify outbound HTTPS to the Defender endpoints (per `global-requirements-defender.md` G5); for macOS/Linux confirm the MDM profile/package installed. Force a sync and re-run `MDEFULL-Validate.ps1 -Check Onboarding`.

### EDR/AV not applied
**Symptom:** A-Test 2 fails — **EDR in block mode** is off or `MDE Next-Gen AV – Pilot Ring – Prod` is not applied.
**Cause:** Block mode not enabled in Advanced features, the AV policy not assigned to the ring, or a third-party AV conflicting.
**Fix:** Enable **Settings → Endpoints → Advanced features → EDR in block mode**; confirm the AV policy is assigned to the ring; confirm the AV posture (Defender primary or passive behind third-party). Re-run `MDEFULL-Validate.ps1 -Check EDR`.

### No device telemetry
**Symptom:** A-Test 6 fails — `DeviceInfo`, `DeviceEvents`, or `DeviceTvmSoftwareVulnerabilities` return no rows.
**Cause:** Devices newly onboarded and still warming up, or a device unhealthy/not reporting.
**Fix:** Confirm devices are onboarded and healthy (A-Test 1); allow warm-up (tables populate over hours); check device health in **Assets → Devices**. Re-run `MDEFULL-Hunt.ps1 -Mode Coverage`.

### Detection does not fire
**Symptom:** A-Test 7 fails — the safe EDR detection test produces no alert.
**Cause:** The device is not fully onboarded, block mode/AV is off, or not enough time has passed.
**Fix:** Confirm onboarding (A-Test 1) and AV/block mode (A-Test 2); run the Microsoft-documented EDR test exactly; allow the alert to surface in **Incidents & alerts**. Re-check with `MDEFULL-Hunt.ps1 -Mode Coverage`.

### Web content filtering not enforcing
**Symptom:** A-Test 4 / B-Test 6 fails — categories in `MDE Web Content Filtering – Tenant – Prod` are not blocked.
**Cause:** Web content filtering requires **P2** and network protection in block mode; the plan or dependency is missing.
**Fix:** *Verify P2 availability in your tenant*; confirm network protection is enabled (web filtering depends on it); allow policy propagation. Re-run `MDEFULL-Validate.ps1 -Check Config`.

### RBAC / device group not effective
**Symptom:** A-Test 5 fails — analysts have inconsistent access or the automation level is wrong.
**Cause:** Roles not assigned, device group scope wrong, or RBAC not yet propagated.
**Fix:** Confirm `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod` assignments and the `MDE Device Group – Pilot Ring – Pilot` scope/automation level under **Settings → Endpoints → Permissions**; allow propagation and re-test. Re-run `MDEFULL-Validate.ps1 -Check RBAC`.

---

## Optimize & tuning

### ASR rule not blocking / breaking a business app
**Symptom:** B-Test 2 fails — a vetted rule still shows Audit/Not configured, or a line-of-business app fails after moving to block.
**Cause:** The rule was not applied to `MDE ASR Rules – Pilot Ring – Block` / not assigned, or a rule blocks a legitimate behavior with no exclusion.
**Fix:** Confirm the rule state and assignment (re-run `MDEFULL-PromoteASR.ps1` in `-WhatIf`, then `-Apply`); for a broken app, identify the rule from the block event (`MDEFULL-Hunt.ps1 -Mode ASRAudit -BlockedOnly`), revert that rule to **audit**, add a scoped exclusion, validate in audit, then re-promote. This is exactly why ASR goes **audit → block** first.

### No baseline / report empty
**Symptom:** B-Test 1/3 fails — no before-state metrics to compare against.
**Cause:** `MDEFULL-Report.ps1 -SaveBaseline` was never run, or the deployment had no telemetry when it ran.
**Fix:** Run `MDEFULL-Report.ps1 -SaveBaseline` on a reporting deployment before any change; without a "before" there is no measurable improvement.

### Noise not dropping / over-broad suppression
**Symptom:** B-Test 3/4 fails — alert volume unchanged, or a suppression is too broad/permanent.
**Cause:** Suppressions/indicators not applied, scoped too widely, or missing a review date.
**Fix:** Confirm each `MDE FP Suppression – <detection> – Prod` / `MDE Allow Indicator – <object> – Prod` is applied, tightly scoped, justified, and time-bound; tighten or add an expiry. Re-run `MDEFULL-Hunt.ps1 -Mode Noise` and `MDEFULL-Validate.ps1 -Check Tuning`.

### Tags/groups not resolving / split-brain policy
**Symptom:** B-Test 5 fails — tags missing, a group is empty, or a setting you changed did not take effect.
**Cause:** The tag scheme/dynamic rule is wrong, or the same setting is authored in two surfaces (Intune and GPO/CM) and the non-authoritative one is silently losing.
**Fix:** Confirm the tag scheme (Step B4) and that policy is authored only in the authoritative surface (Requirement 2.9); migrate stray GPO/CM settings into Intune. Allow propagation and re-run `MDEFULL-Validate.ps1 -Check Tuning`.

---

## Enable (labs)

### Hunting lab query errors
**Symptom:** C-Test 2 fails — a lab query from `MDEFULL-Labs.kql` throws a schema error or returns nothing.
**Cause:** Table/column/ASR-ActionType names differ in your tenant/cloud, or the lookback window is too narrow.
**Fix:** Correct the flagged `// VERIFY` names against **Advanced hunting → schema**; widen `-LookbackDays`; confirm table freshness with `MDEFULL-Discovery.ps1`. Re-run `MDEFULL-RunLab.ps1 -Lab <n>`.

### Lab ASR rule blocked, or a change command was run
**Symptom:** C-Test 3 fails — `MDE ASR Lab – Lab Devices – Audit` shows a rule in block, or the live-response transcript shows `run`/`remediate`/`putfile`.
**Cause:** The read-only / no-production-response posture (Requirement 2.13) was not held.
**Fix:** Set the lab rules back to **audit** (they never blocked anything if audit-only); reaffirm that change commands are out of scope for the labs — reserve them for real incidents under the SOC's approvals.

### Lab detection isn't alert-only
**Symptom:** C-Test 4 fails — `MDE Lab Detection – Team – Pilot` has a response action beyond alerting.
**Cause:** The detection was created (Lab 8) with an automatic isolation/remediation response.
**Fix:** Edit the custom detection so the response is **generate an alert only**; disable or delete it if it is no longer needed. `MDEFULL-Validate.ps1 -Check Enablement` confirms it is alert-only.

---

## Prove (PoC)

### Pilot device not onboarding
**Symptom:** D-Test 1 fails — a device in `MDE PoC – Pilot Ring – Pilot` stays "Can be onboarded."
**Cause:** `MDE PoC EDR Onboarding – Pilot Ring – Pilot` is not assigned, the MDE-Intune connector is off, or the device cannot reach the Defender service endpoints.
**Fix:** Confirm the device is in the pilot group; confirm **Connection status: Enabled**; verify outbound HTTPS to the Defender endpoints (G5). Force an Intune sync and re-run `MDEFULL-PoC.ps1 -Action Enable -WhatIf`.

### EICAR not detected
**Symptom:** D-Test 2 fails — the EICAR test file is written but Microsoft Defender Antivirus does not detect/quarantine it.
**Cause:** Real-time protection is off, third-party AV is primary, tamper/exclusions suppress it, or the file was altered.
**Fix:** Confirm real-time and cloud-delivered protection are on for the pilot device; remove any test-path exclusion; ensure the EICAR string is exact and unmodified. Re-run `MDEFULL-PoC.ps1 -Action TestSignal`.

### No alert from test signal / timeline empty / hunting tables empty
**Symptom:** D-Test 3 fails — no alert, an empty **Timeline**, or no rows from `DeviceEvents`/`AlertInfo`/`AlertEvidence`.
**Cause:** The device is not fully onboarded, signal has not propagated, onboarding is too recent, or the account lacks hunting read scope.
**Fix:** Confirm D-Test 1 passed; allow warm-up (minutes to hours); confirm the simulation/EICAR ran on an onboarded pilot device; confirm `ThreatHunting.Read.All` consent and **Security Reader**. Re-run `MDEFULL-Validate.ps1 -Check PoC`.

### AIR did not start
**Symptom:** D-Test 4 fails — no automated investigation for the test incident.
**Cause:** Automated Investigation is off, the device is not in an automation-enabled group, or the alert type did not trigger AIR.
**Fix:** Confirm **Settings → Endpoints → Advanced features → Automated Investigation** is on and the pilot group's level is **Semi — require approval**; some benign simulations trigger AIR, some do not — use a built-in EDR simulation known to raise an EDR alert. Re-run `MDEFULL-Validate.ps1 -Check PoC`.

### Teardown left residue
**Symptom:** D-Test 6 fails — after `MDEFULL-PoC.ps1 -Action Teardown`, a device still shows onboarded or the Intune policy remains.
**Cause:** Offboarding is asynchronous, or teardown ran in `-WhatIf` only.
**Fix:** Run teardown **without** `-WhatIf` to apply; offboarding can take time to reflect in **Assets → Devices** — allow it, then confirm with `MDEFULL-Validate.ps1 -Check PoC`. Remove the Intune policy and pilot group manually if any remain.

---

## Cross-cutting

### Automated response acted without approval
**Symptom:** A pilot/test device was isolated or a file remediated automatically (any workstream).
**Cause:** The device group's AIR **automation level** is higher than **Semi — require approval**.
**Fix:** Reset the automation level to **Semi — require approval**, confirm with the SOC, and record it with `MDEFULL-Report.ps1`. *The automation-guardrail decision is the security team's.*

### Script cannot authenticate
**Symptom:** An `MDEFULL-*.ps1` script fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, the account lacks the role, or (Government cloud) the wrong environment/endpoints were used.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes (or the write scope for the gated apply paths); confirm **Security Reader** (or Security Administrator / Endpoint Security Manager for change paths); for Government cloud pass the matching `-Environment`. Re-run the script.
