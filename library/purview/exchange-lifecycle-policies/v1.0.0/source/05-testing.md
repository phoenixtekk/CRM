# Testing & Validation — Exchange Lifecycle Policies in Microsoft Purview

Run these gates on the **pilot ring** (`SG-DLCEXO-Pilot`) before expanding scope or enabling any delete
action. Each test has an explicit **PASS / FAIL** signal. A FAIL means **stop, fix, and re-pilot** — do
not widen scope or add a delete action on a failing gate. Because retention **delete is destructive and
has no simulation mode**, the most important gate is **G5: nothing outside scope is touched.**

> Allow for the **Managed Folder Assistant** cycle (roughly daily, best-effort). For MRM tests, trigger
> a pass first: `Start-ManagedFolderAssistant -Identity <pilotMailbox>`. Purview retention can also take
> time to fully apply after a policy is created.

---

## G1. Scope is correct — only pilot mailboxes are in the policy

- **How:** `Get-RetentionCompliancePolicy "DLCEXO-Retention-Exchange-Pilot" | Select ExchangeLocation`
  and confirm it lists **only** the pilot members. `Get-Mailbox <pilotMailbox> | Select RetentionPolicy`
  shows `DLCEXO-MRM-Cleanup-Standard`. Run `DLCEXO-Report.ps1`.
- **PASS:** the Purview policy's ExchangeLocation resolves to pilot members only, and pilot mailboxes
  carry the MRM policy.
- **FAIL:** any non-pilot mailbox appears in scope, or a pilot mailbox is missing the MRM policy.

## G2. Retention rule is configured as designed

- **How:** `Get-RetentionComplianceRule -Policy "DLCEXO-Retention-Exchange-Pilot" | Select Name,
  RetentionDuration, RetentionComplianceAction, ExpirationDateOption`.
- **PASS:** duration, action (`Retain` / `KeepAndDelete` per your approved schedule), and date basis
  match `02-requirements.md` R4 exactly.
- **FAIL:** any value differs from the approved schedule (especially a **delete** action that records/
  legal did not approve).

## G3. Retention preserves mail against user deletion (the "keep" guarantee)

- **How:** In a pilot mailbox, delete a test message and empty Deleted Items (and empty Recoverable
  Items "Deletions" from the client where possible). Confirm via **eDiscovery content search** or
  `Get-MailboxFolderStatistics <pilotMailbox> -FolderScope RecoverableItems` that the item is still
  **preserved** (in Recoverable Items) within the retain period.
- **PASS:** the "deleted" item is still recoverable/preserved — retention overrode the user deletion.
- **FAIL:** the item is gone with an active retain rule → policy not applied yet (allow more time) or
  mis-scoped.

## G4. MRM cleanup ages out the right folders

- **How:** Trigger `Start-ManagedFolderAssistant -Identity <pilotMailbox>`. On a pilot mailbox with a
  message older than the tag age in **Deleted Items** / **Junk Email**, confirm the item is removed
  after the pass; confirm the **MoveToArchive** DPT moved older primary-folder mail into the **archive**
  mailbox (`Get-MailboxFolderStatistics <pilotMailbox> -Archive`).
- **PASS:** aged Deleted Items/Junk are permanently removed; older mail appears in the archive; newer
  mail and other folders are untouched.
- **FAIL:** nothing changed after an MFA pass (check tag age/enabled, archive enabled for MoveToArchive),
  or a folder outside the tag design was affected.

## G5. Blast-radius check — NO mailbox outside the pilot is affected

- **How:** Pick 2–3 **non-pilot** mailboxes. Confirm `Get-Mailbox <nonPilot> | Select RetentionPolicy`
  is **not** `DLCEXO-MRM-Cleanup-Standard`, and that they are **not** in the Purview policy's
  ExchangeLocation. Confirm no cleanup/deletion occurred in them. Run `DLCEXO-Test-Readiness.ps1`.
- **PASS:** non-pilot mailboxes are untouched by both engines.
- **FAIL:** any non-pilot mailbox carries the policy or shows cleanup → **immediately** roll back scope
  (`03-implementation.md`) before continuing.

## G6. Holds are honored (no held mail deleted)

- **How:** For any pilot mailbox on litigation/eDiscovery hold (from `DLCEXO-Discovery.ps1`), confirm
  that mail which would otherwise be deleted by MRM/retention is **still preserved** (holds override
  delete).
- **PASS:** held content is preserved despite delete tags/rules.
- **FAIL:** held content was removed → **stop**, treat as a legal incident, and escalate to legal.

## G7. Readiness gate is green

- **How:** `.\DLCEXO-Test-Readiness.ps1`.
- **PASS:** every check returns **PASS**, or each **GAP** is documented and accepted by records/legal.
- **FAIL:** any unexplained GAP.

---

### Exit criteria (before Expand)
All of **G1–G7 PASS** (or GAPs accepted in writing), evidence exported from `DLCEXO-Report.ps1` and
`DLCEXO-Test-Readiness.ps1`, and records/legal sign-off on record. Only then widen the Purview scope /
add the delete action / broaden the MRM assignment per `03-implementation.md` Phase 5.
