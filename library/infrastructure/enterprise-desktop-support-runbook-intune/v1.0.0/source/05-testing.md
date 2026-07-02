# Testing

Testing here means proving that each runbook actually leads a technician from symptom to a correct
outcome, and that the bundled scripts read what they claim to read. Each runbook has an explicit
**pass/fail gate**: the runbook "passes" when a technician following it reaches the right resolution
(or the right escalation) using only the runbook's checks and evidence.

Run these on a **pilot device** (from the pilot Entra security group, G5) before relying on the
library across the fleet.

## How to test a runbook
1. Reproduce or select a real ticket that matches the runbook's **Scope / symptoms**.
2. Follow the **triage tree** — confirm it lands you on the correct branch.
3. Run the **checks** in order — confirm each one is observable exactly where the runbook says.
4. Apply the **resolution** (or reach the **escalation gate**) — confirm the outcome is correct.
5. Confirm every item in **evidence to collect** was actually capturable.

A runbook **fails** the gate if any check can't be observed as written, the triage tree misroutes,
the resolution doesn't resolve (or escalates when it shouldn't), or required evidence can't be
captured. Fix the runbook, then re-test.

---

## Pass/fail gates per runbook

### Runbook 1 — Sign-in / profile
- **PASS:** Triage correctly separates an identity-side failure (reproducible on a second device)
  from a device/profile failure; `dsregcmd /status` PRT state is readable; the sign-in log failure
  reason is found; resolution restores sign-in **or** a clean identity/profile escalation is raised
  with evidence.
- **FAIL:** Technician can't tell identity from profile; no PRT/sign-in-log evidence captured;
  MFA/CA change attempted on the endpoint instead of escalated.

### Runbook 2 — OS / Windows Update
- **PASS:** Update error code and update ring are identified; disk/retry path is exercised;
  boot/bugcheck cases route to escalation; a stuck update is cleared **or** escalated with the error
  code and ring name recorded.
- **FAIL:** No error code captured; a non-booting device is treated as a local retry; a re-image is
  attempted without approval/backup.

### Runbook 3 — Hardware / peripheral
- **PASS:** Model/serial captured; Device Manager error code found; the peripheral is isolated
  (other port/cable/second machine); resolution fixes the driver/peripheral **or** a confirmed
  physical fault escalates to warranty with evidence.
- **FAIL:** No isolation performed; internal fault treated as a driver reinstall loop; no
  model/serial recorded for warranty.

### Runbook 4 — Application
- **PASS:** Install status and targeting are checked; deploy-vs-runtime is correctly distinguished;
  a targeting miss is fixed via group membership (not sideloading); a crash is resolved by
  repair/reinstall/dependency **or** escalated to the app owner/vendor with the faulting module
  recorded.
- **FAIL:** App sideloaded to bypass a broken deployment; no install error code or faulting module
  captured.

### Runbook 5 — Network reachability
- **PASS:** "Everything vs. one target" is correctly triaged; `ipconfig /all`, ping-by-IP, and
  `nslookup`/`Test-NetConnection` evidence captured; local fixes (renew/flushdns/rejoin) applied;
  upstream faults escalated to the network team.
- **FAIL:** DNS vs. routing not distinguished; endpoint attempts to change firewall/DNS
  infrastructure; a service outage treated as a device fault.

### Runbook 6 — Enrollment / compliance
- **PASS:** Presence and join state (`dsregcmd`) confirmed; the exact non-compliant setting is
  identified by name; targeting/group membership verified; setting remediated and re-evaluated
  **or** escalated; no wipe/re-enroll without approval + backup.
- **FAIL:** "Non-compliant" reported without naming the failing setting; device wiped/re-enrolled
  without approval; targeting not checked when a policy is missing.

---

## Script tests (read-only, run first)
- **DESKSUP-Discovery.ps1** — PASS when it connects to Graph with read scopes and returns endpoint
  health/context for the target device(s) without writing anything. FAIL if it errors on scopes or
  attempts a write.
- **DESKSUP-Validation.ps1** — PASS when the per-device state it reports (enrollment, compliance,
  key policies) matches what the Intune portal shows for a pilot device.
- **DESKSUP-Report.ps1** — PASS when the support-metrics/health summary runs read-only and its
  figures reconcile with the portal for the pilot scope.
- **DESKSUP-Remediation.ps1** — PASS when run with the default `-WhatIf`: it prints the intended
  safe fix and makes **no** change. Only after WhatIf review should it be run for real on a pilot
  device.
- **DESKSUP-Set-ScopeTargeting.ps1** — PASS when run with the default `-WhatIf`: it prints the
  intended group membership change and makes **no** change until explicitly confirmed on the pilot
  group.

**Overall gate to leave pilot:** every runbook passes on the pilot device, all five scripts pass
their read-only/`-WhatIf` tests, and the evidence lists are all capturable in your ticketing tool.
