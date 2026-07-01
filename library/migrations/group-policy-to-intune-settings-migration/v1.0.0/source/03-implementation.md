# 3. Implementation Guide — Group Policy to Intune Settings Migration

Follow these steps **in order**. GPO export is done in the **Group Policy Management Console (GPMC)**
on a domain-joined admin workstation; everything else is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). Reuse the object names from the Requirements naming convention
**exactly**.

> **Model:** Export and measure first, translate the supported settings, handle the unsupported ones
> deliberately, set who-wins precedence, then cut over by rings behind a parity gate. The repeatable
> way: **Assess → Configure → Pilot → Validate → Expand.**

## Step 1 — Create the migration ring groups
1. Entra → **Groups → New group** → **Security** → name `GPO Migration – Devices – Pilot Ring` (a
   few representative hybrid devices). **Create**.
2. Create `GPO Migration – Devices – Broad Ring` (the rest of the in-scope fleet). **Create**.
3. Or run **`GPOM-Set-MigrationRingTargeting.ps1`** to build both groups and seed pilot membership.

## Step 2 — Export and inventory the GPOs (Assess)
1. Open **GPMC** on a domain-joined admin workstation.
2. Right-click the **domain → Back Up All** (or right-click a single GPO → **Back Up**), choose a
   folder, and complete the wizard — this writes the GPO **backup/export** Group Policy analytics
   needs.
3. Alternatively, run **`GPOM-Discovery.ps1`**, which uses the **GroupPolicy** module
   (`Get-GPO` / `Get-GPOReport`) to export every GPO to **XML** and produce an inventory you can
   review and retain as your rollback source.

## Step 3 — Run Group Policy analytics (read the readiness %)
1. Intune → **Reports → Group Policy analytics → Import**.
2. Upload the GPO backup/export from Step 2. Repeat per GPO if you exported individually.
3. Read the **migration readiness percentage** for each imported GPO, and open it to see the
   per-setting mapping: **Supported / mapped**, **Not supported / deprecated**, or **Needs review**.
4. Note which GPOs are high-readiness (migrate first) and which carry many unsupported settings
   (plan handling in Step 6).

## Step 4 — Translate supported settings to the settings catalog
1. In **Group Policy analytics**, select the imported GPO(s) → **Migrate** (this generates a
   **settings catalog** policy from the **supported, mapped** settings).
2. Review the generated policy, then **Name** it `GPO Migration – Settings Catalog – Pilot`.
3. Verify each migrated setting matches the GPO's value; remove anything you do not want to migrate
   yet.
4. **Assignments → Add groups →** `GPO Migration – Devices – Pilot Ring`. **Create**.
   (You can also build a settings catalog policy by hand: **Devices → Manage devices → Configuration
   → Create → New policy → Windows 10 and later → Settings catalog**.)

## Step 5 — Import ADMX for administrative-template settings
1. For ADMX-backed settings not in the in-box catalog (e.g. Office, Edge, Chrome): Intune →
   **Devices → Manage devices → Configuration → Import ADMX**.
2. **Import** the vendor's `.admx` and `.adml` files; wait for status **Available**.
3. **Create → New policy → Windows 10 and later → Imported Administrative templates**, name it
   `GPO Migration – Imported ADMX – Pilot`, configure the settings to match the source GPO.
4. **Assignments → Add groups →** `GPO Migration – Devices – Pilot Ring`. **Create**.

## Step 6 — Handle the unsupported settings (deliberately)
For each setting Group Policy analytics flagged **Not supported / Needs review**, decide and
document one of:
1. **Re-implement** via a different Intune surface — endpoint security profile, **proactive
   remediation** (detect/remediate script), or a **platform script** (Devices → Scripts) for things
   like logon scripts or drive maps.
2. **Replace** with the modern equivalent (e.g. Group Policy Preferences drive maps → a deployment
   or remediation; mapped-printer GPP → Universal Print / printer policy).
3. **Retire** — the setting is obsolete and is intentionally not migrated (record the decision).
Capture every decision; **`GPOM-Report.ps1`** produces the coverage + gap report that lists exactly
these items.

## Step 7 — Set coexistence and precedence (MDMWinsOverGP)
1. **Devices → Manage devices → Configuration → Create → New policy → Windows 10 and later →
   Settings catalog**.
2. Search for **MDM Wins Over GP** (the `ControlPolicyConflict` / "MDM wins over GP" setting) and
   set it so **MDM wins**.
3. Name the policy `GPO Migration – MDM Wins Over GP – All Migrated`.
4. **Assignments → Add groups →** `GPO Migration – Devices – Pilot Ring` (extend to the broad ring
   at Step 9). **Create**.
5. As each setting area is migrated, **scope the legacy GPO away** from migrated devices (security
   filter / unlink for that OU) so there is one authority per setting.

## Step 8 — Validate parity on the pilot (Pilot/Validate)
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Run **`GPOM-Validation.ps1`** → compares the source GPO settings against the applied Intune
   policy and confirms `MDMWinsOverGP` is in effect.
3. Run **`GPOM-Report.ps1`** → confirms migration coverage and lists any remaining gaps.
4. Complete the **Testing Guide**. Do not expand until the parity gate passes.

## Step 9 — Expand to the broad ring (Expand)
1. Copy the validated catalog/ADMX policies to broad scope: create
   `GPO Migration – Settings Catalog – Broad` from the pilot policy (or extend its assignment), and
   add `GPO Migration – Devices – Broad Ring` to the coexistence policy assignment.
2. Move devices into `GPO Migration – Devices – Broad Ring` in waves; re-validate each wave with
   **`GPOM-Validation.ps1`** / **`GPOM-Report.ps1`**.
3. Only after the broad ring passes parity, **scope the legacy GPOs away** from the migrated fleet
   (leave them present-but-unlinked for rollback until you are confident).

---
### Order of operations
`Ring groups → Export + inventory GPOs → Group Policy analytics (readiness %) → Settings catalog →
Imported ADMX → Handle unsupported → MDMWinsOverGP coexistence → Validate parity (pilot) → Expand`
