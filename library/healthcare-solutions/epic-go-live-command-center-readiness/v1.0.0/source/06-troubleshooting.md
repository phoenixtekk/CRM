# 6. Troubleshooting — Epic Go-Live & Command Center Endpoint Readiness Playbook

This section is the deep-diagnostic companion to the rapid-fix triage runbook in `03-implementation.md` (Step 4.3). The runbook gets the clinician working *now*; this section is how Tier-2/Tier-3 root-cause and permanently resolve the failure. Each entry follows **Symptom → Likely causes → Diagnose → Resolve → Prevent**. Deep configuration for the Epic client, Imprivata, and the workstation image lives in the referenced solutions; this focuses on endpoint-side diagnosis during an activation.

> **Pattern first.** Before deep-diving a single device, check whether many devices on one unit are failing the same way at the same time. A cluster is almost always a back-end event (Imprivata appliance, network/VLAN, print server, Conditional Access change) — fix the cause once instead of N devices. The dispatcher's live counts are the fastest way to see a pattern.

---

## A. Login / SSO — badge tap doesn't log in

**Symptom.** Clinician taps badge, nothing happens, wrong/delayed prompt, or session won't open.

**Likely causes.** Badge reader disconnected/failed; Imprivata agent stopped or unhealthy; agent can't reach the Imprivata appliance (network); badge not enrolled/mapped; Conditional Access or compliance blocking the sign-in; time skew on the device.

**Diagnose.**
1. Confirm the badge reader is connected and recognized by the OS; test with a known-good badge.
2. Check the Imprivata agent health/tray; confirm the service is running.
3. Test reachability from the device to the Imprivata appliance and to the Microsoft sign-in endpoints (GR5 dependency map).
4. In **Microsoft Entra admin center > Monitoring > Sign-in logs**, find the user/device sign-in and read the failure reason (e.g., Conditional Access, compliance).
5. Check device time sync (Kerberos/auth fails on skew).

**Resolve.**
- Reader fault → reseat/replace reader; confirm driver.
- Agent hung → restart the Imprivata agent/service; if persistent, repair the agent (referenced Imprivata solution).
- Reachability → fix the network path to the appliance/endpoints with the network team.
- Conditional Access/compliance block → resolve compliance via `EPICGOLIVE-Remediation.ps1 -Apply` for that device; confirm the device is in the readiness group and compliant.
- Time skew → correct time source.

**Prevent.** Validate Imprivata agent health and a live badge tap in the pre-go-live sweep (R6); confirm the manual-login fallback works so a single tap failure never stops care.

---

## B. Printing — wristband / label / document won't print

**Symptom.** Print job fails, prints to the wrong device, or nothing happens. Wristband/label failures are **safety-critical**.

**Likely causes.** Printer offline/out of media; printer not mapped on the device; wrong/corrupt driver; print pathway / print-server problem (server-side); wrong default for the workflow.

**Diagnose.**
1. Confirm the physical printer is powered, online, loaded, and error-free.
2. Confirm the device has the correct printer mapped per the readiness checklist print pathway.
3. Print a test page locally; if it fails, suspect driver/mapping. If it succeeds locally but the Epic job fails, suspect the print pathway/server (escalate to print/Epic print Tier-3).
4. Compare against a peer device on the same unit — if all fail, it's the pathway/server, not the device.

**Resolve.**
- Hardware → clear error, load media, bring online.
- Mapping/driver → re-add the printer / reinstall the correct driver via the managed method.
- Pathway/server → escalate to print/Epic print team Tier-3; do not hand-patch around a server fault.
- For safety-critical wristband/label printing, escalate immediately if not resolved in minutes; route the affected workflow to a known-good printer in the interim.

**Prevent.** Confirm printing per device class in Phase 2 (R4) with a functional test print, and document the print pathway in the checklist so triage isn't guessing.

---

## C. Enrollment / compliance — device can't reach Epic or its dependencies

**Symptom.** Device is blocked from Epic/dependencies, shows non-compliant, or isn't manageable.

**Likely causes.** Device never enrolled / dropped enrollment; failing a compliance setting (encryption, OS build, baseline); Conditional Access blocking non-compliant devices; stale/no check-in; wrong/duplicate device identity in Entra.

**Diagnose.**
1. Run `EPICGOLIVE-Discovery.ps1` for the device; read enrollment, compliance, and last check-in.
2. In **Microsoft Intune admin center > Devices > [device] > Compliance**, read the specific failing setting.
3. Check for duplicate/stale Entra device records.
4. Confirm the device is in the **Readiness Device Group – Clinical Fleet – Validation** (untargeted devices won't get policy/fixes).

**Resolve.**
- Specific compliance failure → remediate the named setting; run `EPICGOLIVE-Remediation.ps1 -Apply` for the safe, supported actions (re-sync, re-evaluate).
- Not enrolled → trigger/repair enrollment; re-run discovery.
- Stale/duplicate identity → clean up the stale record (change-controlled).
- Can't fix fast on the floor → **swap in a known-good ready device** so care continues; remediate the failed one off the floor.

**Prevent.** Drive enrollment+compliance to 100% in Phase 2 (R8) and verify in the validation sweep; keep the readiness group synced (R10).

---

## D. Performance — slow login or slow session

**Symptom.** Login or Epic session is slow enough to impede care.

**Likely causes (device-local).** Low disk/RAM, pending reboot, runaway process, oversized roaming profile, heavy startup apps, antivirus on-access scope, slow GPO/login-script processing. **(Back-end).** Resource contention on shared infrastructure, network latency, presentation-layer load.

**Diagnose.**
1. Compare the device to peers on the same unit. **Widespread = back-end**; **isolated = device-local.**
2. Device-local: check disk/RAM, pending reboots, startup/login-script time, profile size, AV scope.
3. Back-end: escalate to the infrastructure/Epic team with the pattern (which units, what time, how many devices).

**Resolve.**
- Device-local → reboot if appropriate; trim startup/profile; correct AV scope; if a single device stays slow, swap in a ready spare and send it to Tier-2.
- Back-end → escalate the pattern; do not chase it device-by-device.

**Prevent.** Set and measure a login-time target per class (R7); remediate outliers in Phase 2 before go-live.

---

## E. Wrong / missing Epic client version

**Symptom.** Client refuses to connect, prompts for an unexpected upgrade, or behaves differently than training.

**Likely causes.** Deployment didn't reach the device (not in readiness group, failed install, no check-in); version drift from a prior build; an unmanaged manual install.

**Diagnose.**
1. Run `EPICGOLIVE-Discovery.ps1` / `EPICGOLIVE-Validation.ps1`; compare the detected version to the designated version (exact string).
2. In **Microsoft Intune admin center > Apps > Monitor > App install status**, check the Epic client deployment result for the device.
3. Confirm the device is in the readiness group.

**Resolve.**
- Redeploy/repair the designated version via the Epic client deployment solution (referenced); re-run discovery to confirm.
- Remove unmanaged manual installs; let the managed deployment own the version.

**Prevent.** Verify the exact version fleet-wide in Phase 2 (R3) and re-confirm in the sweep before the gate.

---

## F. Peripheral not working — scanner / badge reader / signature pad

**Symptom.** A required peripheral doesn't enumerate or doesn't function.

**Likely causes.** Disconnected/failed hardware; missing/wrong driver; driver package not applied; USB/port issue; device not in the group that delivers the driver package.

**Diagnose.**
1. Run `EPICGOLIVE-Validation.ps1` to see whether the expected peripheral enumerates.
2. Physically confirm connection; try another port; test the peripheral on a known-good device to isolate hardware vs. device.
3. Confirm the driver/driver package is present and applied.

**Resolve.**
- Hardware → reseat/replace.
- Driver → install/repair via the managed package; confirm the device is targeted.
- Re-test the function (scan/tap/sign) before declaring resolved.

**Prevent.** Define the expected peripheral set per class and validate it in Phase 2 (R5).

---

## G. Tooling / script issues

**Symptom.** A solution script errors or returns incomplete data.

**Likely causes.** Microsoft Graph not connected or missing scopes; insufficient admin role; throttling on large fleets; readiness group empty/stale; ePHI-minimization filter mis-scoped.

**Diagnose.**
1. Confirm Graph connection and that the required scopes are consented (read-only for discovery/validation/report; minimal write for remediation/group).
2. Confirm your role is sufficient and least-privilege (GR1).
3. For large fleets, check for Graph throttling; re-run with paging/retry.
4. Confirm the readiness group is populated (`EPICGOLIVE-Set-ReadinessGroup.ps1 -WhatIf`).

**Resolve.**
- Reconnect/consent the correct scopes; assign the needed role; let the script's retry handle throttling; repopulate the group.
- If a report looks empty, confirm the scope/group, not the script, is the cause.

**Prevent.** Establish Graph connectivity, scopes, and roles as part of GR1 before Phase 1; rehearse the scripts on the test device (GR6).

---

## H. Command-center / process issues

**Symptom.** Issues pile up, misroute, or escalate slowly during hypercare.

**Likely causes.** A shift/unit unstaffed; engineers swarming the loud issue instead of being dispatched; unclear safety-critical criteria; cross-team Tier-3 contacts not pre-established; runbook steps stale.

**Diagnose & resolve.**
1. Check the roster coverage map against the live floor — fill any unstaffed shift/unit immediately.
2. Reinforce the dispatch model: dispatcher classifies and assigns; engineers don't self-cluster.
3. Re-confirm what counts as safety-critical and that it jumps the ladder.
4. Re-confirm Tier-3 contacts (Epic app, Imprivata, network, print) are reachable on the first hop.
5. Update the triage runbook with any newly found fix so the next shift inherits it.

**Prevent.** Run the command-center dry run (`05-testing.md` §5) — roster walkthrough, dispatch dry run, triage walkthrough, escalation drill, comms cadence — *before* go-live, and fix every gap then.
