# 2. Requirements Guide — Windows Firewall GPO to Intune Migration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-migrations.md`
(target tenant, Intune licensing/admin, source-platform access, inventory, enrollment, pilot/wave
structure, change control + coexistence + rollback) — confirm those first.

## 2.1 Intune endpoint-security admin access
**Description:** Rights to create and assign `Endpoint security` → `Firewall` policies in Intune.
**Why:** The migration target is an Intune firewall policy and firewall rule profiles; you cannot
build them without these rights.
**Verify:** `https://intune.microsoft.com` → `Endpoint security` → `Firewall` loads and `Create Policy`
is available; you hold **Intune Administrator** or **Endpoint Security Manager**.
**Implement:** Assign the Intune/Endpoint Security admin role (least privilege) to the migrator.

## 2.2 Source GPO firewall rule access and export
**Description:** Read access to the Group Policy Object(s) that configure Windows Defender Firewall
profiles and rules for the in-scope devices.
**Why:** The migration begins by inventorying exactly what GPO enforces so it can be translated.
**Verify:** In Group Policy Management you can open the GPO and see
`Computer Configuration` → `Windows Settings` → `Security Settings` →
`Windows Defender Firewall with Advanced Security`; or run `FWMIG-Discovery.ps1` on a domain-joined
in-scope device (it exports GPO + applied firewall rules, read-only).
**Implement:** Obtain delegated read on the firewall GPO(s) from the AD/GPO owner.

## 2.3 Targeted devices enrolled in Intune
**Description:** In-scope devices enrolled in Intune (co-managed or Intune-managed).
**Why:** A `Firewall Policy` and `Firewall Rules` profiles apply only to enrolled devices.
**Verify:** Intune → `Devices` → `All devices` shows the in-scope devices.
**Implement:** Enable automatic enrollment / co-management; enroll the devices.

## 2.4 Supported Windows OS and MDM firewall CSP
**Description:** Windows 10/11 (Pro/Enterprise/Education) that supports the Firewall configuration
service provider Intune uses.
**Why:** Intune firewall policy and rules require a supported build to apply.
**Verify:** `winver` on a sample device; run `FWMIG-Discovery.ps1` (reports OS build).
**Implement:** Patch/upgrade devices to a supported build before migrating them.

## 2.5 A documented GPO firewall rule inventory (source of truth)
**Description:** An accurate export of the GPO firewall profile defaults and every explicit rule for
the migration scope.
**Why:** Parity validation and GPO retirement depend on knowing exactly what is in scope.
**Verify:** You can produce a rule export (CSV/JSON) from `FWMIG-Discovery.ps1` and
`FWMIG-Report.ps1`.
**Implement:** Run `FWMIG-Discovery.ps1` across a representative device set to build the inventory
before scoping rings.

## 2.6 Coexistence control — one firewall authority per device
**Description:** A defined approach so that, for any device, GPO **or** Intune enforces the firewall —
never both at once on the same settings.
**Why:** Two authorities on the same firewall settings cause conflicts and merge loops (Overview).
**Verify:** For each ring you can both remove devices from GPO firewall scope and add them to the
Intune ring group at the same change step; run `FWMIG-Report.ps1` to flag devices currently double-managed.
**Implement:** Use a security-group-filtered GPO (deny-apply or remove from OU scope) keyed to the
same membership the ring group uses, so moving a device flips authority atomically.

## 2.7 Migration ring groups (pilot + waves)
**Description:** Entra security groups for `Migration Ring – Pilot`, `Migration Ring – Wave 1`, and
`Migration Ring – Broad`.
**Why:** The firewall is cut over in rings with a parity gate between each; connectivity risk demands it.
**Verify:** Entra → `Groups`; the three groups exist (or run `FWMIG-Set-MigrationRingTargeting.ps1`
to create/populate them).
**Implement:** Create the groups (`FWMIG-Set-MigrationRingTargeting.ps1` or Entra →
`Groups` → `New group` → Security).

## 2.8 Change control + rollback (connectivity-aware)
**Description:** A change window and a written rollback (re-scope the device to GPO firewall / unassign
the Intune policy) for each ring, because the firewall affects connectivity.
**Why:** A bad rule translation can block management or LOB traffic; cutover must be reversible.
**Verify:** A rollback procedure is written and approved before any ring cutover.
**Implement:** Define per-ring rollback, comms, and the order coexistence → cutover → retire (see §G7
of the global requirements).

---
## Checklist
- [ ] Intune endpoint-security admin access
- [ ] Source GPO firewall rules readable / exportable — `FWMIG-Discovery.ps1`
- [ ] In-scope devices enrolled in Intune
- [ ] Supported Windows build (firewall CSP) — `FWMIG-Discovery.ps1`
- [ ] GPO firewall rule inventory captured — `FWMIG-Report.ps1`
- [ ] Coexistence control (one authority per device) defined
- [ ] `Migration Ring – Pilot` / `Wave 1` / `Broad` groups created
- [ ] Change control + connectivity-aware rollback approved
