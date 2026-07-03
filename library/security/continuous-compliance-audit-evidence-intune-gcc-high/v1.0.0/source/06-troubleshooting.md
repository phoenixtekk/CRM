# Troubleshooting — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

Use this guide when a step in the Implementation or Testing guide does not behave as described. Each
entry is **Symptom → Likely cause → Fix.** Items map to the scripts and pass/fail gates. **The first
section is GCC-High-specific — check it first**, because most Gov failures are cloud/parity issues, not
logic bugs.

---

## GCC High / DoD — wrong cloud, wrong endpoint, missing feature (check first)

**Symptom:** A script connects but returns **no data**, or authentication fails with an unknown-account
error.
**Likely cause:** You connected to the **Commercial** cloud (`graph.microsoft.com`) instead of US Gov,
so your Gov objects aren't there — or the account isn't recognized on the Commercial endpoint.
**Fix:** Confirm the environment. Run `Get-MgContext` — the Graph host must be `graph.microsoft.us`
(GCC High) or `dod-graph.microsoft.us` (DoD). Re-run the script with **`-Environment USGov`** (GCC
High) or **`-Environment USGovDoD`** (DoD). Sign-in must be at `login.microsoftonline.us`. See
`gcc-high-parity-notes.md` §1.

**Symptom:** A portal you were told to open loads at a `.com` address.
**Likely cause:** You opened the Commercial portal.
**Fix:** Use the **US Gov** hosts: Intune `intune.microsoft.us`, Entra `entra.microsoft.us`, Microsoft
365 `portal.office365.us`, sign-in `login.microsoftonline.us`. If it still redirects to `.com`, your
browser session is signed into a Commercial tenant — sign out and sign in to the Gov tenant.

**Symptom:** A menu, report, or connector referenced in a Commercial runbook is **not present** in
`intune.microsoft.us` (for example the **Power BI / Data Warehouse connector**, **ServiceNow
connector**, **Windows Autopatch / update rings**, **BIOS/DFCI profiles**, **Remote Help**, **Security
Copilot**, **Device Health Attestation**).
**Likely cause:** This is a **GCC High/DoD parity gap**, not a permissions or configuration problem —
the feature is *planned-not-yet-available* or *not available* in the government cloud.
**Fix:** Confirm the feature's status in `gcc-high-parity-notes.md` (§2–§4). Do not troubleshoot a
missing option as if it were a bug. Use the documented alternative — export the **POA&M CSV** and import
it into your GRC/ITSM manually (no ServiceNow connector), build dashboards on **Log Analytics** (no
Power BI DWH connector), and manage updates/BIOS/attestation controls **out-of-band**.

**Symptom:** Scheduled unattended run works interactively but fails as a task.
**Likely cause:** The task account never consented the **US Gov** Graph scopes, or the host cannot reach
`graph.microsoft.us` / `login.microsoftonline.us`.
**Fix:** Run each script once interactively **as the task account** with the correct `-Environment` to
complete US Gov consent; ensure the host (inside your Gov boundary) can reach the US Gov endpoints
through the proxy/firewall (see global requirement G7 and `gcc-high-parity-notes.md` §1).

---

## Connectivity & permissions

**Symptom:** A script fails on connect with a consent or permissions error, or returns no data.
**Likely cause:** The operator lacks a required role, or the delegated Graph read scopes were not
consented (against US Gov).
**Fix:** Confirm the operator holds at least **Global Reader** plus **Intune Administrator** (R2, G3).
Re-run (with `-Environment USGov`/`USGovDoD`) and consent the read scopes when prompted:
`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`, `Policy.Read.All`,
`Directory.Read.All`, `Group.Read.All`. If a tenant admin must grant consent, have them approve the
app's delegated permissions in the **Gov** tenant, then re-run.

**Symptom:** `Microsoft.Graph module not found`.
**Likely cause:** The Graph PowerShell SDK is not installed.
**Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`, then re-run.

---

## Discovery (CCAUDITG-Discovery.ps1)

**Symptom:** Discovery runs but your baseline profiles/policies are missing from the output.
**Likely cause:** The baseline was never built/assigned in the **Gov** tenant, or lives in an object
type not queried, or you connected to the wrong cloud.
**Fix:** Confirm `Get-MgContext` shows a `*.microsoft.us` Graph host. Confirm the baseline exists in
Intune (`intune.microsoft.us` → Endpoint security → Security baselines; Devices → Configuration) and
Entra (`entra.microsoft.us` → Conditional Access) — see R1. If custom objects are used, note their type;
you can still record them manually in `CCAUDITG-Baseline.json`.

**Symptom:** Baseline template has placeholder values (`REPLACE-...`).
**Likely cause:** The template is meant to be completed by you.
**Fix:** Fill in each control's **ControlId** (your CIS/STIG reference — deferred to CIS/DISA),
**SettingName**, **ExpectedValue**, and **Severity**, save as `CCAUDITG-Baseline.json`, and approve it
under change control (Gate 1/T2). Do not include controls whose enforcement mechanism is unavailable in
GCC High (BIOS/DFCI, update rings, DHA) — mark those out-of-band.

---

## Baseline reference

**Symptom:** Validation throws "Baseline reference not found" or "is empty".
**Likely cause:** `CCAUDITG-Baseline.json` is missing, mis-pathed, or invalid JSON.
**Fix:** Point `-BaselinePath` at the correct file; validate the JSON parses
(`Get-Content ... | ConvertFrom-Json`). Regenerate from Discovery `-EmitBaselineTemplate` if needed.

---

## Validation (CCAUDITG-Validation.ps1)

**Symptom:** "Target group not found."
**Likely cause:** `CCAUDITG-Pilot-Devices` (or the named group) does not exist in the Gov tenant.
**Fix:** Create it via `entra.microsoft.us` → Groups, or run `CCAUDITG-Set-ScopeTargeting.ps1` (preview
then `-Commit`). Confirm the display name matches exactly (R5).

**Symptom:** No device rows / "No device members found."
**Likely cause:** The target group has no device members, or contains users instead of devices.
**Fix:** Add the representative **enrolled devices** to the group. For device-based measurement, the
group members must be devices with an `azureADDeviceId`.

**Symptom:** Controls show verdict **Missing** for devices you know are compliant.
**Likely cause:** The device is not returned in managed-device state (not enrolled/reporting), or the
baseline object is not assigned to that device.
**Fix:** Confirm the device is enrolled and compliant in `intune.microsoft.us` → Devices → All devices
(G4). Confirm the baseline is assigned to a group that includes the device. "Missing" is a
targeting/enrollment signal, not a drift.

**Symptom:** Every control shows the same verdict for a device regardless of setting.
**Likely cause:** Observed value is derived from overall device compliance where per-setting reporting
is unavailable, so all controls share the device's compliance signal.
**Fix:** This is expected where Intune does not expose per-setting state for that object type; refine
`CCAUDITG-Baseline.json` to point each control at an object whose state is individually reportable, or
accept device-level conformance as the observed signal for that control.

---

## Drift detection (Testing T4)

**Symptom:** A deliberately-changed setting is **not** detected as Drift.
**Likely cause:** You changed a setting that is not in the monitored set, or Validation reads a
different object than the one you edited.
**Fix:** Confirm the changed setting corresponds to a control in `CCAUDITG-Baseline.json` and that its
**TargetObject** is the object you edited. Allow time for the device to report the new state, then
re-run.

**Symptom:** Unrelated controls flip to Drift after one change.
**Likely cause:** Shared observed-value signal (device compliance) affecting multiple controls, or a
broad policy change.
**Fix:** Narrow the baseline entries to individually-reportable objects; verify only the intended policy
was changed.

---

## Report / evidence (CCAUDITG-Report.ps1)

**Symptom:** "Validation file not found" or "is empty."
**Likely cause:** No validation run was produced, or the wrong path/timestamp was passed.
**Fix:** Run `CCAUDITG-Validation.ps1` first; pass the exact `CCAUDITG-Validation-<timestamp>.json`.

**Symptom:** Evidence rows are missing provenance fields (T5).
**Likely cause:** The validation output was hand-edited or truncated.
**Fix:** Do not edit validation output. Re-run Validation to regenerate a complete file, then re-report.

**Symptom:** No POA&M rows despite known failures.
**Likely cause:** No rows carry Drift/Missing/Non-conformant verdicts (all Pass), or the validation file
is stale.
**Fix:** Confirm failures exist in the validation output; re-run Validation against current state.

**Symptom:** Evidence cannot be copied to the destination, or can't reach ServiceNow.
**Likely cause:** Missing write permission or wrong destination path (R3) — or you expected the Intune
**ServiceNow connector**, which is **not available** in GCC High.
**Fix:** Grant the operator write access; verify the in-boundary destination path; confirm
retention/immutability settings (R4) do not block new-file writes. For POA&M routing, import the CSV into
your GRC/ITSM manually (see `gcc-high-parity-notes.md` §2).

---

## Remediation (CCAUDITG-Remediation.ps1)

**Symptom:** Preview appears to change state.
**Likely cause:** `-Commit` was passed (which disables preview).
**Fix:** Run without `-Commit` for preview. Only add `-Commit` inside an approved change window with a
documented rollback (G8).

**Symptom:** After `-Commit`, the control does not return to Pass on re-measure.
**Likely cause:** The re-assignment did not reach the device yet, the drift source persists (for example
a local admin re-changing the setting), or the control's enforcement mechanism is **not available in GCC
High** (update ring, BIOS/DFCI, DHA).
**Fix:** Allow policy sync time and re-run Validation. If it recurs, address the root cause (remove local
rights, correct the policy). If the control relies on an unavailable GCC High mechanism, remediate
**out-of-band** and record it in the POA&M rather than expecting Intune to enforce it.

**Symptom:** "Baseline group not found."
**Likely cause:** `CCAUDITG-Fleet-Devices` (or the named baseline group) does not exist.
**Fix:** Build it with `CCAUDITG-Set-ScopeTargeting.ps1` (preview then `-Commit`).

---

## Scope targeting (CCAUDITG-Set-ScopeTargeting.ps1)

**Symptom:** Group/members not created after `-Commit`.
**Likely cause:** The operator lacks `Group.ReadWrite.All`, or candidate objects were not devices.
**Fix:** Consent `Group.ReadWrite.All` (against US Gov); confirm candidates are device objects. Re-run
preview to verify the plan, then `-Commit`.

**Symptom:** Pilot group has too many/few members.
**Likely cause:** `-PilotSampleSize` default, or a source group with unexpected membership.
**Fix:** Set `-PilotSampleSize` to the desired count, or pass `-SourceGroupName` to seed from a known
group; review the preview plan before committing.

---

## When to stop and escalate

- Do **not** trust any result until `Get-MgContext` confirms you are on **US Gov** (`*.microsoft.us`).
- Do **not** run Remediation on the fleet if the pilot gates (T4/T6) did not pass.
- Do **not** treat exports as audit evidence until T0–T6 pass on the pilot and T7 on the fleet.
- Do **not** troubleshoot a missing GCC High feature as a bug — confirm it against
  `gcc-high-parity-notes.md` and use the documented alternative.
- If evidence integrity is ever in doubt (edited files, gaps in the series), re-run the full cycle to
  regenerate authoritative records rather than patching output by hand.
