# 3. Implementation Guide (net-new) — CIS Benchmarks for Windows 11 (Microsoft Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This builds the CIS Level 1 baseline (and optional Level 2) as
Intune policy, proves it on a pilot, then expands fleet-wide.

> **Model:** Assess → Configure → Pilot → Validate → Expand. A small `CIS Win11 – Pilot Devices`
> group validates the hardening before the `CIS Win11 – Production Devices` fleet receives it.
> **Hardening can break business apps — do not skip the pilot gate or the rollback note (Step 9).**

> **Source note:** The authoritative control list, levels, and values come from the current CIS
> Windows 11 Benchmark and its Build Kit (Requirement 2.4). Control names shown below are clearly
> marked examples; configure the actual controls and values from the benchmark you obtained.

## Step 1 — Stage the benchmark (Assess)
1. Open the current CIS Windows 11 Benchmark you obtained and confirm its version (for example `vX.Y.Z`).
2. Decide scope: **Level 1 for all devices**, and **Level 2 for the high-security subset** (if any).
3. From the benchmark, list any controls that have **no settings-catalog equivalent** (these become the imported-ADMX policy in Step 5) and any planned **break-glass exceptions** (Step 6).
4. Record the version you are targeting as your tag: `CIS-Win11-vX.Y.Z`.

## Step 2 — Create the device groups
1. Entra → **Groups → New group → Security →** name `CIS Win11 – Pilot Devices` → add a few representative devices. **Create**.
2. Create `CIS Win11 – Production Devices` for the rest of the fleet. **Create**.

## Step 3 — Build the Level 1 settings-catalog policy
1. Intune → **Devices → Manage devices → Configuration → Create → New Policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. **Create**.
3. **Name:** `CIS Win11 – L1 – Pilot`. **Description:** include the version tag `CIS-Win11-vX.Y.Z`. **Next**.
4. Click **Add settings**. In the settings picker, search for each CIS Level 1 control and add it, then set the value to the benchmark's recommended value. Work through the benchmark sections in order. *Illustrative examples only — use the actual benchmark values:*
   - Account Policies → password/lockout settings (example: minimum password length).
   - Microsoft Defender Antivirus settings (example: real-time protection enabled).
   - Local Policies / User Rights / Security Options (example: interactive logon banner).
   *(If you have the CIS Build Kit, use it to confirm each setting maps to the right catalog entry.)*
5. **Next → Assignments → Add groups →** `CIS Win11 – Pilot Devices`. **Next → Create**.

## Step 4 — (Optional) Build the Level 2 settings-catalog policy
1. Repeat Step 3 with **Name:** `CIS Win11 – L2 – Pilot`, adding only the **Level 2** controls (L2 sits on top of L1).
2. **Description:** version tag `CIS-Win11-vX.Y.Z` and "Level 2 — high-security subset only".
3. **Assignments → Add groups →** `CIS Win11 – Pilot Devices` (only if your pilot includes an L2 device). **Create**.

## Step 5 — Import ADMX and build the administrative-template policy (only if needed)
1. For any CIS control with no settings-catalog equivalent (from Step 1.3): Intune → **Devices → Manage devices → Configuration → Import ADMX → Import**, upload the matching `.admx` and its `.adml` language file. Wait until status shows **Available**.
2. **Configuration → Create → New Policy → Windows 10 and later → Templates → Imported Administrative templates → Create**.
3. **Name:** `CIS Win11 – ADMX – Pilot`. **Description:** version tag. Configure the required template settings to the benchmark values.
4. **Assignments → Add groups →** `CIS Win11 – Pilot Devices`. **Create**.

## Step 6 — Handle break-glass exceptions
1. For each planned exception (a control that would break a business app), document it in your change record: control, why, compensating control, owner, review date.
2. Implement the exception by **omitting that setting** from the policy, or by creating a narrowly scoped exception group and assigning a relaxed policy to it — never silently leave it undocumented.

## Step 7 — Create the compliance policy
1. Intune → **Devices → Manage devices → Compliance → Create policy → Windows 10 and later → Create**.
2. **Name:** `CIS Win11 – Compliance`. Set the compliance rules that represent your CIS posture (for example: minimum OS build, BitLocker required, Defender on — use the benchmark-relevant rules available in compliance).
3. **Actions for noncompliance:** mark noncompliant after a grace period; optionally email the user.
4. **Assignments → Add groups →** `CIS Win11 – Pilot Devices`. **Create**.

## Step 8 — Apply and validate on the pilot
1. On a pilot device, sync policy: **Settings → Accounts → Access work or school → Info → Sync**.
2. In Intune, open `CIS Win11 – L1 – Pilot` → **Device status / Per-setting status** and confirm **Succeeded**.
3. On the device run `CIS11-Validation.ps1` (per-device CIS-compliance check) and `CIS11-Report.ps1` for fleet/pilot posture and drift.
4. **Soak the pilot:** have pilot users run their real apps for several business days. Watch for breakage (sign-in, line-of-business apps, printing, removable media, scripting). Complete the **Testing Guide** (document 5).

## Step 9 — Pilot gate and rollback note
1. **Gate:** do not expand until the pilot passes the Testing Guide gate AND no unresolved app breakage remains.
2. **Rollback (if hardening breaks something):** in Intune, **remove the assignment** of the offending policy from the affected group (or set the specific setting to *Not configured*), then sync. Removing the assignment is the fastest safe rollback; the device reverts on the next policy cycle. Record the rollback and the offending control as a break-glass exception (Step 6).

## Step 10 — Expand to production
1. Duplicate each piloted policy (Intune → policy → **Duplicate**) and rename the copies `CIS Win11 – L1 – Production`, `CIS Win11 – L2 – Production`, `CIS Win11 – ADMX – Production`. Keep the version tag in the description.
2. Reassign the production copies to `CIS Win11 – Production Devices` (or simply add that group to the existing policies if you prefer a single policy set). Assign `CIS Win11 – Compliance` to production too.
3. Roll out in waves if the fleet is large; re-run `CIS11-Report.ps1` after each wave to confirm posture and catch drift.

---
### Order of operations
`Stage benchmark → Groups → L1 catalog policy → (L2 catalog) → Import ADMX → Exceptions → Compliance → Apply + Validate → Pilot gate / rollback → Expand`
