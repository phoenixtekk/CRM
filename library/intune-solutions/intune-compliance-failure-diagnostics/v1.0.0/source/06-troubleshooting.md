# Troubleshooting

Common problems seen **while running this diagnostic solution itself** — reading state,
running the scripts, and confirming a fix. For diagnosing the *device's* compliance failure,
use the **Diagnostic Playbook** (`03-implementation.md`); this page fixes the toolkit and the
console around it. Each entry: **Symptom → Cause → Fix.**

---

### The console shows non-compliant but no setting looks failed
**Symptom:** Device state is **Not compliant**, but expanding the policy shows every setting
Compliant (or blank).
**Cause:** Report lag — the device evaluated a fix but the per-setting view has not refreshed;
or a second policy from another assignment is the one failing.
**Fix:** Force a **Sync**, wait for the next check-in and report, re-open the blade. Check
**all** assigned policies on the device, not just the obvious one — the least-compliant
policy wins. Confirm with `INTCOMPDX-Validation.ps1 -DeviceName "<device>"`.

---

### `Connect-MgGraph` fails or scopes are missing
**Symptom:** Sign-in errors, or `Get-MgContext` does not list the needed scope; cmdlets
return **authorization** / 403 errors.
**Cause:** The Microsoft Graph SDK is not installed, admin consent was never granted, or you
connected without the required scopes.
**Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`, then
`Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","Policy.Read.All"`
and **Accept** the consent prompt (or have a Global Administrator grant admin consent to
**Microsoft Graph Command Line Tools**). Re-check with `Get-MgContext`.

---

### Scripts return no devices / empty results
**Symptom:** Discovery/Report run cleanly but return nothing.
**Cause:** Missing read scope, a scope/RBAC boundary limiting what the account can see, or a
filter (device name / policy name) that does not match.
**Fix:** Confirm scopes (above) and that the account's Intune role can read compliance and
devices (R1). Check the exact object name in the console and reuse it verbatim — names are
case- and spelling-sensitive. Run without a name filter first to confirm data returns.

---

### A setting shows "Error" instead of Not compliant
**Symptom:** Per-setting state is **Error**.
**Cause:** The setting could not be **evaluated** — a Custom compliance script did not return
valid JSON, timed out, was blocked by script signing, or the Intune management extension is
unhealthy. This is **not** a compliance verdict.
**Fix:** On the device, run the detection script manually and confirm it emits valid JSON;
check script signing and the management extension. Fix the script/agent — the setting cannot
report Compliant until it evaluates cleanly. See Playbook Step 3B.

---

### Fixed the device but Conditional Access still blocks the user
**Symptom:** Device reports **Compliant** but the user is still blocked.
**Cause:** Timing across the three clocks — CA read a stale state, or the user's existing
token predates the fix.
**Fix:** Confirm device state is Compliant, then have the user **sign out and back in** (or
wait for token refresh). Re-check the **Sign-in logs → Conditional Access** tab for the
compliance control turning **Success**. See Playbook Step 5.

---

### Grace makes a failing device look compliant
**Symptom:** A device with a genuinely failing setting reports **Compliant** and is not
blocked.
**Cause:** The setting is failing but still **within the grace window** (Actions for
noncompliance), so CA is not enforcing yet.
**Fix:** This is expected behaviour, not a bug — but do not ignore it. Fix the real setting
before grace expires. Do **not** extend grace to keep it hidden. See Playbook Step 4.

---

### Remediation script "did nothing"
**Symptom:** `INTCOMPDX-Remediation.ps1` (or `Set-ScopeTargeting`) reported planned actions
but changed nothing.
**Cause:** Both default to **-WhatIf** — they only preview.
**Fix:** Review the previewed actions, then re-run with `-WhatIf:$false` to commit. This is
intentional so diagnosis is always safe to run.

---

### Widespread failure appeared suddenly across many devices
**Symptom:** Many devices flipped non-compliant on the same setting at once.
**Cause:** A policy edit, a broken Custom compliance script/JSON pushed to everyone, or a
service-side change (new Defender platform, OS floor).
**Fix:** Use `INTCOMPDX-Report.ps1` to confirm the single setting driving the count, find
what changed, fix the **cause** staged to a pilot group — do not mass-exempt or disable the
policy. See Playbook Step 6.

---

### "Not applicable" on a setting you expected to enforce
**Symptom:** A setting shows **Not applicable** rather than Compliant/Not compliant.
**Cause:** The setting does not apply to that device's OS/edition, or the policy is not truly
assigned to that device.
**Fix:** Confirm the policy assignment reaches the device and that the setting applies to its
OS/edition. Use `INTCOMPDX-Discovery.ps1` to verify policy targeting.

---

If a symptom is not listed here, return to the **Diagnostic Playbook** and work the tree from
Step 0 — the failure is almost always one of: timing, grace, a real setting, a custom-rule
error, or Conditional Access.
