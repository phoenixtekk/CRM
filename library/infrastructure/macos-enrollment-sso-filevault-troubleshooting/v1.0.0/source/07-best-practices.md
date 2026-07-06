# 7. Best Practices — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

Evidence-based escalation: every recommendation below shortens the path from symptom to the failing
layer, and keeps you from acting on a guess.

- **Diagnose top-down, always.** A lower-layer symptom (SSO, FileVault, CA) is usually caused by a
  missing or errored artifact **above** it (an unassigned serial, an undelivered profile). Confirm the
  higher layer is healthy before you blame the lower one — it is the single biggest time-saver.
- **Classify the symptom first.** The one question "**where does it stop?**" picks the branch. Naming
  the class (ADE / SSO / FileVault / compliant-but-denied / locked-out) before touching anything keeps
  the investigation on rails.
- **Read the signal; don't infer it.** Each layer has an authoritative signal — the enrollment token,
  the per-device profile state, `sysadminctl`/`fdesetup` on the Mac, the Entra sign-in log's CA tab.
  Read the actual signal rather than assuming from the symptom.
- **Trust the Mac for token state.** SecureToken and Bootstrap-Token status are authoritative **on the
  device** (`sysadminctl`, `profiles status -type bootstraptoken`). Graph confirms escrow and profile
  delivery; the local commands confirm the token itself.
- **Escrow the recovery key before you need it.** Verify FileVault **personal recovery key** escrow in
  Intune (and `MACDX-Report.ps1` coverage) proactively — the key is what unlocks a locked-out Mac in
  Branch E. Missing escrow turns a five-minute fix into a wipe.
- **Keep the enrollment token current.** An expired Apple enrollment program token stops **all** new
  ADE enrollments tenant-wide. Track the expiry and renew ahead of time; set and verify a default
  enrollment profile.
- **Preview before you change.** Run `MACDX-Remediation.ps1` and `MACDX-Set-ScopeTargeting.ps1` in
  their default `-WhatIf` mode, read the intended action, then re-run with `-WhatIf:$false`. The safe
  actions here (Sync, add-to-group) are deliberately the least-disruptive; never reach for a wipe as a
  first move.
- **Separate "compliant" from "allowed".** Intune decides compliance; **Conditional Access** decides
  access. When a compliant Mac is denied, read the CA tab of the Entra sign-in log — that names the
  policy and grant control actually blocking, so you fix the right thing.
- **Confirm the SSO method matches the device.** Platform SSO password vs. Secure-Enclave-key vs.
  smart-card each has different device prerequisites; a mismatch loops sign-in. Verify macOS supports
  the method you configured before deploying it fleet-wide.
- **Record every resolution.** A short log of symptom → failing layer → signal → cause → fix compounds:
  the second occurrence should be minutes, not hours, and it is what lets you hand the runbook to the
  rest of the team.
- **Pilot on real failures.** Validate the playbook on at least two distinct failures — ideally
  different branches — before making it the team standard. Assign once, repeat everywhere.
- **Escalate with evidence, not a story.** When a fix doesn't hold, escalate with the captured
  signal — Company Portal diagnostics, the MDM log, the Intune device page, the Entra CA sign-in — and
  the exact layer/class. Evidence-based tickets get resolved; "it won't enroll" tickets bounce.
