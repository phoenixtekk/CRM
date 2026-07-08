# 6. Troubleshooting — Sensitivity Label Taxonomy Design (Microsoft Purview)

Common issues, grouped by step. Each has a **symptom**, the **likely cause**, and a **resolution**.
Every write in `IPTAX-TaxonomyConfig.ps1` is `-WhatIf` by default and only applies with `-Commit`; building
labels does **not** surface them to users (only a policy publish does), and every encrypting label is
piloted in a small ring first. `IPTAX-Discovery.ps1`, `IPTAX-Reporting.ps1`, `IPTAX-ScopeHealth.ps1`, and
`IPTAX-Validation.ps1` are read-only. Portal paths are current at authoring — the portal evolves, so
**verify paths in your tenant**.

## Connectivity & licensing

**Symptom:** `Get-Label` / `New-Label` unavailable.
**Likely cause:** `ExchangeOnlineManagement` not connected, or the Information Protection role is missing.
**Resolution:** `Install-Module ExchangeOnlineManagement`, `Connect-IPPSSession`, and confirm the
Information Protection Admin role. Sensitivity labels require the appropriate compliance licensing — verify
your licensing/tenant.

## Assess & design (Steps 1–2)

**Symptom:** `IPTAX-Discovery.ps1` reports an internal-name **collision** with a planned label.
**Likely cause:** an existing label already uses that internal `Name`.
**Resolution:** choose a different internal name (the `Name` is immutable once created) or retire the old
label first. Internal names must be unique and final before building (Step 2 gate).

**Symptom:** the design sheet isn't signed off but you want to start building.
**Likely cause:** tier count, final names, which tiers encrypt, and the rights model are
**security/compliance/records determinations** (§2.7).
**Resolution:** get the design sheet signed off first — building labels against an unconfirmed design causes
rework (labels can't be freely renamed/deleted once applied).

## Building parents & sublabels (Steps 3–4)

**Symptom:** `IPTAX-TaxonomyConfig.ps1` printed calls but created nothing.
**Likely cause:** `-WhatIf` (the default) — no `-Commit`.
**Resolution:** review the previewed `New-Label` lines against the design sheet, then re-run with `-Commit`
(add `-Sublabels` for Step 4).

**Symptom:** a parent label appears selectable / seems to protect content.
**Likely cause:** a parent grouping label was created with protection or as selectable.
**Resolution:** parents must be **grouping-only** — no encryption, not individually selectable. Rebuild the
parent per the design (parents group; sublabels protect). Confirm with `IPTAX-Validation.ps1`.

**Symptom:** an encrypting sublabel's rights don't target the right people.
**Likely cause:** the rights definition points at the wrong or a non-mail-enabled security group.
**Resolution:** confirm the **mail-enabled security group** named in the mapping (§2.6) exists and is
correct; re-preview with `-WhatIf` before `-Commit`.

## Publishing to the pilot ring (Step 5)

**Symptom:** pilot users don't see the labels.
**Likely cause:** client sync delay, the policy didn't publish to the pilot group, or the user isn't in the group.
**Resolution:** allow time for Office client sync; confirm with `IPTAX-ScopeHealth.ps1 -Group <pilot-group>`
that the group has the intended members and the policy publishes the labels; verify in **Information
Protection → Label policies**.

**Symptom:** a **non-pilot** user sees the labels.
**Likely cause:** the policy scope is broader than the pilot group.
**Resolution:** correct the policy's published scope to the pilot group only; rollback is
`Remove-LabelPolicy "SL Policy - Pilot - Ring1"` (unpublishes without deleting labels).

## Validation & protection (Step 6)

**Symptom:** applying an encrypting sublabel doesn't protect content / everyone can still open it.
**Likely cause:** the protection (Azure Rights Management) service isn't active, or the label isn't actually
encrypting.
**Resolution:** run `IPTAX-ScopeHealth.ps1` — it checks `Get-IRMConfiguration`; if Rights Management
licensing is off, enable it (verify your licensing/tenant). Confirm the label's `EncryptionEnabled` in
`IPTAX-Reporting.ps1`. Test as an unauthorized user → access denied.

**Symptom:** `IPTAX-Reporting.ps1` conformance flags labels that don't match `SL-`.
**Likely cause:** pre-existing labels use a different naming convention.
**Resolution:** decide whether to rename (new label, since `Name` is immutable) or accept legacy names; keep
the taxonomy design sheet as the authority. Use `-ConformanceOnly` for just the conformance view.

## Health: orphans & sprawl (IPTAX-ScopeHealth.ps1)

**Symptom:** a policy shows "publishes NO labels (orphaned)".
**Likely cause:** a label policy exists with no labels attached.
**Resolution:** attach the intended labels or remove the empty policy.

**Symptom:** labels flagged "in no policy (sprawl)".
**Likely cause:** labels were built but never published — expected for **parent grouping** labels, a
problem for a leaf label you meant to publish.
**Resolution:** publish the leaf labels that should be user-visible; parent groupings are intentionally not
individually published/selectable.

## Broad publish (Step 7)

**Symptom:** a ticket flood after broad publish.
**Likely cause:** users were surprised by new marking/encryption.
**Resolution:** communicate what the labels mean and what changes **before** the broad publish reaches users.
Rollback: `Remove-LabelPolicy "SL Policy - Broad - AllUsers"` unpublishes without deleting labels.

## What this solution does NOT decide
The **number of tiers**, the **final names**, **which tiers encrypt**, and the **rights model** are
**security / compliance / records determinations** (design sheet §2.7). This solution designs, builds,
pilots, validates, and publishes the taxonomy per that signed-off design — it does not make the
classification policy determination.
