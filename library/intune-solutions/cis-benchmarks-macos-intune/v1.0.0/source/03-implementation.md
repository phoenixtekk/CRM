# 3. Implementation Guide (net-new) — CIS Benchmarks for macOS (Microsoft Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This builds the CIS Level 1 baseline (and optional Level 2) across
the three macOS surfaces — settings catalog, custom `.mobileconfig` profiles, and shell scripts —
proves it on a pilot, then expands fleet-wide.

> **Model:** Assess → Configure → Pilot → Validate → Expand. A small `CIS macOS – Pilot Devices`
> group validates the hardening before the `CIS macOS – Production Devices` fleet receives it.
> **Hardening can break apps and even sign-in — do not skip the pilot gate or the rollback note (Step 10).**

> **Source note:** The authoritative control list, levels, payload keys, and values come from the
> current CIS macOS Benchmark (Requirement 2.5). Control names shown below are clearly marked
> examples; configure the actual controls and values from the benchmark you obtained.

## Step 1 — Stage the benchmark (Assess)
1. Open the current CIS macOS Benchmark you obtained and confirm its version (for example `vX.Y.Z`) and the macOS release it targets.
2. Decide scope: **Level 1 for all devices**, and **Level 2 for the high-security subset** (if any).
3. From the benchmark, sort each control into one of the three Intune surfaces: **settings catalog** (most controls, Step 4), **custom `.mobileconfig`** (controls with no catalog payload, Step 6), and **shell script** (controls only enforceable by a command, Step 7). List any planned **break-glass exceptions** (Step 8).
4. Record the version you are targeting as your tag: `CIS-macOS-vX.Y.Z`.

## Step 2 — Confirm Apple management prerequisites
1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm present and not expired (Requirement 2.2).
2. Confirm your target Macs are enrolled: Intune → **Devices → macOS → macOS devices** (Requirement 2.3).

## Step 3 — Create the device groups
1. Entra → **Groups → New group → Security →** name `CIS macOS – Pilot Devices` → add a few representative Macs. **Create**.
2. Create `CIS macOS – Production Devices` for the rest of the fleet. **Create**.

## Step 4 — Build the Level 1 settings-catalog policy
1. Intune → **Devices → macOS → Configuration → Create → New Policy** (or **Manage devices → Configuration → Create**).
2. **Platform:** macOS. **Profile type:** **Settings catalog**. **Create**.
3. **Name:** `CIS macOS – L1 – Pilot`. **Description:** include the version tag `CIS-macOS-vX.Y.Z`. **Next**.
4. Click **Add settings**. In the settings picker, search for each CIS Level 1 control and add it, then set the value to the benchmark's recommended value. Work through the benchmark sections in order. *Illustrative examples only — use the actual benchmark values:*
   - Software Update payload (example: automatic security responses / install macOS updates enabled).
   - Security & Privacy / Login Window (example: require password after sleep or screen saver begins).
   - Restrictions (example: disable content caching, or restrict AirDrop — per the benchmark).
   *(Where the benchmark lists a control, confirm it maps to the matching Apple payload in the catalog.)*
5. **Next → Assignments → Add groups →** `CIS macOS – Pilot Devices`. **Next → Create**.

## Step 5 — (Optional) Build the Level 2 settings-catalog policy
1. Repeat Step 4 with **Name:** `CIS macOS – L2 – Pilot`, adding only the **Level 2** controls (L2 sits on top of L1).
2. **Description:** version tag `CIS-macOS-vX.Y.Z` and "Level 2 — high-security subset only".
3. **Assignments → Add groups →** `CIS macOS – Pilot Devices` (only if your pilot includes an L2 Mac). **Create**.

## Step 6 — Add custom `.mobileconfig` profiles (only if needed)
1. For any CIS control with no settings-catalog payload (from Step 1.3), obtain or author the matching `.mobileconfig` file (Requirement 2.6).
2. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Profile type: Templates → Custom → Create**.
3. **Name:** `CIS macOS – Custom – Pilot`. **Description:** version tag. Provide a deployment channel and upload the `.mobileconfig` configuration profile file.
4. **Assignments → Add groups →** `CIS macOS – Pilot Devices`. **Create**.

## Step 7 — Add macOS shell scripts (only for script-only controls)
1. For any CIS control enforceable only by a command (from Step 1.3): Intune → **Devices → macOS → Shell scripts → Add**.
2. **Name:** `CIS macOS – Shell – Pilot`. **Description:** version tag. Upload the shell script implementing the control (for example a `defaults write` / service-toggle command from the benchmark's remediation guidance).
3. **Script settings:** run as root = **Yes** (most CIS controls require it); set the run frequency so the control is re-enforced on a schedule (re-applying corrects user drift). **Next**.
4. **Assignments → Add groups →** `CIS macOS – Pilot Devices`. **Add → Next → Add**.

## Step 8 — Handle break-glass exceptions
1. For each planned exception (a control that would break an app, a workflow, or login), document it in your change record: control, why, compensating control, owner, review date.
2. Implement the exception by **omitting that setting** from the policy/profile/script, or by creating a narrowly scoped exception group and assigning a relaxed policy to it — never silently leave it undocumented.

## Step 9 — Create the compliance policy
1. Intune → **Devices → macOS → Compliance → Create policy → Platform: macOS → Create**.
2. **Name:** `CIS macOS – Compliance`. Set the compliance rules that represent your CIS posture (for example: minimum OS version, **FileVault** required, **firewall** required, system integrity — use the benchmark-relevant rules available in macOS compliance).
3. **Actions for noncompliance:** mark noncompliant after a grace period; optionally email the user.
4. **Assignments → Add groups →** `CIS macOS – Pilot Devices`. **Create**.

## Step 10 — Apply and validate on the pilot, with pilot gate and rollback note
1. On a pilot Mac, force a sync: **Company Portal → ... → Check status** (or **System Settings → Privacy & Security → Profiles**, then let it refresh).
2. In Intune, open `CIS macOS – L1 – Pilot` → **Device status / Per-setting status** and confirm **Succeeded**. Check the custom profile and shell script status too (**Devices → macOS → Shell scripts →** script **→ Device status**).
3. On the Mac run `CISMAC-Validation.ps1` (per-device CIS-compliance check) and `CISMAC-Report.ps1` for fleet/pilot posture and drift.
4. **Soak the pilot:** have pilot users run their real apps for several business days. Watch for breakage (sign-in/login window, app launch under Gatekeeper, firewall-blocked apps, printing, removable media, automation). Complete the **Testing Guide** (document 5).
5. **Gate:** do not expand until the pilot passes the Testing Guide gate AND no unresolved app/login breakage remains.
6. **Rollback (if hardening breaks something):** in Intune, **remove the assignment** of the offending profile/policy/script from the affected group (or set the specific setting to *Not configured*, or disable the shell script), then sync. Removing the assignment is the fastest safe rollback; the Mac reverts on the next policy cycle. Record the rollback and the offending control as a break-glass exception (Step 8).

## Step 11 — Expand to production
1. Duplicate each piloted policy (Intune → policy → **Duplicate** where available) and rename the copies `CIS macOS – L1 – Production`, `CIS macOS – L2 – Production`, `CIS macOS – Custom – Production`, `CIS macOS – Shell – Production`. Keep the version tag in the description. (For shell scripts, re-create with the production name and assignment.)
2. Reassign the production copies to `CIS macOS – Production Devices` (or simply add that group to the existing policies if you prefer a single policy set). Assign `CIS macOS – Compliance` to production too.
3. Roll out in waves if the fleet is large; re-run `CISMAC-Report.ps1` after each wave to confirm posture and catch drift.

---
### Order of operations
`Stage benchmark → Confirm APNs/enrollment → Groups → L1 catalog policy → (L2 catalog) → Custom .mobileconfig → Shell scripts → Exceptions → Compliance → Apply + Validate (pilot gate / rollback) → Expand`
