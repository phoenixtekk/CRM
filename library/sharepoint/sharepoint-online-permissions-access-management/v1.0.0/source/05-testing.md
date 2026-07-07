# 5. Testing & Validation

Run these after the pilot remediation (Stage D) and again after each expansion batch. Each test states
the **procedure** and the **expected pass/fail signal**. Run read-only checks with **`SPOPERM-Discovery.ps1`**
and **`SPOPERM-AccessReview.ps1`**; do not use `-Commit` here. Substitute your tenant/site for the
`contoso.sharepoint.com` / `Finance` examples.

---

## Test 1 — Access is group-based at the site root
- **Procedure:** Re-run the audit and inspect the root web's role assignments:
  ```powershell
  .\SPOPERM-Discovery.ps1 -Url https://contoso.sharepoint.com/sites/Finance -CsvPath .\finance-audit-post.csv
  ```
- **Pass:** Every root role assignment is a **SharePoint group** (Owners/Members/Visitors) or a governed
  **Entra/M365 group** — no individual **User** principals (system accounts like the site collection admin
  excepted).
- **Fail:** Any individual user still granted directly at the root → convert them via
  `Group Access Remediation – Finance – Remediation`.

## Test 2 — Standard permission levels are correctly bound
- **Procedure:** `Get-PnPGroupPermissions -Identity "Finance Owners"` (and Members/Visitors).
- **Pass:** `SPO Group – Finance Owners – Prod` = **Full Control**, `...Members...` = **Edit**,
  `...Visitors...` = **Read**. Any custom level in use is exactly `Perm Level – Read No Download – Prod`,
  and **built-in levels are unmodified**.
- **Fail:** A group carries the wrong level, or a built-in level was edited in place → correct the binding
  / recreate the built-in level.

## Test 3 — Broken inheritance reduced to documented exceptions only
- **Procedure:** From the post-remediation audit, count scopes with `HasUniqueRoleAssignments = true` and
  compare against `documented-exceptions.csv` (from `Access Model – SPO – Design`).
- **Pass:** The only scopes with unique permissions are the **documented, owner-approved exceptions**;
  their unique grants are **groups**, not individuals.
- **Fail:** Undocumented broken-inheritance scopes remain → reset them
  (`Inheritance Reset – Finance – Remediation`), or add to the design if genuinely required (owner-approved).

## Test 4 — Limited Access sprawl reduced
- **Procedure:** In the post-remediation audit, count principals whose only level is **Limited Access**.
- **Pass:** Limited Access entries dropped in step with the inheritance resets (Limited Access disappears
  when the underlying sub-scope unique grant is removed).
- **Fail:** Limited Access persists with no corresponding remaining unique grant → find and reset the
  sub-scope (list/folder/item) still holding a unique permission for that principal.

## Test 5 — No unintended over-share
- **Procedure:** In the audit, check for broad principals — **Everyone**, **Everyone except external
  users**, the site **Members** group — holding **Edit** or **Full Control** at the root or on sensitive
  libraries.
- **Pass:** No broad principal holds Edit/Full Control unintentionally; broad read access, if present, is
  intentional and owner-approved.
- **Fail:** A broad principal has more than intended → reduce the level or remove the principal per the
  owner's decision.

## Test 6 — A converted user actually has the right effective access
- **Procedure:** Pick a user converted in Stage D. Confirm group membership
  (`Get-PnPGroupMember -Identity "Finance Members"`), then verify effective access — e.g.
  `Get-PnPUserEffectivePermissions` for the user on the site, or have the user confirm they can still open
  the content they need (and nothing they shouldn't).
- **Pass:** The user's effective permissions match the group's level; they retain intended access via the
  group, with no leftover direct grant.
- **Fail:** Effective access is wrong (too much/too little) → correct group membership; ensure the old
  direct grant was removed.

## Test 7 — Access review is running
- **Procedure:** Confirm the recurring review exists — the Entra ID Access Review `Access Review – Finance
  – Prod` (if P2), the SharePoint site access review (if SAM), or the scheduled
  `SPOPERM-AccessReview.ps1 -Report` job — and that it produced its first output.
- **Pass:** A recurring review/report is configured with the site owner as reviewer/recipient and has run
  at least once.
- **Fail:** No recurring attestation exists → wire it (Stage F) before declaring done.

## Test 8 — The access report reproduces cleanly
- **Procedure:** Run the reporting path end-to-end:
  ```powershell
  .\SPOPERM-AccessReview.ps1 -Url https://contoso.sharepoint.com/sites/Finance -Report -CsvPath .\finance-access.csv
  ```
- **Pass:** `Access Report – SPO – Report` produces a per-principal who-has-access export (group,
  expanded members, level, scope) without errors, suitable for owner attestation.
- **Fail:** The report errors or omits expected principals → check Graph/PnP scopes (Requirements 2, 6)
  and group-expansion permissions.

## Test 9 — Rollback works (pilot only, non-destructive rehearsal)
- **Procedure:** On a **non-production test scope**, confirm you can restore a prior unique grant from the
  `Permission Audit – SPO – Discovery` baseline (re-add the documented group at the scope).
- **Pass:** The prior state is restorable from the baseline export; the rollback procedure is understood
  before any broad-scope `-Commit`.
- **Fail:** No usable before-state → re-capture the audit baseline before proceeding.

---

**Overall gate:** Tests 1–5 and 7–8 **pass** on `Permission Scope – Pilot – Stage1`, Test 6 confirms real
users are unaffected, and Test 9's rollback is understood — before expanding to
`Permission Scope – Broad – Stage2`.
