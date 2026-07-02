# Troubleshooting — Continuous Compliance Monitoring & Audit-Evidence Automation

Use this guide when a step in the Implementation or Testing guide does not behave as described. Each
entry is **Symptom → Likely cause → Fix.** Items map to the scripts and pass/fail gates.

---

## Connectivity & permissions

**Symptom:** A script fails on connect with a consent or permissions error, or returns no data.
**Likely cause:** The operator lacks a required role, or the delegated Graph read scopes were not
consented.
**Fix:** Confirm the operator holds at least **Global Reader** plus **Intune Administrator** (R2, G3).
Re-run and consent the read scopes when prompted:
`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`,
`Policy.Read.All`, `Directory.Read.All`, `Group.Read.All`. If a tenant admin must grant consent,
have them approve the app's delegated permissions, then re-run.

**Symptom:** `Microsoft.Graph module not found`.
**Likely cause:** The Graph PowerShell SDK is not installed.
**Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`, then re-run.

**Symptom:** Scheduled fleet run works interactively but not unattended (T7).
**Likely cause:** The scheduled-task account has not consented the Graph scopes, or cannot write to the
destination.
**Fix:** Run each script once interactively as the task account to complete consent; grant that
account write access to the staging/destination folders (R3).

---

## Discovery (CCAUDIT-Discovery.ps1)

**Symptom:** Discovery runs but your baseline profiles/policies are missing from the output.
**Likely cause:** The baseline was never built/assigned, or lives in an object type not queried.
**Fix:** Confirm the baseline exists in Intune (Endpoint security → Security baselines; Devices →
Configuration) and Entra (Conditional Access) — see R1. If custom objects are used, note their type;
you can still record them manually in `CCAUDIT-Baseline.json`.

**Symptom:** Baseline template has placeholder values (`REPLACE-...`).
**Likely cause:** The template is meant to be completed by you.
**Fix:** Fill in each control's **ControlId** (your CIS/STIG reference — deferred to CIS/DISA),
**SettingName**, **ExpectedValue**, and **Severity**, save as `CCAUDIT-Baseline.json`, and approve it
under change control (Gate 1/T2).

---

## Baseline reference

**Symptom:** Validation throws "Baseline reference not found" or "is empty".
**Likely cause:** `CCAUDIT-Baseline.json` is missing, mis-pathed, or invalid JSON.
**Fix:** Point `-BaselinePath` at the correct file; validate the JSON parses
(`Get-Content ... | ConvertFrom-Json`). Regenerate from Discovery `-EmitBaselineTemplate` if needed.

---

## Validation (CCAUDIT-Validation.ps1)

**Symptom:** "Target group not found."
**Likely cause:** `CCAUDIT-Pilot-Devices` (or the named group) does not exist.
**Fix:** Create it via Entra → Groups, or run `CCAUDIT-Set-ScopeTargeting.ps1` (preview then
`-Commit`). Confirm the display name matches exactly (R5).

**Symptom:** No device rows / "No device members found."
**Likely cause:** The target group has no device members, or contains users instead of devices.
**Fix:** Add the representative **enrolled devices** to the group. For device-based measurement, the
group members must be devices with an `azureADDeviceId`.

**Symptom:** Controls show verdict **Missing** for devices you know are compliant.
**Likely cause:** The device is not returned in managed-device state (not enrolled/reporting), or the
baseline object is not assigned to that device.
**Fix:** Confirm the device is enrolled and compliant in Intune → Devices → All devices (G4). Confirm
the baseline is assigned to a group that includes the device. "Missing" is a targeting/enrollment
signal, not a drift.

**Symptom:** Every control shows the same verdict for a device regardless of setting.
**Likely cause:** Observed value is derived from overall device compliance where per-setting reporting
is unavailable, so all controls share the device's compliance signal.
**Fix:** This is expected where Intune does not expose per-setting state for that object type; refine
`CCAUDIT-Baseline.json` to point each control at an object whose state is individually reportable, or
accept device-level conformance as the observed signal for that control.

---

## Drift detection (Testing T4)

**Symptom:** A deliberately-changed setting is **not** detected as Drift.
**Likely cause:** You changed a setting that is not in the monitored set, or Validation reads a
different object than the one you edited.
**Fix:** Confirm the changed setting corresponds to a control in `CCAUDIT-Baseline.json` and that its
**TargetObject** is the object you edited. Allow time for the device to report the new state, then
re-run.

**Symptom:** Unrelated controls flip to Drift after one change.
**Likely cause:** Shared observed-value signal (device compliance) affecting multiple controls, or a
broad policy change.
**Fix:** Narrow the baseline entries to individually-reportable objects; verify only the intended
policy was changed.

---

## Report / evidence (CCAUDIT-Report.ps1)

**Symptom:** "Validation file not found" or "is empty."
**Likely cause:** No validation run was produced, or the wrong path/timestamp was passed.
**Fix:** Run `CCAUDIT-Validation.ps1` first; pass the exact `CCAUDIT-Validation-<timestamp>.json`.

**Symptom:** Evidence rows are missing provenance fields (T5).
**Likely cause:** The validation output was hand-edited or truncated.
**Fix:** Do not edit validation output. Re-run Validation to regenerate a complete file, then
re-report.

**Symptom:** No POA&M rows despite known failures.
**Likely cause:** No rows carry Drift/Missing/Non-conformant verdicts (all Pass), or the validation
file is stale.
**Fix:** Confirm failures exist in the validation output; re-run Validation against current state.

**Symptom:** Evidence cannot be copied to the destination.
**Likely cause:** Missing write permission or the destination path is wrong (R3).
**Fix:** Grant the operator write access; verify the destination path; confirm retention/immutability
settings (R4) do not block the write path used for new files.

---

## Remediation (CCAUDIT-Remediation.ps1)

**Symptom:** Preview appears to change state.
**Likely cause:** `-Commit` was passed (which disables preview).
**Fix:** Run without `-Commit` for preview. Only add `-Commit` inside an approved change window with a
documented rollback (G8).

**Symptom:** After `-Commit`, the control does not return to Pass on re-measure.
**Likely cause:** The re-assignment did not reach the device yet, or the drift source persists (for
example a local admin re-changing the setting).
**Fix:** Allow policy sync time and re-run Validation. If it recurs, address the root cause (remove
local rights, correct the policy) rather than repeatedly remediating.

**Symptom:** "Baseline group not found."
**Likely cause:** `CCAUDIT-Fleet-Devices` (or the named baseline group) does not exist.
**Fix:** Build it with `CCAUDIT-Set-ScopeTargeting.ps1` (preview then `-Commit`).

---

## Scope targeting (CCAUDIT-Set-ScopeTargeting.ps1)

**Symptom:** Group/members not created after `-Commit`.
**Likely cause:** The operator lacks `Group.ReadWrite.All`, or candidate objects were not devices.
**Fix:** Consent `Group.ReadWrite.All`; confirm candidates are device objects. Re-run preview to
verify the plan, then `-Commit`.

**Symptom:** Pilot group has too many/few members.
**Likely cause:** `-PilotSampleSize` default, or a source group with unexpected membership.
**Fix:** Set `-PilotSampleSize` to the desired count, or pass `-SourceGroupName` to seed from a known
group; review the preview plan before committing.

---

## When to stop and escalate

- Do **not** run Remediation on the fleet if the pilot gates (T4/T6) did not pass.
- Do **not** treat exports as audit evidence until T1–T6 pass on the pilot and T7 on the fleet.
- If evidence integrity is ever in doubt (edited files, gaps in the series), re-run the full cycle to
  regenerate authoritative records rather than patching output by hand.
