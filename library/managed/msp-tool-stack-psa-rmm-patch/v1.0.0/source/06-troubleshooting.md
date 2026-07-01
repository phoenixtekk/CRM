# 6. Troubleshooting — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

Common failures encountered while standing up and operating the stack, with causes and fixes. Many fixes are automated in `MSPSTACK-Remediation.ps1` (run `-WhatIf` first, then `-Apply`). Re-run the relevant check in `05-testing.md` after any fix.

---

## PSA issues

### Boards/queues missing or misnamed

- **Symptom:** Validation V1 fails — a board/queue is absent or named inconsistently.
- **Cause:** Created out of convention, or not created at all.
- **Fix:** Recreate using the exact `<Purpose> – <Scope> – <Stage>` names (e.g. `Service Desk – Reactive – Triage`). In the PSA console's service board/queue section, rename or create as needed.

### Time not flowing to billing

- **Symptom:** Logged technician time does not appear on a draft invoice.
- **Cause:** Time entry against tickets is disabled, or the ticket is not tied to a billable agreement.
- **Fix:** Enable time entry on tickets; attach the ticket's company to a billable agreement type; confirm the time entry is marked billable.

## RMM issues

### Agent not reporting / endpoint offline

- **Symptom:** A device shows offline or never checks in after deployment.
- **Cause:** Agent not installed, blocked outbound connectivity, or wrong site assignment.
- **Fix:** Confirm the agent is installed; verify the endpoint can reach the RMM's documented hostnames/ports (R10); confirm the device is in `Client Site – {ClientName} – Production`. Use `MSPSTACK-Discovery.ps1` to flag connectivity gaps.

### Monitors not firing / alert noise

- **Symptom:** No alert on a real condition, or too many low-value alerts.
- **Cause:** Policy not bound to the device group, or thresholds mis-tuned.
- **Fix:** Confirm `Monitoring Policy – Workstation – Standard` / `…– Server – Standard` are bound to the right groups; tune thresholds. Re-test by triggering a known condition.

### Nightly automation failing

- **Symptom:** `Automation Policy – Maintenance – Nightly` reports failures.
- **Cause:** Insufficient permissions, locked files, or reboots blocked by policy.
- **Fix:** Review the automation log on a failing endpoint; adjust the automation's run context/permissions; honor reboot-suppression where required.

## Patch issues

### Devices not receiving updates

- **Symptom:** Patch ring shows devices stuck or non-compliant.
- **Cause:** Device not in the ring's assigned group, blocked update source, or deferral not yet elapsed.
- **Fix:** Confirm the device is in the ring's assignment group; verify reachability of Windows Update / WSUS / Delivery Optimization (R10); confirm the deferral window. For Intune: *Devices → Manage updates → Windows updates → Update rings → (open ring) → Assignments* and *Devices → Monitor → Windows Update reports*.

### Wrong deferral on a ring

- **Symptom:** Validation V3 fails — a ring's deferral does not match the design (0/3/7/7).
- **Cause:** Misconfiguration at ring creation.
- **Fix:** Open the ring and correct the **Quality update deferral period (days)**. In Intune: *Devices → Manage updates → Windows updates → Update rings → (open ring) → Properties → Settings*.

## Integration issues

### Integration shows disconnected

- **Symptom:** `Integration – PSA-RMM – Bi-Directional` is not connected.
- **Cause:** Expired/rotated API credential, or insufficient credential scope.
- **Fix:** Retrieve the current credential from the secrets store (R12); re-authenticate the integration; confirm the credential's scope covers tickets, assets, and alerts. Rotate if compromised.

### Alerts not creating tickets

- **Symptom:** RMM alerts fire but no ticket appears on `NOC – Alerts – Automated`.
- **Cause:** Alert→ticket mapping not configured, or site↔company mapping missing.
- **Fix:** In the integration's mapping screen, confirm alerts map to `NOC – Alerts – Automated` and that `Client Site – {ClientName} – Production` maps to the matching PSA company. Trigger a test alert to confirm.

### Tickets not auto-closing

- **Symptom:** Alert clears but the ticket stays open.
- **Cause:** Auto-close on alert-clear not enabled.
- **Fix:** Enable auto-close in the alert→ticket mapping so a resolved alert closes its ticket.

### Assets not appearing in the CMDB

- **Symptom:** RMM-discovered devices are not configuration items in the PSA.
- **Cause:** Asset/CMDB feed not enabled or device-to-CI mapping missing.
- **Fix:** Enable the asset feed in the integration; confirm device-to-configuration-item mapping; let the next sync run, then re-check the PSA company's configurations.

## Onboarding issues

### Onboarding script dry-run shows unexpected objects

- **Symptom:** `MSPSTACK-Set-ClientOnboarding.ps1 -WhatIf` would create duplicates or wrong names.
- **Cause:** Legacy objects exist, or the client name input is inconsistent.
- **Fix:** Reconcile against the naming standard; correct the client-name parameter; only run `-Apply` once the dry-run output is correct.

---

## Escalation

If a fix is not covered here: re-run `MSPSTACK-Discovery.ps1` and `MSPSTACK-Validation.ps1` to localize the failing plane, consult the chosen vendor's admin console and documentation for product-specific behavior, and route any fleet-wide change through change control (GM4) before applying.
