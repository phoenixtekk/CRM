# 2. Requirements Guide — AppLocker to WDAC (App Control for Business) Migration

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-migrations.md`.

## 2.1 Intune licensing and admin rights
Description: An Intune-bearing license plan (Microsoft 365 E3/E5, Business Premium, or standalone
Intune Plan 1) and the Intune Administrator role. WDAC itself is a free Windows feature.
Why: Intune authors and assigns the WDAC audit/enforce policies and the migration-ring groups.
Verify: `https://intune.microsoft.com` loads; Tenant administration to Tenant status is active; you
hold Intune Administrator.
Implement: Assign an Intune-bearing plan and grant least-privilege admin roles.

## 2.2 Devices enrolled in Intune
Description: The in-scope Windows devices are enrolled in Intune.
Why: WDAC policies and ring assignments apply only to enrolled devices.
Verify: Intune to Devices to All devices; run `WDACMIG-Discovery.ps1`.
Implement: Enable automatic enrollment; enroll the in-scope devices.

## 2.3 Supported Windows OS
Description: Windows 10 1903+ or Windows 11 (Pro/Enterprise/Education). Windows 11 adds `citool` for
local policy inspection.
Why: App Control for Business policy deployment and the Code Integrity audit log require a supported
build.
Verify: `winver`; run `WDACMIG-Discovery.ps1` (reports OS support verdict).
Implement: Patch/upgrade to a supported build before migrating that device.

## 2.4 The existing AppLocker policy export (the migration source)
Description: A current export of the in-force AppLocker policy from the devices being migrated.
Why: The WDAC policy is translated from what AppLocker currently allows; without the export you
cannot guarantee parity and risk locking out apps AppLocker permitted.
Verify: Run `WDACMIG-Discovery.ps1` (captures the effective AppLocker policy and rule collections),
or `Get-AppLockerPolicy -Effective -Xml` on a representative device.
Implement: Export the effective AppLocker policy from representative devices in each ring before
authoring WDAC.

## 2.5 A WDAC authoring approach
Description: A decided method for producing the WDAC base policy — the Intune App Control for Business
profile (built-in trust: Windows + Store + managed installer + optional ISG) for most fleets, with
the WDAC Wizard or `New-CIPolicy` for any custom signer/hash rules carried over from AppLocker.
Why: You must produce a concrete policy artifact to deploy in audit mode; the built-in Intune profile
covers the common case, custom policy covers carried-over AppLocker specifics.
Verify: You can open Intune to Endpoint security to App Control for Business and create a policy, and
(if needed) you have the WDAC Wizard installed for custom XML.
Implement: Use the Intune built-in profile for trust; author supplemental/custom XML only for apps
not covered by managed installer or ISG.

## 2.6 Managed installer (recommended trust path)
Description: Intune configured as a managed installer so apps deployed through Intune are
automatically trusted by WDAC.
Why: The managed installer is the lowest-maintenance way to keep business apps allowed after
enforcement, replacing AppLocker's brittle path/publisher rules.
Why it matters for migration: apps AppLocker allowed by path are best re-trusted by redeploying them
through Intune under the managed installer rather than re-creating path rules in WDAC.
Verify: Intune to Endpoint security to App Control for Business — the managed installer setting is
enabled; `WDACMIG-Discovery.ps1` reports managed-installer tagging where present.
Implement: Enable the managed installer in the App Control for Business settings and deploy
line-of-business apps through Intune.

## 2.7 Migration rings and pilot group
Description: Microsoft Entra security groups for the migration rings, named per the naming convention
below, with a pilot ring populated first.
Why: Enforcement is rolled out in rings (pilot to broad) so a too-strict policy is caught on a small
group before the fleet.
Verify: Entra to Groups; the ring groups exist; `WDACMIG-Set-MigrationRingTargeting.ps1` can populate
them. Run `WDACMIG-Report.ps1` to confirm ring coverage.
Implement: Create the ring groups (see naming) and add pilot devices first.

## 2.8 Change control, coexistence, and rollback
Description: A change window, the documented AppLocker/WDAC coexistence plan (AppLocker stays in force
until WDAC enforcement is validated per ring), and a rollback (unassign WDAC enforce, revert to
audit) before any enforcement.
Why: Enforcement touches live production devices; cutover must be reversible and coordinated.
Verify: A rollback procedure and coexistence plan are written and approved before Step 8 (enforce).
Implement: Define the audit-to-enforce gate, the per-ring rollback, and the order coexistence to
enforce to AppLocker retirement.

---
## Naming convention (name every artifact `<Purpose> – <Scope> – <Stage>`; reuse verbatim)
| Artifact | Name |
|---|---|
| WDAC base policy | `App Control – Migrated from AppLocker – Base` |
| Audit profile (Intune) | `App Control – Fleet – Audit` |
| Enforce profile (Intune) | `App Control – Fleet – Enforce` |
| Pilot ring group | `App Control Migration – Pilot – Ring 1` |
| Broad ring group | `App Control Migration – Broad – Ring 2` |
| Fleet ring group | `App Control Migration – Fleet – Ring 3` |

---
## Checklist
- [ ] Intune licensing + Intune Administrator
- [ ] Devices enrolled
- [ ] Windows 10 1903+ / Windows 11 — `WDACMIG-Discovery.ps1`
- [ ] Effective AppLocker policy exported — `WDACMIG-Discovery.ps1`
- [ ] WDAC authoring approach decided
- [ ] Managed installer enabled; LOB apps via Intune
- [ ] Migration ring groups created (Pilot / Broad / Fleet)
- [ ] Coexistence + audit-to-enforce gate + rollback approved
