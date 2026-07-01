# 3. Implementation Guide (net-new) — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
This builds the DISA STIG baseline by CAT severity as Intune policy, proves it on a pilot, then
expands fleet-wide.

> Model: Assess → Configure → Pilot → Validate → Expand. A small `STIG Win10/11 – Pilot Devices`
> group validates the hardening before the `STIG Win10/11 – Production Devices` fleet receives it.
> Hardening can break mission apps — do not skip the pilot gate or the rollback note (Step 10).

> Source note: The authoritative rule list, CAT severities, values, and check/fix text come from the
> current DISA Windows 10/11 STIG and its SCAP content, read in the STIG Viewer (Requirement 2.4).
> Rule names shown below are clearly marked examples; configure the actual rules and values from the
> STIG you obtained.

## Step 1 — Stage the STIG (Assess)
1. Open the current DISA Windows 10 and/or Windows 11 STIG in the STIG Viewer and confirm its release (for example `vYYYY.MM`).
2. Decide scope by severity: CAT I and CAT II fleet-wide, CAT III where practical.
3. From the STIG, list any rules that have no settings-catalog equivalent (these become the imported-ADMX policy in Step 6) and any rules you expect to carry as POA&M exceptions (Step 7).
4. Record the release you are targeting as your tag: `STIG-Win-vYYYY.MM`.

## Step 2 — Create the device groups
1. Entra → Groups → New group → Security → name `STIG Win10/11 – Pilot Devices` → add a few representative devices. Create.
2. Create `STIG Win10/11 – Production Devices` for the rest of the fleet. Create.

## Step 3 — Build the CAT I settings-catalog policy
1. Intune → Devices → Manage devices → Configuration → Create → New Policy.
2. Platform: Windows 10 and later. Profile type: Settings catalog. Create.
3. Name: `STIG Win10/11 – CAT I – Pilot`. Description: include the version tag `STIG-Win-vYYYY.MM`. Next.
4. Click Add settings. In the settings picker, search for each CAT I STIG rule and add it, then set the value to the STIG's required value. Work through the STIG's rules in order. Illustrative examples only — use the actual STIG rule values from the STIG Viewer:
   - Account Policies → password/lockout settings (example: minimum password length).
   - Microsoft Defender Antivirus settings (example: real-time protection enabled).
   - Local Policies / Security Options (example: interactive logon legal notice banner).
   *(Use the STIG Viewer check/fix text to confirm each setting maps to the right catalog entry.)*
5. Next → Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Next → Create.

## Step 4 — Build the CAT II settings-catalog policy
1. Repeat Step 3 with Name: `STIG Win10/11 – CAT II – Pilot`, adding only the CAT II rules.
2. Description: version tag `STIG-Win-vYYYY.MM` and "CAT II".
3. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 5 — (Optional) Build the CAT III settings-catalog policy
1. Repeat Step 3 with Name: `STIG Win10/11 – CAT III – Pilot`, adding the CAT III rules you choose to deploy.
2. Description: version tag `STIG-Win-vYYYY.MM` and "CAT III".
3. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 6 — Import ADMX and build the administrative-template policy (only if needed)
1. For any STIG rule with no settings-catalog equivalent (from Step 1.3): Intune → Devices → Manage devices → Configuration → Import ADMX → Import, upload the matching `.admx` and its `.adml` language file. Wait until status shows Available.
2. Configuration → Create → New Policy → Windows 10 and later → Templates → Imported Administrative templates → Create.
3. Name: `STIG Win10/11 – ADMX – Pilot`. Description: version tag. Configure the required template settings to the STIG values.
4. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 7 — Record POA&M exceptions
1. For each rule you cannot meet (it would break a mission app, the hardware lacks a feature, an operational constraint), record a POA&M item in your register: Rule/Vuln ID, CAT, risk, compensating control, owner, remediation milestone/date.
2. Implement the exception by omitting that setting from the policy, or by creating a narrowly scoped exception group and assigning a relaxed policy to it — never silently leave a rule undocumented.

## Step 8 — Create the compliance policy
1. Intune → Devices → Manage devices → Compliance → Create policy → Windows 10 and later → Create.
2. Name: `STIG Win10/11 – Compliance`. Set the compliance rules that represent your STIG posture (for example: minimum OS build, BitLocker required, Defender on, Secure Boot — use the STIG-relevant rules available in compliance).
3. Actions for noncompliance: mark noncompliant after a grace period; optionally email the user.
4. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 9 — Apply and validate on the pilot
1. On a pilot device, sync policy: Settings → Accounts → Access work or school → Info → Sync.
2. In Intune, open `STIG Win10/11 – CAT I – Pilot` → Device status / Per-setting status and confirm Succeeded (repeat for CAT II/III and ADMX policies).
3. On the device run `STIG-Validation.ps1` (per-device STIG-compliance check) and `STIG-Report.ps1` for fleet/pilot posture and drift. Reconcile against a STIG Viewer / SCAP scan of the pilot device.
4. Soak the pilot: have pilot users run their real mission apps for several business days. Watch for breakage (sign-in, line-of-business apps, printing, removable media, scripting). Complete the Testing Guide (document 5).

## Step 10 — Pilot gate and rollback note
1. Gate: do not expand until the pilot passes the Testing Guide gate AND no unresolved app breakage remains, and open CAT I/II findings are either fixed or carried as approved POA&Ms.
2. Rollback (if hardening breaks something): in Intune, remove the assignment of the offending policy from the affected group (or set the specific setting to Not configured), then sync. Removing the assignment is the fastest safe rollback; the device reverts on the next policy cycle. Record the rollback and the offending rule as a POA&M exception (Step 7).

## Step 11 — Expand to production
1. Duplicate each piloted policy (Intune → policy → Duplicate) and rename the copies `STIG Win10/11 – CAT I – Production`, `STIG Win10/11 – CAT II – Production`, `STIG Win10/11 – CAT III – Production`, `STIG Win10/11 – ADMX – Production`. Keep the version tag in the description.
2. Reassign the production copies to `STIG Win10/11 – Production Devices` (or add that group to the existing policies if you prefer a single policy set). Assign `STIG Win10/11 – Compliance` to production too.
3. Roll out in waves if the fleet is large; re-run `STIG-Report.ps1` after each wave to confirm posture and catch drift.

---
### Order of operations
`Stage STIG → Groups → CAT I catalog → CAT II catalog → (CAT III catalog) → Import ADMX → POA&M exceptions → Compliance → Apply + Validate → Pilot gate / rollback → Expand`
