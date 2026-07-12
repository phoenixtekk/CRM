# 5. Testing Guide — Microsoft Defender for Endpoint

Run the tests for each workstream you executed. Every test has a **pass/fail gate**; do not enforce ASR/block mode more widely, expand onboarding, promote a detection, or call a PoC conclusive until the relevant gates pass. Objects are referenced by the exact names from the Implementation Guide. Scripts are referenced by name.

---

## Part A — Deploy validation

### A-Test 1 — Pilot ring onboarded (all platforms)
**Procedure:** Run `MDEFULL-Validate.ps1 -Check Onboarding`. In **Assets → Devices**, confirm each pilot device from `MDE Device Group – Pilot Ring – Pilot` (Windows/macOS/Linux) is **Onboarded**.
**Pass:** Every pilot device is onboarded and reporting EDR signal.
**Fail:** A device stays "Can be onboarded" — see Troubleshooting *Device not onboarding*.

### A-Test 2 — Next-gen AV + EDR block mode
**Procedure:** Run `MDEFULL-Validate.ps1 -Check EDR`. Confirm `MDE Next-Gen AV – Pilot Ring – Prod` is applied and **EDR in block mode** is on.
**Pass:** AV policy applied to the ring and block mode enabled. **Fail:** either off — see Troubleshooting *EDR/AV not applied*.

### A-Test 3 — ASR in audit, then block
**Procedure:** Run `MDEFULL-Validate.ps1 -Check ASR` and `MDEFULL-Report.ps1 -Section ASR`. Confirm `MDE ASR Rules – Pilot Ring – Audit` produced audit events, exclusions were reviewed, and `MDE ASR Rules – Pilot Ring – Block` is blocking on the ring.
**Pass:** ASR ran in audit, exclusions tuned, block enforced with no legitimate-app breakage. **Fail:** blocking before audit review, or breaking apps — revert to audit per Implementation Step A4/B2.

### A-Test 4 — Tamper protection + web content filtering
**Procedure:** Run `MDEFULL-Validate.ps1 -Check Config`. Confirm **Tamper Protection** is enforced and `MDE Web Content Filtering – Tenant – Prod` is active.
**Pass:** Tamper protection on; web filtering enforced (P2). **Fail:** either off — re-apply per Step A5; *verify P2*.

### A-Test 5 — Device groups + RBAC
**Procedure:** Run `MDEFULL-Validate.ps1 -Check RBAC`. Confirm `MDE Device Group – Pilot Ring – Pilot` exists with automation **Semi — require approval**, and roles `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod` are assigned.
**Pass:** Device group and roles exist; reader cannot take response actions, operator can; automation approval-gated. **Fail:** flat permissions or wrong automation — re-apply per Step A6.

### A-Test 6 — Onboarding coverage + telemetry streaming
**Procedure:** Run `MDEFULL-Hunt.ps1 -Mode Coverage`. Confirm `DeviceInfo` shows pilot devices onboarded/healthy and `DeviceEvents` / `DeviceTvmSoftwareVulnerabilities` return rows.
**Pass:** Coverage and telemetry tables stream for the ring. **Fail:** a table empty — see Troubleshooting *No device telemetry*.

### A-Test 7 — A detection actually fires
**Procedure:** Run the Microsoft-provided safe **EDR detection test** on a pilot device; confirm the alert appears in **Incidents & alerts**. With block mode on, confirm an ASR-block event.
**Pass:** The controlled test produces a visible MDE alert; ASR blocks the tested behavior. **Fail:** no alert/block — see Troubleshooting *Detection does not fire*.

### A-Test 8 — TVM exposure baseline + AIR approval-gated
**Procedure:** Run `MDEFULL-Report.ps1 -SaveBaseline`. Confirm a TVM exposure baseline is recorded and the pilot group's AIR automation level is **Semi — require approval**.
**Pass:** Exposure baseline captured; AIR approval-gated. **Fail:** no exposure data (allow warm-up) or automation higher than agreed — reset per Step A7 and confirm with the SOC.

**Deploy exit gate:** all eight pass on the pilot ring before promoting ASR/block mode or expanding onboarding (Step A9). Re-run A-Tests 1, 3, 6, 7, 8 after each expansion wave against the saved baseline.

---

## Part B — Operate & Optimize validation

### B-Test 1 — Before-state baseline captured
**Procedure:** Confirm the baseline from `MDEFULL-Report.ps1 -SaveBaseline` (Step B1) exists with alert volume, false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage.
**Pass:** A baseline exists. **Fail:** none — re-run Step B1; without a "before" there is no measurable improvement.

### B-Test 2 — ASR rules blocking on the pilot ring; no legitimate app broke
**Procedure:** Run `MDEFULL-Validate.ps1 -Check ASR` / `-Check Tuning`. Confirm the vetted rules show **Block** on `MDE ASR Rules – Pilot Ring – Block`, assigned to `MDE Device Group – Pilot Ring – Pilot`; run `MDEFULL-Hunt.ps1 -Mode ASRAudit -BlockedOnly` and review block events for any business app.
**Pass:** Intended rules block; only malicious/unwanted behavior blocked; no business-critical app broken. **Fail:** rules still audit/unassigned, or a legitimate app blocked — add a scoped exclusion or revert that rule to audit (rollback).

### B-Test 3 — Alert noise / false positives reduced (measured)
**Procedure:** Run `MDEFULL-Report.ps1 -BaselinePath <baseline>`. Compare current alert volume and false-positive proportion to the B-Test 1 baseline.
**Pass:** Volume and/or FP proportion **measurably lower** than baseline, with no new blind spot from over-suppression. **Fail:** no reduction — confirm suppressions/indicators applied and scoped.

### B-Test 4 — Suppressions scoped and time-bound
**Procedure:** Run `MDEFULL-Validate.ps1 -Check Tuning`. In **Incidents & alerts → suppression rules** and **Settings → Endpoints → Indicators**, confirm each is named `MDE FP Suppression – <detection> – Prod` / `MDE Allow Indicator – <object> – Prod` with a justification and review date.
**Pass:** every suppression/indicator narrow, justified, with a review date. **Fail:** a broad/permanent one exists — tighten or add an expiry.

### B-Test 5 — Coverage expanded + tags/groups resolve
**Procedure:** Run `MDEFULL-Validate.ps1 -Check Tuning` and `MDEFULL-Hunt.ps1 -Mode Coverage`. Compare onboarded/active count to baseline; filter **Assets → Devices** by the applied tag.
**Pass:** onboarding/sensor-health coverage **higher** than baseline; tags/groups target the right devices. **Fail:** coverage unchanged, devices Inactive, or tags missing — see Troubleshooting.

### B-Test 6 — Hardening on (tamper / EDR block mode / web filtering)
**Procedure:** Run `MDEFULL-Validate.ps1 -Check Config`. Confirm **Tamper Protection = On**, **EDR in block mode = On**, and `MDE Web Content Filtering – Tenant – Prod` active for the ring.
**Pass:** all three enabled and applied. **Fail:** one off — re-run Step B5.

**Optimize exit gate:** all pass on the pilot ring — with a **measurable before/after improvement** in B-Test 3 and B-Test 5 — before estate-wide expansion (Step B6). Re-run after each wave against the re-saved baseline.

---

## Part C — Enable validation (lab gates)

### C-Test 1 — Environment supports the labs
**Procedure:** Run `MDEFULL-Discovery.ps1`; confirm active devices and that `DeviceProcessEvents`/`DeviceNetworkEvents`/`DeviceEvents` return recent rows, and that Advanced hunting / Live Response / Custom detection rules are present (P2).
**Pass:** data present and P2 surfaces load. **Fail:** onboard devices / assign P2, or run only the prevention/ASR labs on P1.

### C-Test 2 — Hunting labs resolve
**Procedure:** `MDEFULL-RunLab.ps1 -Lab 4` returns rows; repeat for Lab 5.
**Pass:** Labs 4–5 run without schema errors and return explainable results. **Fail:** correct any table/column/ASR-ActionType name to your tenant's schema and re-run.

### C-Test 3 — Learners can investigate; lab ASR is audit-only; live response read-only
**Procedure:** Observe the capstone (root cause + scope from graph + timeline); confirm `MDE ASR Lab – Lab Devices – Audit` is **audit** (never block) with events in `DeviceEvents`; review the live-response transcript for `MDE Lab Devices – Pilot Ring – Pilot` — only `processes`/`dir`/`fileinfo`/`getfile`. `MDEFULL-Validate.ps1 -Check Enablement` flags any block-mode lab rule or change command.
**Pass:** capstone identifies root cause + scope; lab ASR audit-only; only read-only live-response commands. **Fail:** reinforce the mapped lab; reaffirm the read-only posture (**R2.13**).

### C-Test 4 — Lab detection is alert-only; knowledge-check passes
**Procedure:** **Advanced hunting → Custom detection rules** lists `MDE Lab Detection – Team – Pilot` with response = alert-only; run `MDEFULL-Validate.ps1 -Check Enablement` for the `MDE Knowledge Check – Team – Pilot` score.
**Pass:** detection exists and is alert-only; each learner passes the knowledge-check. **Fail:** recreate the detection as alert-only (Lab 8); revisit the mapped lab for any missed question.

**Enable exit gate:** all lab gates pass and no production response action was taken; then operationalize (Step C3).

---

## Part D — Prove validation (PoC gates)

### D-Test 1 — Pilot onboarding
**Procedure:** Run `MDEFULL-PoC.ps1 -Action Enable -WhatIf`, then after enabling confirm each device in `MDE PoC – Pilot Ring – Pilot` shows **Onboarded** in **Assets → Devices**.
**Pass:** every pilot device onboarded. **Fail:** a device stays "Can be onboarded" — see Troubleshooting *Pilot device not onboarding*.

### D-Test 2 — Benign signal generated
**Procedure:** Run `MDEFULL-PoC.ps1 -Action TestSignal` on a pilot device; confirm the EICAR file was written/quarantined and a built-in simulation ran.
**Pass:** Microsoft Defender Antivirus detects/quarantines EICAR; the simulation runs; only benign signal used. **Fail:** no AV reaction — see Troubleshooting *EICAR not detected*.

### D-Test 3 — Detection reached the portal, timeline, and hunting
**Procedure:** Run `MDEFULL-Validate.ps1 -Check PoC`. Confirm an alert from the pilot device in **Incidents & alerts**, the EICAR/simulation activity on the **device timeline** with process/file detail, and recent rows in `DeviceEvents`/`AlertInfo`/`AlertEvidence`.
**Pass:** alert within your agreed latency window; timeline rich; hunting rows return. **Fail:** empty — allow warm-up; see Troubleshooting *No alert from test signal* / *Timeline empty* / *Hunting tables empty*.

### D-Test 4 — Automated investigation started (approval-gated)
**Procedure:** Open **Incidents → the test incident → Automated investigations**; `MDEFULL-Validate.ps1 -Check PoC` reports AIR status and automation level.
**Pass:** an automated investigation started and the pilot group's level is **Semi — require approval** (no unattended action). **Fail:** no AIR, or automation acted unattended — see Troubleshooting *AIR did not start* / reset per Step D2.

### D-Test 5 — Scorecard produced
**Procedure:** Run `MDEFULL-PoC.ps1 -Action Score` and confirm `MDE PoC Scorecard – Pilot Ring – Validate` is written with a pass/fail per criterion.
**Pass:** a complete scorecard maps every observation to your criteria. **Fail:** missing observations — re-run the relevant validate step first.

### D-Test 6 — Clean teardown
**Procedure:** Run `MDEFULL-PoC.ps1 -Action Teardown -WhatIf`, then for real; re-run `MDEFULL-Validate.ps1 -Check PoC`.
**Pass:** pilot devices offboarded, the Intune policy removed, EICAR deleted, test alerts resolved — nothing left onboarded. **Fail:** residue remains — see Troubleshooting *Teardown left residue*.

**Prove exit gate:** D-Tests 1–5 pass to call the PoC conclusive; D-Test 6 passes to close it out. Keep the scorecard as the decision record.
