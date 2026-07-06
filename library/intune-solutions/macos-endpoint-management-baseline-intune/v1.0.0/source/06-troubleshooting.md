# 6. Troubleshooting Guide — macOS Endpoint Management Baseline (Microsoft Intune)

Field issues and how to resolve them. Reuse the **exact** object names from the Implementation Guide.
Start most investigations with `MACBASE-Discovery.ps1` (readiness) and `MACBASE-Report.ps1` (posture).

## A. Nothing applies to any Mac
**Symptoms:** No baseline policy shows a device status; Macs never receive profiles.
**Likely causes & fixes:**
- **APNs certificate missing or expired.** Without a valid Apple MDM Push certificate, **no** profile,
  compliance policy, or update policy reaches any Mac. Intune → **Devices → Enrollment → Apple → Apple
  MDM Push certificate**; confirm present and **not expired** (Requirement 2.3). `MACBASE-Discovery.ps1`
  reports expiry. Renew with the **same** Apple ID used to create it — a different Apple ID forces
  re-enrollment of every Mac.
- **Macs not actually enrolled/managed.** Intune → **Devices → macOS → macOS devices**; confirm the
  target Macs appear as managed (Requirement 2.4).
- **Policy assigned to an empty or wrong group.** Confirm the pilot Macs are members of
  `macOS Baseline – Pilot Devices` and that the policy's **Assignments** include that group.

## B. A single Mac is not applying the baseline
**Symptoms:** Most pilot Macs succeed; one does not.
**Fixes:**
- **Group membership.** Confirm the Mac is in the assigned group (dynamic-group membership can lag —
  give it time or re-evaluate).
- **Force a sync.** On the Mac: **Company Portal → ⋯ → Check status**, or **System Settings → Privacy &
  Security → Profiles** and let it refresh. Then run `MACBASE-Validation.ps1 -DeviceName the-mac-name`.
- **Stale/duplicate device record.** A re-imaged Mac can leave an orphaned record. Remove the stale
  record so status reflects the live device.

## C. Device status shows "Error" or "Conflict"
**Symptoms:** A baseline policy reports **Error** or **Conflict** on the Per-setting status.
**Fixes:**
- **Conflict = two authorities.** The same Apple payload is being set by **two** policies (for example
  a legacy "Device restrictions" template and your new settings-catalog restrictions policy, or two
  catalog policies). Find both and **remove the setting from one**. Run `MACBASE-Discovery.ps1` to list
  every macOS policy touching the area before you build, to avoid this.
- **Error = payload rejected.** Often a value the current macOS version does not accept, or a payload
  requiring supervision the Mac lacks. Check the Per-setting detail, confirm the value against Apple's
  documentation for that macOS version, and adjust.

## D. Restrictions not taking effect
**Symptoms:** A restriction (e.g. AirDrop, content caching) is set in Intune but not enforced on the
Mac.
**Fixes:**
- Confirm `macOS Baseline – Restrictions – Pilot` shows **Succeeded** on the device (Testing Test 2).
- Some restriction payloads apply **only to supervised** (ADE-enrolled) Macs. A user-enrolled Mac may
  ignore them by design — verify the payload's supervision requirement in Apple's documentation. This
  is a platform constraint, not a misconfiguration.
- Check for a **conflicting** profile also setting that payload (see C).

## E. Software updates not enforcing
**Symptoms:** `macOS Baseline – Software Update – Pilot` shows Succeeded but Macs do not update, or the
deadline never fires.
**Fixes:**
- **macOS version dependency.** Update-enforcement behaviour — especially Declarative Device
  Management-based enforcement — depends on the macOS major version. Confirm your Macs are on a version
  that supports the setting you configured (`MACBASE-Discovery.ps1` shows the version spread); on older
  macOS, some enforcement options simply do not apply.
- **No update available / already current.** Nothing enforces if the Mac is already at or above the
  target version.
- **Network to Apple update servers.** The Mac needs outbound access to Apple's software-update
  endpoints; a proxy/firewall block prevents downloads.

## F. Compliance policy marks Macs non-compliant unexpectedly
**Symptoms:** Macs you expected to be compliant evaluate **non-compliant** against
`macOS Baseline – Compliance`.
**Fixes:**
- **FileVault rule but FileVault not on.** If the policy requires FileVault, a Mac without encryption
  is correctly non-compliant — deploy encryption (a separate profile/solution) or adjust the rule.
- **Minimum OS version set above the fleet.** Lower the threshold or update the Macs.
- **Grace period.** A freshly-assigned device is non-compliant until it reports in and the grace period
  elapses — allow a sync cycle, then recheck **Company Portal**.

## G. Custom `.mobileconfig` profile shows applied but the setting is wrong
**Symptoms:** `macOS Baseline – Custom – Pilot` reports **Succeeded**, but the intended behaviour is
absent.
**Fixes:**
- A custom profile is **opaque** — Intune reports "applied", not whether the payload is correct.
  Validate the payload keys/values against **Apple's public MDM documentation**; a wrong key applies
  silently with no effect. Prefer moving the setting to the **settings catalog** if a catalog payload
  exists (per-setting status makes errors visible).
- Confirm the **deployment channel** (device vs user) matches the payload's requirement.

## H. Drift after a Mac was compliant
**Symptoms:** `MACBASE-Report.ps1` shows Macs that previously succeeded now drifted.
**Fixes:**
- A user removed a profile, a conflicting policy was added, or an apply failed. Run
  `MACBASE-Remediation.ps1 -PolicyNameLike "macOS Baseline"` (preview first, then `-WhatIf:$false`) to
  re-sync the drifted Macs so the baseline re-applies.
- If a Mac **keeps** drifting, there is a persistent conflict (section C) — resolve the second
  authority rather than repeatedly re-syncing.

## I. Scripts fail to connect or return nothing
**Symptoms:** A `MACBASE-*` script errors on `Connect-MgGraph`, or returns no objects.
**Fixes:**
- **Consent/scopes.** On first run, sign in with an account that can consent to the read scopes
  (Discovery/Validation/Report) or the read-write scope (`MACBASE-Set-ScopeTargeting.ps1` needs
  `DeviceManagementConfiguration.ReadWrite.All`). An Intune Administrator or equivalent is typically
  required.
- **Graph SDK missing.** The scripts install `Microsoft.Graph` for the current user if absent; if the
  install is blocked, install it manually (`Install-Module Microsoft.Graph -Scope CurrentUser`).
- **Name-prefix mismatch.** The scripts find objects by the `-PolicyNameLike` prefix (`macOS Baseline`
  by default). If you renamed the policies, pass the matching `-PolicyNameLike`.
- **`-WhatIf` returned no change (expected).** `MACBASE-Remediation.ps1` and
  `MACBASE-Set-ScopeTargeting.ps1` default to preview — pass `-WhatIf:$false` to apply.

## J. Rollback
**Symptoms:** A baseline setting broke a legitimate workflow on the pilot.
**Fix:** In Intune, **remove the assignment** of the offending policy from
`macOS Baseline – Pilot Devices` (or set the specific setting to **Not configured**), then sync.
Removing the assignment is the fastest safe rollback — the Mac reverts on the next policy cycle. Record
the change and the offending setting, then re-pilot the corrected policy.

---
### First moves for any issue
1. `MACBASE-Discovery.ps1` — APNs, enrollment, and conflicting-policy check.
2. `MACBASE-Report.ps1` — where the drift/errors are, by object.
3. `MACBASE-Validation.ps1 -DeviceName <mac>` — deep-dive one Mac.
4. Resolve conflicts (section C) before re-syncing; use `MACBASE-Remediation.ps1` to re-apply.
