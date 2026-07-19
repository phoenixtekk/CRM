# Group Policy to Intune Settings Migration

> **Version 1.0.0** · Category: Migrations · Solution code: GPOM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Group Policy to Intune Settings Migration (Microsoft Intune)

**White-label · Intune Solutions**

Decades of Group Policy keep your domain-joined PCs in line — but those settings only apply on the
corporate network, they don't follow cloud-joined or remote devices, and nobody fully knows what is
actually in the GPO estate anymore. This solution gives you a **structured migration** from Active
Directory Group Policy to **Microsoft Intune**: inventory what you really have, translate supported
settings to the **Intune settings catalog** and **imported ADMX** policies, handle the settings
Intune can't take, manage **coexistence and precedence** so on-prem and cloud policy don't fight,
and cut over **by rings** — without losing a setting that mattered.

This is a complete, **deploy-it-today** package for migrating Group Policy to Intune, written for an
administrator with no prior migration experience.

## What you get
- A plain-language **Solution Overview** of how GPO and Intune policy differ, the settings catalog
  and imported ADMX model, the Group Policy analytics workflow, coexistence/precedence, and the
  ring-based cutover.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps in the required order — export GPOs,
  run Group Policy analytics, map supported settings, handle unsupported ones, set coexistence, and
  assign in rings.
- Five **PowerShell scripts** for GPO discovery/inventory, settings-parity validation, a migration
  coverage and gap report, safe conflict remediation, and a migration-ring group builder.
- **Testing** and **Troubleshooting** guides for a confident, parity-checked cutover.

## What this delivers
A **translated** Group Policy estate — not a guessed one. Group Policy analytics reads your exported
GPOs and reports a **migration readiness percentage**; supported settings become **settings catalog**
and **imported ADMX** policies named to a strict convention; unsupported settings are documented and
handled deliberately; and the on-prem-to-cloud cutover runs in **rings** behind a parity gate so a
mistake is caught on a pilot, never the fleet.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Your Group Policy settings preserved in Intune — coexistence managed during the move, conflicts
resolved by design, and a ringed cutover that follows devices on or off the corporate network —
proven on a pilot before you scale.


---


# 1. Solution Overview — Group Policy to Intune Settings Migration

## What this migration is
Group Policy (GPO) is the on-premises Active Directory mechanism that pushes configuration to
domain-joined Windows devices. It is powerful, but it only applies when a device can reach a domain
controller — so cloud-joined, remote, and hybrid devices fall out of scope. **Microsoft Intune**
delivers the equivalent configuration from the cloud, to any enrolled device, anywhere. This
solution is a **structured translation** of your GPO estate into Intune policy: inventory the GPOs,
measure how much is supported, recreate the supported settings in Intune, handle the rest
deliberately, and cut over by rings.

## How GPO and Intune policy differ (why this is a translation, not a copy)
- **GPO** is processed by the device against AD on the corporate network, on a refresh interval,
  using ADMX templates and security/preferences. **Intune** delivers policy over the internet to
  enrolled devices using the **settings catalog**, **imported ADMX (administrative templates)**,
  **endpoint security**, and **compliance** profiles.
- Most ADMX-backed GPO settings have a direct Intune equivalent; many **Group Policy Preferences**,
  logon/startup scripts, drive maps, and a few security settings **do not** translate one-for-one and
  must be re-implemented another way (or retired).
- Both can apply to the same device during migration. When they conflict, you must choose a winner —
  see **coexistence and precedence** below.

## The Group Policy analytics workflow
Intune includes **Group Policy analytics**, which reads an **exported GPO backup** and tells you,
per setting, whether it **maps** to an Intune setting (supported), is **deprecated/not supported**,
or **needs review**. It produces a **migration readiness percentage** for each imported GPO — the
honest measure of how much of that GPO you can move. The standard workflow is:
1. **Export** each GPO from the domain (GPMC backup → XML/reports).
2. **Import** the export into Group Policy analytics and read the **readiness %** and per-setting
   mapping.
3. **Migrate** the supported settings — analytics can generate **settings catalog** policies
   directly from the mapped settings, which you then review, name, and assign.
4. **Handle** the unsupported settings (re-implement, replace, or retire) and document the decision.

## What you create in Intune
- **Settings catalog** policies for supported, mapped settings (the modern, searchable surface).
- **Imported ADMX** policies for in-box and third-party administrative templates (e.g. Office,
  Edge, Chrome) so ADMX-only settings have a home.
- **Coexistence control** so on-prem GPO and Intune MDM policy don't fight during the move.
- **Migration ring groups** and ringed assignments for a safe, phased cutover.

## Coexistence and precedence during migration
While a device is both domain-joined and Intune-enrolled (hybrid), **both** policy sources apply. By
default, for most ADMX-backed settings, **Group Policy wins** over MDM. To let Intune take
authority cleanly as you migrate, enable the **MDMWinsOverGP** setting (the
`ControlPolicyConflict` / "MDM wins over GP" policy) so Intune's value wins where both set the same
setting. Migrate setting areas deliberately — turn the matching GPO setting off (or scope the GPO
away from migrated devices) as you bring each area into Intune — so there is exactly one authority
per setting at the end.

## The ring-based cutover
Devices move in **rings**: a small **Pilot** ring takes the new Intune policy first and is checked
for **parity** (does Intune now enforce what the GPO used to?). Only after the parity gate passes do
you **Expand** to the broad fleet, scoping the legacy GPO away from migrated devices as you go.

## Benefits
- **Cloud reach** — policy follows remote and cloud-joined devices, not just LAN-connected ones.
- **Visibility** — you finally know what is in the GPO estate and how much is supported.
- **Safety** — parity-checked, ringed cutover catches loss on a pilot, not the fleet.
- **One authority** — coexistence handled so on-prem and cloud policy stop fighting.

## Limitations (be honest with buyers)
- Not every GPO setting maps — **Group Policy Preferences**, logon scripts, drive maps, and some
  security settings need a different Intune approach (proactive remediations, platform scripts,
  endpoint security, or retirement).
- Group Policy analytics measures **readiness**, it does not flip the switch — you still review,
  name, assign, and validate each policy.
- Coexistence requires a deliberate precedence decision (MDMWinsOverGP) and per-area cutover to
  avoid double-authority drift.

## The standard deployment model
> **Export GPOs → run Group Policy analytics → translate supported settings → handle unsupported →
> set coexistence/precedence → assign in rings → validate parity → expand.** The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Group Policy to Intune Settings Migration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Microsoft Intune (Plan 1, included in M365 E3/E5 or Business Premium). Group Policy
analytics and the settings catalog are in-box Intune features.
**Why:** Intune delivers Group Policy analytics, the settings catalog, imported ADMX, and policy
assignment.
**Verify:** M365 admin center → **Billing → Licenses**; `https://intune.microsoft.com` loads.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Access to export Group Policy
**Description:** Rights and tooling to export/back up GPOs from the domain — the **Group Policy
Management Console (GPMC)** and/or the **GroupPolicy** PowerShell module on a domain-joined admin
workstation.
**Why:** Group Policy analytics needs a GPO **export/backup** as its input; you cannot measure
readiness without it.
**Verify:** Open GPMC; or run `Get-Module -ListAvailable GroupPolicy`. Run **`GPOM-Discovery.ps1`**
(exports all GPOs to XML).
**Implement:** Install **RSAT: Group Policy Management Tools** (`Add-WindowsCapability -Online -Name
Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0`); use an account with **GPO read** rights (e.g. Group
Policy Creator Owners or delegated read).

## 2.3 Device enrollment in Intune
**Description:** Targeted devices enrolled in Intune (cloud-joined or hybrid Entra-joined).
**Why:** Translated Intune policy applies only to enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears.
**Implement:** Enable automatic enrollment; for hybrid devices configure Entra Hybrid Join + Intune
auto-enrollment.

## 2.4 Group Policy analytics available
**Description:** Access to **Reports → Group Policy analytics** in the Intune admin center.
**Why:** This is where you import GPO backups, read the **migration readiness %**, and generate
settings catalog policies from mapped settings.
**Verify:** Intune → **Reports → Group Policy analytics** opens and accepts an import.
**Implement:** Assign an **Intune Administrator** (or **Policy and Profile Manager**) role to the
operator; no extra add-on is required.

## 2.5 Coexistence / precedence decision (MDMWinsOverGP)
**Description:** A decided answer to "during migration, when GPO and Intune set the same thing, who
wins?" — implemented via the **MDM wins over GP** (`ControlPolicyConflict`) setting.
**Why:** Hybrid devices receive both policy sources; without a precedence decision, GPO wins by
default and your migrated Intune settings appear not to apply.
**Verify:** Run **`GPOM-Validation.ps1`** (reports the current `MDMWinsOverGP` state) and
**`GPOM-Discovery.ps1`** (flags settings still owned by GPO).
**Implement:** Plan to deploy the coexistence policy in Implementation Step 5; scope legacy GPOs
away from migrated devices per area.

## 2.6 Migration ring groups
**Description:** Microsoft Entra security groups for the phased cutover — at minimum a pilot ring and
a broad ring.
**Why:** The cutover is ringed so loss is caught on a pilot before the fleet.
**Verify:** Entra → **Groups**; the migration ring groups exist. Run
**`GPOM-Set-MigrationRingTargeting.ps1`** to build them.
**Implement:** Create the groups in Implementation Step 1 (or with the ring-targeting script).

## 2.7 Rollback plan
**Description:** A documented way to back out — the original GPO exports retained, legacy GPOs left
**enabled but unscoped** (not deleted) until parity is proven, and a known-good restore path.
**Why:** Migration must be reversible until the parity gate passes for the broad ring.
**Verify:** Confirm GPO backups from **`GPOM-Discovery.ps1`** are retained and legacy GPOs are still
present (linked-but-scoped-away, not deleted).
**Implement:** Keep the export folder safe; do not delete or unlink source GPOs until the broad ring
passes Testing.

---
## Naming convention (use verbatim throughout)
All objects follow `<Purpose> – <Scope> – <Stage>`. The objects this solution creates:
| Object | Name |
|---|---|
| Settings catalog policy (supported, mapped settings) | `GPO Migration – Settings Catalog – Pilot` |
| Settings catalog policy (broad cutover copy) | `GPO Migration – Settings Catalog – Broad` |
| Imported ADMX policy (administrative templates) | `GPO Migration – Imported ADMX – Pilot` |
| Coexistence / precedence policy (MDMWinsOverGP) | `GPO Migration – MDM Wins Over GP – All Migrated` |
| Pilot ring group | `GPO Migration – Devices – Pilot Ring` |
| Broad ring group | `GPO Migration – Devices – Broad Ring` |

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Access + tooling to export GPOs — `GPOM-Discovery.ps1`
- [ ] Devices enrolled in Intune
- [ ] Group Policy analytics available (Reports → Group Policy analytics)
- [ ] Coexistence/precedence decision made (MDMWinsOverGP) — `GPOM-Validation.ps1`
- [ ] Migration ring groups created — `GPOM-Set-MigrationRingTargeting.ps1`
- [ ] Rollback plan: GPO exports retained, source GPOs not deleted


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — Group Policy to Intune Settings Migration

Run after the pilot policies apply (Implementation Step 8) and again for each broad-ring wave. The
goal of testing is **parity**: Intune now enforces what the GPO used to, on the right devices, with
Intune as the winning authority.

## Test 1 — Settings catalog policy applied
**Do:** Intune → **Devices → Manage devices → Configuration →** `GPO Migration – Settings Catalog –
Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Imported ADMX policy applied
**Do:** Open `GPO Migration – Imported ADMX – Pilot` → **Device status**; confirm the imported ADMX
shows **Available** under **Import ADMX**.
**Expected:** Pilot devices show **Succeeded**; the ADMX import status is **Available**.

## Test 3 — Settings parity (GPO vs Intune)
**Do:** On a pilot device run `GPOM-Validation.ps1` (compares source GPO settings to the applied
Intune values).
**Expected:** Each migrated setting reports **match**; no migrated setting is **missing** or
**different**.

## Test 4 — MDM wins over GP in effect
**Do:** Run `GPOM-Validation.ps1` (reports `MDMWinsOverGP`), or check
`HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict`.
**Expected:** `MDMWinsOverGP` is enabled — where both GPO and Intune set a value, the Intune value
wins.

## Test 5 — Migration coverage + gaps
**Do:** Run `GPOM-Report.ps1`.
**Expected:** A coverage figure close to the Group Policy analytics readiness %, and a gap list that
matches the unsupported settings you handled in Step 6 (nothing unexpected).

## Test 6 — No conflicting double-authority
**Do:** Run `GPOM-Discovery.ps1` on a migrated device (flags settings still owned by a live GPO).
**Expected:** For migrated areas, the legacy GPO is scoped away (no competing GPO value), or
`MDMWinsOverGP` cleanly resolves it.

## Test 7 — Cloud reach (off-network)
**Do:** Take a pilot device off the corporate network and sync; re-run `GPOM-Validation.ps1`.
**Expected:** The Intune settings still apply off-network (the original GPO would not have) —
confirming the cloud-reach benefit.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass; parity confirmed and `MDMWinsOverGP` in effect on the pilot ring |
| **Broad pass** | Tests 1, 3, 5, 6 pass for the broad ring before legacy GPOs are scoped away from the fleet |


---


# 6. Troubleshooting Guide — Group Policy to Intune Settings Migration

Use **`GPOM-Discovery.ps1`** for GPO inventory and conflicting-authority detection,
**`GPOM-Validation.ps1`** for settings parity and precedence state, **`GPOM-Report.ps1`** for
coverage/gaps, and **`GPOM-Remediation.ps1`** (`-WhatIf` first) for safe conflict resolution.

## A. Migrated settings don't apply (GPO still winning)
| Symptom | Cause | Remediation |
|---|---|---|
| Intune policy shows Succeeded but the device behaves per the old GPO | `MDMWinsOverGP` not set — GPO wins by default | Deploy `GPO Migration – MDM Wins Over GP – All Migrated` (Step 7); re-run `GPOM-Validation.ps1` |
| A migrated setting is still controlled by AD | Legacy GPO still scoped to the device | Scope/unlink the legacy GPO from migrated devices; `GPOM-Discovery.ps1` flags it |
| Mixed results across devices | Device not synced / not in the ring group | Sync the device; confirm membership in `GPO Migration – Devices – Pilot Ring` |

## B. Group Policy analytics import / readiness issues
| Symptom | Cause | Remediation |
|---|---|---|
| Import fails or shows nothing | Wrong export type (not a GPO backup) | Re-export with **GPMC → Back Up** or `GPOM-Discovery.ps1` (`Get-GPOReport`), then re-import |
| Readiness % lower than expected | GPO has many preferences/scripts/security settings | Expected — handle the unsupported settings in Step 6; `GPOM-Report.ps1` lists them |
| Setting shows "Needs review" | Analytics can't auto-map it | Review the source value and re-implement in the settings catalog or another surface |

## C. Unsupported settings (no direct Intune equivalent)
- **Group Policy Preferences** (drive maps, registry items, printers) → re-implement via a
  **platform script** (Devices → Scripts), a **proactive remediation**, Universal Print, or retire.
- **Logon/startup scripts** → replace with a platform script or proactive remediation.
- **Some security settings** → use an **endpoint security** profile or the security baseline instead
  of the settings catalog. Record every decision in the gap report.

## D. Settings catalog / imported ADMX problems
| Symptom | Cause | Remediation |
|---|---|---|
| ADMX setting can't be found in the catalog | Vendor ADMX not imported | **Import ADMX** (Step 5); wait for **Available**, then add the imported template policy |
| Policy error / conflict on device | Two Intune policies set the same setting differently | Consolidate; remove the duplicate; `GPOM-Validation.ps1` highlights the mismatch |
| Imported ADMX stuck "Uploading" | Mismatched/old `.admx`/`.adml` pair | Re-import a matching ADMX+ADML pair from the current vendor package |

## E. Coexistence drift (double authority)
- A setting owned by **both** GPO and Intune long-term causes flapping. Fix by enforcing one
  authority: keep `MDMWinsOverGP` on **and** scope the legacy GPO away for that area. Run
  `GPOM-Remediation.ps1 -WhatIf` to preview the precedence fix before applying.

## F. Diagnostics quick reference
```powershell
Get-GPO -All | Select-Object DisplayName, Id, GpoStatus          # GPO inventory (GroupPolicy module)
Get-GPOReport -Name 'Your GPO' -ReportType Xml -Path .\gpo.xml   # export a GPO for analytics
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict' -EA SilentlyContinue  # MDMWinsOverGP
gpresult /h gpresult.html                                        # what GPO is still applying on the device
```
MDM diagnostics: **Settings → Accounts → Access work or school → Info → Create report**, or
`mdmdiagnosticstool.exe -area DeviceEnrollment -cab C:\Temp\mdm.cab`.

## G. When to escalate
If the Intune policy shows Succeeded, `MDMWinsOverGP` is confirmed, the legacy GPO is scoped away,
the device is synced and in the correct ring group, and a migrated setting still won't take effect,
collect `GPOM-Validation.ps1` output plus `gpresult /h` and the MDM diagnostics CAB and open a
Microsoft support case.


---


# 7. Best Practices — Group Policy to Intune Settings Migration

- **Measure before you migrate.** Run Group Policy analytics first and let the **readiness %** drive
  the order — migrate high-readiness GPOs early; plan the heavy-unsupported ones carefully.
- **Translate, never guess.** Recreate settings from the analytics mapping and the source GPO value,
  not from memory; confirm each migrated value with `GPOM-Validation.ps1`.
- **Decide precedence up front.** Enable **MDMWinsOverGP** before you cut over so migrated Intune
  settings actually win on hybrid devices — otherwise GPO wins and the work looks broken.
- **One authority per setting.** As each area moves, scope the legacy GPO away from migrated
  devices; never leave the same setting owned by both GPO and Intune long-term.
- **Migrate by ring, gate on parity.** A small **Pilot Ring** proves parity before the **Broad
  Ring** — the single most important safety practice in a migration.
- **Handle the unsupported settings deliberately.** Re-implement (proactive remediation / platform
  script / endpoint security), replace with the modern equivalent, or retire — and record the
  decision in the gap report.
- **Keep your exports and source GPOs.** Retain the GPO XML exports and leave source GPOs
  present-but-unscoped (not deleted) until the broad ring passes — that is your rollback.
- **Name everything to the convention.** Use `<Purpose> – <Scope> – <Stage>` for every policy and
  group so the estate stays auditable and the next admin understands it instantly.
- **Re-run the gap report each wave.** `GPOM-Report.ps1` should trend toward full coverage; chase
  anything that lingers in the gap list.
- **Document the cutover.** Record readiness %, migrated areas, unsupported-setting decisions, and
  the precedence model for audits and repeatability.


---


# 8. Deliverables Summary — Group Policy to Intune Settings Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How GPO and Intune policy differ, Group Policy analytics, settings catalog + imported ADMX, coexistence/precedence, ringed cutover, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, plus the naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: export GPOs, analytics, settings catalog, imported ADMX, handle unsupported, coexistence, ringed cutover |
| 5. Testing Guide | Parity validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GPOM-Discovery.ps1` | Exports/inventories every GPO via the GroupPolicy module (`Get-GPO` / `Get-GPOReport` to XML); flags settings still owned by a live GPO. Read-only. |
| `GPOM-Validation.ps1` | Settings parity — compares source GPO settings against the applied Intune policy and reports `MDMWinsOverGP`. Read-only. |
| `GPOM-Report.ps1` | Migration coverage + gap report (supported vs unsupported, what was migrated, what remains). Read-only. |
| `GPOM-Remediation.ps1` | Safe conflict remediation (`-WhatIf` by default) — resolves conflicting policy / sets MDM-wins precedence. |
| `GPOM-Set-MigrationRingTargeting.ps1` | Builds the migration ring groups (pilot/broad) via Microsoft Graph and seeds membership. |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
A Group Policy estate translated into Intune — supported settings preserved, unsupported settings
handled by design, coexistence managed, and a parity-checked ringed cutover that follows devices on
or off the corporate network.
