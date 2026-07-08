# 5. Testing & Validation Guide — Sensitivity Label Taxonomy Design

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring to broad publish until the relevant tests pass. All
checks use the Purview portal and Security & Compliance PowerShell — the provided scripts automate the
read-only ones.

> **Reminder:** the tier count, names, and protection mapping under test are the security/compliance/
> records determinations from §2 — you are validating that the built taxonomy *matches the signed-off
> design and behaves as specified*, not deciding the scheme.

## Test 1 — Taxonomy built exactly as designed
- **How:** `IPTAX-Validation.ps1 -Full`, or `Get-Label | Sort-Object Priority | Format-Table DisplayName,Name,ParentId,Priority`.
- **Pass:** every label from the signed-off design sheet exists — correct display name, internal `Name`,
  parent link, and **order** (least → most sensitive); no missing or extra labels.
- **Fail:** missing/extra labels, wrong order, or wrong internal name → fix in
  `IPTAX-TaxonomyConfig.ps1` and re-run. **Do not rename an existing internal `Name`** — create the
  correct one and retire the wrong one.

## Test 2 — Parents group only (never protect, never selectable)
- **How:** `IPTAX-Validation.ps1 -Full`; confirm the parent labels (`SL-Confidential`, `SL-HighlyConf`)
  report **no encryption and no marking**, and confirm in Office that a pilot user **cannot select the
  parent directly** — only its sublabels.
- **Pass:** parents carry no protection and are not individually applicable; only sublabels are
  selectable under them.
- **Fail:** a parent applies protection or is selectable → correct the label so the parent is a grouping
  only.

## Test 3 — Content marking appears (marking-only tiers)
- **How:** as a **pilot** user, apply `Public` and `Internal` to test documents and confirm the footer
  text appears as designed.
- **Pass:** the configured footer (e.g. `Internal — do not distribute externally`) appears; no
  encryption is applied to these tiers.
- **Fail:** no marking, wrong text, or unexpected encryption on a marking-only tier → correct the label's
  content-marking settings and re-test.

## Test 4 — Encryption/protection actually enforces (protecting sublabels)
- **How:** as a pilot user, apply `Confidential \ Trusted People` (or `Highly Confidential \ Specified
  People`) to a test document; attempt to open it as a user **outside** the rights group.
- **Pass:** the unauthorized user is **denied**; the authorized rights (Co-Author vs Reviewer vs
  Viewer/no-export) behave as the mapping defines; the watermark/footer appears where configured.
- **Fail:** unauthorized access succeeds, or rights are wrong → the protection service or the label's
  `EncryptionRightsDefinitions` is misconfigured (§2.6). **Do not publish broadly** until fixed.

## Test 5 — Naming convention conformance
- **How:** `IPTAX-Reporting.ps1 -ConformanceOnly` (or review the conformance column in the full report).
- **Pass:** every internal `Name` matches the `SL-<Tier>[-<Audience>]` convention; display names and
  order match the design; no legacy/ad-hoc labels break the scheme in the published set.
- **Fail:** non-conforming names or stray labels → reconcile with the design sheet; retire non-conforming
  labels rather than renaming them.

## Test 6 — Pilot scoping is correct
- **How:** as a **pilot** user, confirm the full taxonomy appears in Office; as a **non-pilot** user,
  confirm **no** labels appear. `Get-LabelPolicy "SL Policy - Pilot - Ring1"` shows the pilot group.
- **Pass:** pilot users see the full ordered label set; non-pilot users see nothing (publish is scoped).
- **Fail:** labels missing for pilot users (allow client sync time) or visible to non-pilot users (policy
  scope wrong) → re-check `SL Policy - Pilot - Ring1` targeting.

## Test 7 — Tooltips are present and plain-language
- **How:** in Office, hover each label as a pilot user; or `Get-Label | Format-Table DisplayName,Tooltip`.
- **Pass:** every selectable label has a plain-language tooltip that states what it means and gives a
  handling instruction — the only in-context help a user gets.
- **Fail:** missing or jargon tooltips → set a clear tooltip per label and re-publish.

## Test 8 — Full health check before broad publish
- **How:** `IPTAX-Validation.ps1 -Full`.
- **Pass:** structure/order/protection == design, naming conformant, tooltips present, pilot policy scoped
  correctly — all green.
- **Fail:** any red → resolve before publishing `SL Policy - Broad - AllUsers`.

---
### Exit criteria (all must be true before broad publish)
`Taxonomy built as designed · parents group-only · marking visible · encryption enforces · naming conformant · pilot scope correct · tooltips present · full health check green · rollback documented per policy`
