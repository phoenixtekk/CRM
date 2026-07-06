# 3. Implementation Guide — macOS Endpoint Management Baseline (Microsoft Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This builds the named baseline — configuration profile, restrictions
policy, compliance policy, and macOS software-update policy — primarily in the **settings catalog**
(with a custom `.mobileconfig` only where the catalog cannot reach a payload), proves it on a pilot,
then expands fleet-wide.

> **Model:** Assess → Configure → Pilot → Validate → Expand. A small `macOS Baseline – Pilot Devices`
> group validates the baseline before the `macOS Baseline – Production Devices` fleet receives it.
> **Do not skip the pilot gate or the rollback note (Step 10).**

> **Naming:** Create every object with the **exact** name shown and reuse it verbatim in the Testing
> and Troubleshooting guides and in the scripts. Put the tag `macOS-Baseline-v1.0` in every
> description.

## Step 1 — Stage the baseline decisions (Assess)
1. Confirm the agreed baseline values from Requirement 2.7: the **restrictions** to apply, the
   **software-update** behaviour (auto-download/install, minimum OS version, deadline), and the
   **compliance** thresholds (minimum OS version, FileVault required, firewall required).
2. Sort each agreed setting into a surface: **settings catalog** (nearly all — Steps 5–8), or
   **custom `.mobileconfig`** (only settings with no catalog payload — Step 9).
3. Record `macOS-Baseline-v1.0` as the tag you will place in each policy description.

## Step 2 — Confirm Apple management prerequisites
1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm present and **not
   expired** (Requirement 2.3).
2. Confirm the target Macs are enrolled: Intune → **Devices → macOS → macOS devices** (Requirement
   2.4). Optionally run `MACBASE-Discovery.ps1` for a readiness snapshot.

## Step 3 — Create the device groups
1. Entra (`https://entra.microsoft.com`) → **Groups → New group → Group type: Security →** name
   `macOS Baseline – Pilot Devices` → add a few representative Macs. **Create**.
2. Create `macOS Baseline – Production Devices` for the rest of the fleet (a dynamic device group is
   convenient here — see Requirement 2.6). **Create**.

## Step 4 — Baseline the tenant before you build (recommended)
1. Run `MACBASE-Discovery.ps1` to list any **existing** macOS configuration policies, custom profiles,
   compliance policies, and update policies. Note anything already targeting the same area so you do
   not create a **conflicting** second authority for the same setting (a leading cause of "Error /
   Conflict" status later).

## Step 5 — Build the baseline configuration profile (settings catalog)
1. Intune → **Devices → macOS → Configuration → Create → New Policy**.
2. **Platform:** macOS. **Profile type:** **Settings catalog**. **Create**.
3. **Name:** `macOS Baseline – Config – Pilot`. **Description:** include the tag `macOS-Baseline-v1.0`.
   **Next**.
4. Click **Add settings**. In the settings picker, search for and add the core baseline payloads, then
   set each to the agreed value. Typical baseline areas (configure the actual values you agreed in
   Step 1):
   - **Login Window** — e.g. disable automatic login; show name/password fields (not a user list).
   - **Security** — e.g. require a password after sleep or screen saver begins, and set the grace
     period; enable FileVault prompting (if you enforce encryption here rather than in a dedicated
     encryption profile).
   - **Screen Saver / Password** — idle time before the screen saver, and password required to wake.
   - **Privacy Preferences (PPPC)** — pre-approve management/security agents where needed (author from
     Apple's public payload documentation if you have such agents).
5. **Next → Scope tags** (optional) **→ Next → Assignments → Add groups →**
   `macOS Baseline – Pilot Devices`. **Next → Review + create → Create**.

## Step 6 — Build the restrictions policy (settings catalog)
1. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Profile type:
   Settings catalog → Create**.
2. **Name:** `macOS Baseline – Restrictions – Pilot`. **Description:** tag `macOS-Baseline-v1.0`.
   **Next**.
3. **Add settings →** search the **Restrictions** category and add the agreed toggles, for example:
   - AirDrop (allow/deny), content caching (allow/deny), iCloud document/desktop sync, Game Center,
     media sharing, and similar feature restrictions per your agreed baseline.
4. **Assignments → Add groups →** `macOS Baseline – Pilot Devices`. **Review + create → Create**.

> Keeping restrictions in their **own** policy (separate from Step 5) lets you assign, adjust, or roll
> back restrictions independently of the broader configuration — recommended.

## Step 7 — Build the macOS software-update policy (settings catalog)
1. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Profile type:
   Settings catalog → Create**.
2. **Name:** `macOS Baseline – Software Update – Pilot`. **Description:** tag `macOS-Baseline-v1.0`.
   **Next**.
3. **Add settings →** search **Software Update** and add the agreed update controls, for example:
   - Automatically **download** and **install** macOS and app/security updates.
   - Enforce a **minimum OS version** and (where available) a **deadline / enforcement** so updates are
     not deferred indefinitely.
   *(On modern macOS, Intune may present Declarative Device Management update-enforcement settings.
   Availability is version-dependent — use the options Intune shows for your macOS releases; see the
   Overview version note.)*
4. **Assignments → Add groups →** `macOS Baseline – Pilot Devices`. **Review + create → Create**.

## Step 8 — Create the compliance policy
1. Intune → **Devices → macOS → Compliance → Create policy → Platform: macOS → Create**.
2. **Name:** `macOS Baseline – Compliance`. **Description:** tag `macOS-Baseline-v1.0`. **Next**.
3. Set the agreed compliance rules, for example: **minimum OS version**, **FileVault** required,
   **firewall** required, and system integrity where available.
4. **Actions for noncompliance:** mark noncompliant after a short grace period; optionally email the
   user. **Next**.
5. **Assignments → Add groups →** `macOS Baseline – Pilot Devices`. **Review + create → Create**.

## Step 9 — Add a custom `.mobileconfig` profile (only if needed)
1. For any agreed setting with **no** settings-catalog payload (from Step 1.2), obtain or author the
   matching `.mobileconfig` file (Requirement 2.8).
2. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Profile type:
   Templates → Custom → Create**.
3. **Name:** `macOS Baseline – Custom – Pilot`. **Description:** tag `macOS-Baseline-v1.0`. Provide a
   deployment channel and **upload** the `.mobileconfig` configuration profile file. **Next**.
4. **Assignments → Add groups →** `macOS Baseline – Pilot Devices`. **Review + create → Create**.

## Step 10 — Apply and validate on the pilot, with pilot gate and rollback note
1. On a pilot Mac, force a sync: **Company Portal → ⋯ → Check status** (or **System Settings → Privacy
   & Security → Profiles**, then let it refresh).
2. In Intune, open each pilot policy → **Device status** / **Per setting status** and confirm
   **Succeeded** with no conflicts. Check the compliance policy's **Device status** too.
3. On the Mac (or from an admin workstation) run `MACBASE-Validation.ps1` (per-device applied-state
   check) and `MACBASE-Report.ps1` (fleet/pilot posture and drift).
4. **Soak the pilot:** have pilot users run their real apps for several business days. Watch for
   anything the baseline changed unexpectedly (login window behaviour, screen-saver/password prompts,
   a restriction blocking a legitimate workflow, an update deadline interrupting work). Complete the
   **Testing Guide** (document 5).
5. **Gate:** do not expand until the pilot passes the Testing Guide gate AND no unresolved workflow
   breakage remains.
6. **Rollback (if a setting causes a problem):** in Intune, **remove the assignment** of the offending
   policy from the pilot group (or set the specific setting to **Not configured**), then sync. Removing
   the assignment is the fastest safe rollback; the Mac reverts on the next policy cycle. Record the
   change and the offending setting in your change record.

## Step 11 — Expand to production
1. Duplicate each piloted policy (Intune → policy → **Duplicate**) and rename the copies
   `macOS Baseline – Config – Production`, `macOS Baseline – Restrictions – Production`,
   `macOS Baseline – Software Update – Production`, and (if used)
   `macOS Baseline – Custom – Production`. Keep the tag `macOS-Baseline-v1.0` in each description.
2. Reassign the production copies to `macOS Baseline – Production Devices`. Assign
   `macOS Baseline – Compliance` to production too (add the production group to the existing compliance
   policy).
3. Roll out in **waves** if the fleet is large; re-run `MACBASE-Report.ps1` after each wave to confirm
   posture and catch drift. Optionally run `MACBASE-Set-ScopeTargeting.ps1` to add/stage group
   assignments the repeatable way (defaults to `-WhatIf`).

---
### Order of operations
`Confirm APNs/enrollment → Groups → Baseline the tenant → Config profile → Restrictions → Software Update → Compliance → (Custom .mobileconfig) → Apply + Validate (pilot gate / rollback) → Expand`
