# 6. Troubleshooting Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Work top-down: confirm the requirement, reproduce on the **test device** first, and only then act on
patient-care devices. Where a script helps, it is named. For Epic-installer specifics (switches,
version strings, environment config), confirm with your **Epic build team / Epic UserWeb** —
this guide covers the **Intune / ConfigMgr** mechanics.

---

## A. Install fails or never starts

**Symptom:** Intune → **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Device install status**
shows **Failed**, or the install never runs.

1. **Silent command not actually silent.** Re-run `<EPIC_INSTALLER> <EPIC_SILENT_ARGS>` by hand on the
   test device (Implementation Step 2). If it prompts, the Intune **Install command** is wrong — get
   the correct silent switches from your Epic build team and update **Program → Install command**.
2. **Requirement rule excludes the device.** Check **Properties → Requirements** — wrong minimum OS /
   architecture will leave the app **Not applicable**. Confirm the device meets it (`winver`).
3. **WebView2 dependency failing (Hyperdrive).** If the WebView2 dependency app is failing, the Epic
   app won't proceed. Check the WebView2 app's own install status; fix it first (Section D).
4. **Install behavior wrong.** Shared clinical devices need **Install behavior = System**. A
   per-user install on a shared device misbehaves — set it to **System**.
5. **Non-standard return codes.** If `<EPIC_INSTALLER>` returns a code Intune treats as failure,
   map it under **Program → Return codes** (e.g. add the installer's success/soft-reboot codes).
6. **Nudge the device:** run **`EPICCLIENT-Remediation.ps1 -AppName "Epic Hyperdrive - <EPIC_VERSION>" -Apply`**
   to force an MDM sync, wait, then re-check.

## B. Detection mismatch (installs but Intune says "Not installed", or re-installs in a loop)

**Symptom:** The Epic client is clearly on the device, but Intune reports **Not installed** (or
keeps reinstalling).

1. **Detection value doesn't match reality.** On the test device run **`EPICCLIENT-Discovery.ps1`** and
   compare the **actual** version / path / registry key to the **detection rule** (Implementation
   Step 7). They must match exactly.
2. **Wrong detection type.** If the installer registers an MSI product code, a **File version** rule
   on the wrong path won't detect it (and vice-versa). Switch the rule type to match how
   `<EPIC_INSTALLER>` actually registers (Requirements §R8).
3. **Operator too strict/loose.** A **String (version) – Greater than or equal to** rule against
   `<EPIC_VERSION>` is usually right. An **Equals** on a version that the installer formats slightly
   differently will read as "not installed."
4. **Path with environment specifics.** Ensure `<EPIC_INSTALL_DIR>` / `<EPIC_EXE>` in the rule are the
   real installed path/name, not a guess.

## C. Version drift (devices stuck on an old version)

**Symptom:** **`EPICCLIENT-Report.ps1`** shows a mix of versions; some devices never moved to
`<EPIC_VERSION>`.

1. **Device not in the assigned ring.** Confirm the device is a member of `Epic Hyperdrive – Pilot
   Ring` / `Epic Hyperdrive – Broad Ring` (whichever the new app is assigned to). Add it if missing
   (or run **`EPICCLIENT-Set-DeploymentRings.ps1`**).
2. **Superseding app not assigned.** Supersedence only acts where the **new** app is assigned — see
   Section E.
3. **Device not syncing.** Force a sync (**Access work or school → Sync**) or run
   **`EPICCLIENT-Remediation.ps1 … -Apply`**.
4. **Stale install failure** on those devices — drill into **Device install status** for the error and
   apply Section A.

## D. Hyperdrive won't launch (blank/white window, crash) — WebView2

**Symptom:** Hyperdrive installs but shows a blank/white window, fails to render, or crashes at launch.

1. **WebView2 runtime missing.** This is the most common cause. Run **`EPICCLIENT-Validation.ps1`**;
   if **WebView2 runtime present = FAIL**, deploy/repair the **Evergreen WebView2 Runtime** and set it
   as a **dependency** (auto-install = Yes) of the Hyperdrive app (Requirements §R5, Implementation
   Step 6).
2. **WebView2 present but broken.** Repair/reinstall the WebView2 runtime app via Intune, then relaunch.
3. **Wrong Epic environment / config.** If it launches but connects to the wrong environment, the
   client configuration is off — confirm the environment/connection values with your Epic build team
   (out of scope for packaging, but a common "looks broken" report).
4. **Hyperspace, not Hyperdrive.** If you are deploying legacy **Hyperspace**, WebView2 is N/A — don't
   chase a WebView2 fix for a Hyperspace launch issue.

## E. Supersedence not upgrading (old version stays)

**Symptom:** You created a new app and a supersedence relationship, but devices keep the old version.

1. **New app not assigned to the devices.** Supersedence requires the **new** app to be **assigned**
   (Required) to the ring (Implementation Step 15.5). Assign `Epic Hyperdrive – <EPIC_VERSION_NEW>` to
   the pilot ring first, then broad.
2. **"Uninstall previous version" not set.** On the new app → **Supersedence**, confirm the relationship
   to `Epic Hyperdrive – <EPIC_VERSION>` has **Uninstall previous version = Yes** for a clean replace.
3. **Old app's detection still satisfied / old app still required.** If the **old** app is still
   assigned **Required** to the same devices, the two assignments fight. Remove the old app's Required
   assignment once supersedence is in place.
4. **Not synced yet.** Allow time and force a sync; supersedence evaluation isn't instant.
5. **Detection on the new app wrong.** If the new app's version-pinned detection is wrong, Intune
   thinks the upgrade failed — re-check per Section B.

## F. Retire leftovers (old client remains after retire)

**Symptom:** After retiring a version (Implementation Step 16), the old client is still present.

1. **Uninstall command wrong.** The app's **Program → Uninstall command** (`<EPIC_UNINSTALL_CMD>`) must
   silently remove the client. Test it by hand on the test device; correct it with your Epic build
   team's switches.
2. **Uninstall assignment missing the device.** Confirm you added the device's group to the app's
   **Uninstall** assignment, and removed any **Required** assignment that would reinstall it.
3. **Verify and finish.** Run **`EPICCLIENT-Discovery.ps1`** / **`EPICCLIENT-Validation.ps1`**; only
   delete the old Win32 app after devices report the uninstall (keep the prior `.intunewin` for
   rollback per Requirements §R10).

## G. Ring / assignment problems

**Symptom:** The wrong devices got the app, or a ring is mixed/stuck.

1. **Group membership.** Confirm `EPIC – Clinical Workstations`, `Epic Hyperdrive – Pilot Ring`, and
   `Epic Hyperdrive – Broad Ring` contain the intended **devices** (these are device groups). Fix
   membership in Entra or via **`EPICCLIENT-Set-DeploymentRings.ps1`**.
2. **Assigned too broadly too soon.** If broad got it before pilot was validated, remove the broad
   **Required** assignment, re-validate pilot, then re-add broad in the change window.
3. **Overlapping/contradictory assignments.** Avoid assigning both **Required** and **Uninstall** for
   the same app to overlapping groups — they conflict. Keep one intent per group.
4. **Co-management authority.** If devices are co-managed and the **Client apps** workload points at
   ConfigMgr, Intune app assignments won't apply — set the workload authority correctly
   (Requirements §R6).

## H. Imprivata badge-tap no longer launches Epic after a client change

**Symptom:** Tap-to-launch / SSO into Epic stopped working after deploying/upgrading the client.

1. **Confirm Imprivata agent health** on the device (service running). Imprivata configuration is a
   **separate solution** — this solution only validates the tap.
2. **Launch target changed.** A new client version can change the launch executable/path Imprivata
   targets; engage your Imprivata administrators / the Imprivata solution to update the profile.
3. **Re-test** with Testing §6 once corrected. If you don't use Imprivata, this is N/A.

---

## Escalation / rollback
If a failure affects **patient-care** devices and a quick fix isn't in hand, **invoke the rollback
plan** (Requirements §R10): re-assign the previously validated package/version (or remove the new
assignment), confirm with **`EPICCLIENT-Validation.ps1`**, and record the back-out in the clinical
change log. For Epic-installer behavior beyond packaging (switches, version strings, environment
config), escalate to your **Epic build team / Epic Technical Services**.
