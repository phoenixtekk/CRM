# Testing

Testing here means proving that each runbook actually leads a technician from symptom (or setup
task) to a correct outcome, and that the bundled scripts read what they claim to read. Each runbook
has an explicit **pass/fail gate**: the runbook "passes" when a technician following it reaches the
right resolution (or the right escalation) using only the runbook's checks and evidence.

Run these on a **pilot Mac** (from the pilot Entra security group) before relying on the library
across the fleet, and **re-run the enrollment, FileVault, SSO, and compliance gates on each major
macOS release** (see Solution Overview — keeping current).

## How to test a runbook
1. Reproduce or select a real ticket/task that matches the runbook's **Scope / symptoms**.
2. Follow the **triage tree** — confirm it lands you on the correct branch.
3. Run the **checks** in order — confirm each one is observable exactly where the runbook says.
4. Apply the **resolution / setup steps** (or reach the **escalation gate**) — confirm the outcome
   is correct.
5. Confirm every item in **evidence to collect** was actually capturable.

A runbook **fails** the gate if any check can't be observed as written, the triage tree misroutes,
the resolution doesn't resolve/complete (or escalates when it shouldn't), or required evidence
can't be captured. Fix the runbook, then re-test.

> **FileVault safety in testing:** for any test that touches FileVault (Runbooks 4 and 7), confirm
> the pilot Mac's recovery key is escrowed **before** the test, and never use a production user's
> Mac for a destructive-path test.

---

## Pass/fail gates per runbook

### Runbook 1 — ADE / enrollment
- **PASS:** A pilot serial assigned to the Intune MDM server in ABM receives its enrollment profile
  and enrolls through Setup Assistant; token validity and profile assignment are readable; a Mac
  missing its management profile is correctly routed (re-sync or re-enroll) **or** escalated with
  the serial, ABM assignment, and error captured.
- **FAIL:** Enrollment failure treated without checking ABM assignment/token; a Mac is erased to
  "fix" enrollment without approval and a confirmed recovery key.

### Runbook 2 — SSO setup
- **PASS:** The Enterprise SSO plug-in (or Platform SSO) profile is confirmed assigned and installed;
  Company Portal presence verified; a registration/token failure is distinguished from a CA block via
  the sign-in log; SSO works after setup **or** a CA/Platform-SSO-design issue is escalated.
- **FAIL:** No check of profile assignment or Company Portal; MFA/CA change attempted on the endpoint;
  Platform SSO rolled out fleet-wide without a pilot.

### Runbook 3 — App deployment (VPP / LOB)
- **PASS:** VPP token validity and license count checked (for VPP); assignment/targeting and install
  status read; deploy-vs-runtime correctly distinguished; a targeting miss fixed via group membership
  (not sideloading); a failed install resolved by re-sync/detection fix **or** escalated with the
  error captured.
- **FAIL:** App sideloaded to bypass a broken deployment; no install error or token/license state
  captured.

### Runbook 4 — Passwordless / FileVault
- **PASS:** FileVault policy assignment and `fdesetup status` confirmed; **recovery key escrow
  verified before any change**; a missing key is escrowed via rotate; SecureToken/bootstrap-token
  state read and reconciled; passwordless/Platform SSO stood up on the pilot.
- **FAIL:** Any FileVault change attempted without a confirmed escrowed key; recovery key value
  written into a ticket; SecureToken granted in production without pilot verification.

### Runbook 5 — BYOD
- **PASS:** Enrollment restriction (personal macOS allow) and Company Portal presence checked; the
  Mac enrolls user-driven and shows **Ownership = Personal**; BYOD group targeting verified; a
  non-compliant BYOD Mac is handed to Runbook 6.
- **FAIL:** A corporate/full-wipe control applied to a personal Mac; enrollment attempted without
  confirming BYOD is allowed and the user is licensed.

### Runbook 6 — Compliance & Conditional Access
- **PASS:** Presence/check-in confirmed; the exact non-compliant setting is identified by name
  (e.g. FileVault, minimum macOS); CA block distinguished from plain non-compliance via the sign-in
  log; setting remediated and re-evaluated **or** escalated; targeting verified when a policy is
  missing.
- **FAIL:** "Non-compliant" reported without naming the failing setting; a CA bypass attempted on
  the endpoint; targeting not checked when a policy is missing.

### Runbook 7 — Incident response
- **PASS:** Recovery-key escrow is the first check; a locked Mac is recovered with the escrowed key
  and the key is **rotated afterward**; SecureToken/bootstrap-token state is read and either fixed on
  a pilot or escalated; **no erase/reset without approval + confirmed key**.
- **FAIL:** A locked Mac with no escrowed key is worked toward an erase without escalation; the
  recovery key is captured into a ticket; a destructive step is taken as a technician decision.

---

## Script tests (read-only, run first)
- **MACRUN-Discovery.ps1** — PASS when it connects to Graph with read scopes and returns Mac
  health/context (enrollment, compliance, FileVault-escrow indicator, OS, primary user) for the
  target device(s) without writing anything. FAIL if it errors on scopes or attempts a write.
- **MACRUN-Validation.ps1** — PASS when the per-device state it reports (enrollment, compliance with
  named non-compliant policies, assigned config profiles, recovery-key escrow) matches what the
  Intune portal shows for a pilot Mac.
- **MACRUN-Report.ps1** — PASS when the support-metrics / fleet-health summary runs read-only and its
  figures reconcile with the portal for the pilot scope.
- **MACRUN-Remediation.ps1** — PASS when run with the default `-WhatIf`: it prints the intended safe
  action (Sync / Rotate FileVault key) and makes **no** change. Only after WhatIf review should it be
  run for real on a pilot Mac.
- **MACRUN-Set-ScopeTargeting.ps1** — PASS when run with the default `-WhatIf`: it prints the intended
  group membership change and makes **no** change until explicitly confirmed on the pilot group.

**Overall gate to leave pilot:** every runbook passes on the pilot Mac, all five scripts pass their
read-only/`-WhatIf` tests, the FileVault recovery key is confirmed escrowed for the pilot Mac, and
the evidence lists are all capturable in your ticketing tool.
