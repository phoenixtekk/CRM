# 6. Troubleshooting — Android Enterprise App Management via Managed Google Play (Intune)

Symptom → likely root cause → fix. Start with **`ANDROIDAPP-Scope.ps1`** (binding + app-sync health)
and **`ANDROIDAPP-Discovery.ps1`** (assignment posture) — most app-delivery failures are a stale sync,
a missing assignment, or the wrong intent for the enrollment model.

## Approved app never appears on devices
- **Root cause:** managed Google Play **app sync stale/errored**, or the app isn't assigned (or assigned
  to a group the device isn't in), or the intent doesn't match the model.
- **Fix:** run `ANDROIDAPP-Scope.ps1` — if last app-sync isn't recent/`success`, trigger a **Sync** in
  **Devices > Android > Android enterprise**. Confirm the assignment with `ANDROIDAPP-Discovery.ps1`; verify
  the device is in the target group and the intent is **Required** (silent) for fully managed/dedicated.

## App is Required but doesn't install silently on work-profile BYOD
- **Root cause:** on **work profile (BYOD)**, apps land in the work profile and users often **pull**
  them; a Required push may still need the work Play Store to process it, and personal-side apps are untouched.
- **Fix:** confirm the device is truly work-profile enrolled; allow time/sync. If the intent should be
  user-initiated, use **Available for enrolled devices** instead. Verify against current Microsoft
  guidance for the exact per-model behavior.

## App opens blank / prompts for setup (managed config not applied)
- **Root cause:** no **app-config policy** for the app's package, wrong **profile applicability**
  (personally-owned work profile vs fully managed/dedicated), or the policy isn't assigned to the device's group.
- **Fix:** `ANDROIDAPP-AssignConfig.ps1 -WhatIf` reports whether a config is attached for the package.
  Create/attach an app-config policy with the **matching profile type**, set the app's **managed
  configuration keys**, and assign it to the same group as the app.

## OEMConfig setting not taking effect (Samsung Knox / Zebra)
- **Root cause:** the OEMConfig **app isn't deployed**, the wrong **schema key** was set, or the OEM
  requires a specific enrollment model.
- **Fix:** ensure the OEM's OEMConfig app (e.g. Knox Service Plugin, Zebra OEMConfig) is deployed and
  assigned, then set keys **from the OEM's documented schema** (vendor-authoritative). Confirm the
  device model/OS supports the setting per the OEM.

## App protection controls not enforced (no PIN / copy-paste still works)
- **Root cause:** APP policy not assigned to the user/group, the app not added to the policy, or (MAM-only)
  the **Company Portal**/APP broker prerequisite missing on the device.
- **Fix:** `ANDROIDAPP-AppProtection.ps1` (read mode) lists policies + assignments — confirm the app is
  in the policy and the policy is assigned. Ensure Company Portal is present for MAM-only. Re-open the
  app's corporate data to trigger enforcement.

## App on the wrong update track / not updating as expected
- **Root cause:** the assignment's **track** isn't set to the intended track, the device isn't in the
  track's group, or the **auto-update mode** differs from expectation.
- **Fix:** `ANDROIDAPP-Discovery.ps1` shows Tracks + AutoUpdate per assignment. Set the intended
  **track** and **auto-update mode** in the app's assignment settings (`ANDROIDAPP-AssignConfig.ps1 -WhatIf`
  to preview). For a **closed/Beta track**, the device/account must be a member of that track in managed
  Google Play.

## Editing one assignment removed other groups
- **Root cause:** the Graph **`assign` action replaces ALL** of an app's assignments — sending a partial
  set drops the rest.
- **Fix:** always read the current set first (`ANDROIDAPP-Discovery.ps1`) and re-send the **full**
  intended set. `ANDROIDAPP-AssignConfig.ps1` does this automatically (preserves other groups, gated
  behind `-Commit`). Restore a dropped group by re-adding it in the full set.

## Private LOB / web app not visible in Intune
- **Root cause:** the app was **published on the Google side** but not yet synced/approved, or published
  to the wrong organization.
- **Fix:** confirm it appears in the managed Google Play iframe under your organization, **Approve**, and
  **Sync**. The private-publishing surface evolves — verify against current Google guidance/your publisher account.

## Uninstall intent didn't remove the app
- **Root cause:** the **Uninstall** assignment isn't targeting the device's group, or the app is also
  Required elsewhere (a conflicting Required assignment wins).
- **Fix:** ensure no other group assigns the app as **Required** to the same device; set **Uninstall** on
  the correct group; sync. Verify with `ANDROIDAPP-Discovery.ps1`.

## "Can't add a Google account" / enrollment-side failures
- **Root cause:** network reachability to Google/Microsoft endpoints blocked, or a **connector / AMAPI**
  issue (out of scope for app delivery but blocks it upstream).
- **Fix:** confirm required endpoints are allowed (category global requirement 5). Connector/AMAPI-level
  problems are **high-impact** — handle under change control and **verify re-enrollment behavior against
  current Microsoft guidance / your tenant** before acting.

---
### First moves for any app-delivery issue
1. `ANDROIDAPP-Scope.ps1` — is the binding healthy and app-sync recent/successful?
2. `ANDROIDAPP-Discovery.ps1` — is the app assigned, to the right group, with the right intent + track?
3. `ANDROIDAPP-Validation.ps1` — does the app have config + protection + a defined track (the four gates)?
4. Only then change configuration — preview with `-WhatIf`, keep the current set as your rollback.
