# 5. Testing Guide — Azure RMS / AIP → Built-in Unified Labeling Migration

Run after building the inventory and after each configuration step, and again after the pilot cutover.
Every test is safe (read-only, a `-WhatIf` preview, or a controlled user action on the pilot ring).
Validate on `AIP Migration Pilot Ring – Stage1` before expanding tenant-wide.

## Test 1 — Inventory is complete and matches the portal
**Do:** Run `IPRMSMIG-Assess-Migration.ps1`; compare its labels, label policies, and RMS templates
against **Information Protection → Sensitivity labels / Label policies** in the Purview portal and
`Get-AipServiceTemplate`.
**Expected:** Every label, policy (with its advanced settings), and RMS/protection template in the portal
appears in `AIP/RMS Inventory – Migration – Assess`; nothing is stranded in a classic-only location.

## Test 2 — Azure RMS is activated and recoverable
**Do:** Run `IPRMSMIG-Scope-Health.ps1`.
**Expected:** `FunctionalState` reports `Enabled`; the super-user feature state and named recovery
account(s) are reported. Protection can apply and encrypted content is recoverable.

## Test 3 — Label-policy settings dry-run makes no changes
**Do:** Run `IPRMSMIG-Set-LabelPolicy.ps1 -PolicyName '<policy>' -SettingsPath .\parity.json -WhatIf`;
afterward run `Get-LabelPolicy -Identity '<policy>'`.
**Expected:** The dry-run lists each advanced setting it would apply and prints the prior/reverse value;
the policy's advanced settings are unchanged — `-WhatIf` truly changed nothing.

## Test 4 — Parity settings resolve after commit
**Do:** After `-Commit` on the pilot policy, run `Get-LabelPolicy -Identity '<pilot policy>'` (or re-run
`IPRMSMIG-Assess-Migration.ps1`).
**Expected:** The pilot policy shows exactly the intended advanced settings from
`Built-in Labeling Parity – Design` (e.g. default Outlook label, mandatory posture, custom-permissions
availability — verified against current key names); no unrelated setting changed.

## Test 5 — Every label resolves for a pilot user
**Do:** Run `IPRMSMIG-Test-Parity.ps1 -UserUpn <pilot user> -OfficeBuild '<build>'`.
**Expected:** The pilot user's effective label set matches the add-in label list; no expected label is
missing; the script flags any parity feature that needs a newer Office build than the one supplied.

## Test 6 — Built-in labeling is active and the add-in is gone (ring)
**Do:** On a pilot-ring device after the cutover, open Word/Excel/PowerPoint/Outlook and check the
ribbon.
**Expected:** The **Sensitivity** button (built-in labeling) is present, the expected labels appear in
order, and the **Azure Information Protection** add-in is no longer loaded.

## Test 7 — Encryption and custom permissions behave as before (ring)
**Do:** On the ring, apply an encrypting label (and a custom-permissions label if used) to a test
document/email; open it as an authorized and an unauthorized user.
**Expected:** Protection applies with the same permissions as the add-in did; authorized users open it,
unauthorized users are denied; a departmental-template scenario is reproduced by its mapped label.

## Test 8 — Content protected by the old add-in / templates still opens
**Do:** Open documents/emails that were protected **before** the migration (add-in labels and departmental
RMS templates) on a migrated ring device.
**Expected:** Previously protected content opens with the correct permissions — the migration preserved
access; if not, RMS super-user recovery is available and the mapping is corrected before expanding.

## Test 9 — Parity report shows no open protection gap
**Do:** Run `IPRMSMIG-Report-Migration.ps1 -CsvPath .\MigrationStatus.csv`; review
`Migration Validation – Report`.
**Expected:** Every parity row passes on the ring, or an open gap has a recorded owner decision; **no**
encryption/protection row is failing when you decide to expand.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–9 pass on `AIP Migration Pilot Ring – Stage1`: estate inventoried, RMS activated + recoverable, parity settings applied, labels resolve, built-in labeling active with the add-in gone, encryption/templates reproduced, old protected content opens, no open protection gap |
| **Expand pass** | Tests 3–9 pass again for each subsequent ring as the Office client policy broadens tenant-wide, with RMS recovery available — until the full population is on built-in labeling and the add-in is decommissioned |
