# 6. Troubleshooting — Microsoft Purview Center of Excellence

The failure modes that make a Purview **CoE stall, over-reach, or fail its own audit** — plus the
role-group, ownership-stamp, validation, and reconciliation issues you'll hit standing up and running the
operating model. Each: **symptom → likely cause → fix.** The CoE governs the *operating model* (board,
standards, intake, lifecycle); it **never flips a policy to enforce** and makes **no** retention/records/
legal or insider-risk determination — those are deferred. Every write tool previews with `-WhatIf` first.

## `OPSCOE-ScopeCheck.ps1` can't see a capability you intend to govern
- **Cause:** the capability is unlicensed, or portal-only in your tenant (insider risk especially).
- **Fix:** confirm the SKU (Requirement 2.1). If genuinely portal-only, govern it by **attestation** — a
  register row with a named owner and review date — rather than inventing a cmdlet. The gate FAILS only for
  a capability you intend to govern that you also can't see with a correct license/role.

## `OPSCOE-ApplyStandards.ps1 -RoleMatrixCsv` prints `[MISSING] role group`
- **Cause:** the role-group name in the matrix doesn't exist — Purview role-group names **evolve** and many
  tenants use **unified Purview RBAC** with different names.
- **Fix:** verify the current name in **Settings → Roles & scopes → Permissions**; fix the matrix. To create
  a *custom scoped* group deliberately, mark the row `Custom=Yes` (the tool then `New-RoleGroup`s it). Do
  not guess built-in names.

## The preview would add someone to an investigative role
- **Cause:** the matrix grants Insider Risk / Communication Compliance / eDiscovery to a member not named in
  the charter.
- **Fix:** the `[WARN] … INVESTIGATIVE role` line is the gate — **STOP** and confirm the member is named in
  the CoE charter and that separation of duties holds (investigative seats separate from the chair/compliance
  administration seat). Correct the matrix before `-Commit`.

## The ownership stamp changed (or seems to have changed) a policy
- **Cause:** concern that `-StampOwnership` altered a policy's rules/scope/enforcement.
- **Fix:** it does **not** — it writes only the `Comment` field (`CoE-Owner=<name>; Review=<date>`),
  preserving any non-CoE comment text. Re-run `OPSCOE-Discovery.ps1` and confirm every policy's **State**
  is unchanged. **Rollback:** `OPSCOE-ApplyStandards.ps1 -StampOwnership -Restore -Commit` reverts each
  Comment from the saved backup (`OPSCOE-StampBackup.json`).

## Stamp skips a capability with `[SKIP] … cmdlets unavailable`
- **Cause:** that capability is unlicensed or lacks a writable comment surface (`Set-*` cmdlet absent).
- **Fix:** expected behavior — the tool guards `Get-Command` and skips rather than inventing a surface.
  Govern that capability's ownership in the register by attestation instead.

## `OPSCOE-Validate.ps1` reports FAIL on naming
- **Cause:** an artifact doesn't match `<Purpose> – <Capability> – <State>`.
- **Fix:** route the rename through **intake** (renaming is per-object in the portal). Portal-only/attestation
  rows are exempt (reported WARN, not FAIL). Adjust the `namePattern` in `coe-standards.json` only if your
  agreed standard genuinely differs — don't loosen it to hide drift.

## Validate reports FAIL on `EnforceEvidence`
- **Cause:** a high-impact policy (DLP / auto-label / retention) is in an **enforced** state with **no
  recorded simulation/test evidence** in the register.
- **Fix:** this is the core CoE gate. Either record the simulation evidence (`Evidence=`/`SimEvidence` in
  the register Detail) if the pilot genuinely passed, or return the policy to **simulation/test** and take
  it back through intake. The board's target is **enforced-without-evidence = 0**.

## Validate reports FAIL on `Owner` / `ReviewDate`
- **Cause:** the artifact has no owner or no (valid, current) review date.
- **Fix:** assign an owner and a review date — in the register or via an `OPSCOE-ApplyStandards.ps1`
  ownership stamp. An overdue review is a **WARN** (past the cadence in `reviewCadenceDays`); a missing one
  is a **FAIL**. Bring the estate to 100% owned and review-dated.

## Separation-of-duties FAIL on the board matrix
- **Cause:** one member holds **two** investigative roles (or an investigative role plus others without a
  recorded exception).
- **Fix:** remove one membership (`OPSCOE-ApplyStandards.ps1` printed the reverse `Remove-RoleGroupMember`)
  or record a board-accepted exception for a WARN. Insider risk, communication compliance, and eDiscovery
  stay separated from the chair/compliance-administration seat.

## Reconciliation reports `Unregistered` / orphaned live artifacts
- **Cause:** a policy exists in the tenant that isn't in the register — an out-of-band change bypassing
  intake.
- **Fix:** route it through intake — assign an owner, standard name, and review date, and register it; or
  decommission it under change control (identify → confirm owner → disable → remove). This is exactly the
  drift the CoE exists to catch.

## `OPSCOE-Register.ps1` scorecard shows enforced-without-evidence > 0
- **Cause:** the validation output still contains `EnforceEvidence` FAILs.
- **Fix:** remediate each in validation first (record evidence or de-enforce), re-run `OPSCOE-Validate.ps1`,
  then regenerate the scorecard. The scorecard is the board's audit answer — it must show **0** before
  sign-off.

## `Connect-IPPSSession` / `Connect-ExchangeOnline` / `Connect-MgGraph` fails
- **Cause:** module not installed, or MFA/modern-auth not completed.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (+ `Microsoft.Graph`); complete the
  interactive sign-in (Requirement 2.3). The read-only scripts are safe to retry; write tools are `-WhatIf`
  by default.

## When to escalate beyond this solution
- **What a policy should *contain* or *require*** — retention schedules, records file plans, insider-risk
  conditions, regulatory applicability → **compliance, records, privacy, and legal**. The CoE governs the
  operating model; it does not make these determinations.
- **The decision to enforce** → the board, via intake, **after** simulation passes — never a script action.
- **A role group or portal surface that has genuinely changed** → verify against current Microsoft
  documentation; Purview RBAC and the portal evolve, and unified RBAC may be in effect.
