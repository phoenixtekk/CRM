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
