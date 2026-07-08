# 5. Testing & Validation Guide — Microsoft Purview Center of Excellence

Every governance gate has a **pass/fail** test. Run these after Phase 2 (Configure) and again on every
lifecycle review cycle. Read-only scripts are safe to re-run at any time; nothing here enforces a
policy. Record results on `Purview CoE Lifecycle – Review` and roll the summary into `Purview CoE
Scorecard – Report`.

> **What "pass" means for a governance CoE.** The CoE is validated when the *operating model* holds:
> the board is least-privilege and separated, every governed artifact is named to standard, owned, and
> review-dated, no high-impact policy is enforced without simulation evidence, and the register
> reconciles to the live tenant. The CoE does **not** validate the correctness of a policy's regulatory
> content — that is the stakeholders' determination.

---

## Test 1 — Scope and toolchain (Requirement 2.1–2.4)
**Procedure:** `.\OPSCOE-ScopeCheck.ps1 -UseGraph`
**Pass:** sign-in OK; the in-remit capability list matches the agreed remit; unlicensed/portal-only
capabilities are correctly flagged.
**Fail:** any capability you intend to govern is not visible → resolve licensing/roles (2.1–2.2) and
re-run.

## Test 2 — Estate inventory completeness (Requirement 2.8)
**Procedure:** `.\OPSCOE-Discovery.ps1`
**Pass:** the inventory enumerates every licensed+readable governed capability; portal-only capabilities
are flagged for attestation; the artifact count and non-conforming-name list are recorded.
**Fail:** an in-remit, licensed capability returns no data because of a missing read role → assign the
least-privilege read role and re-run.

## Test 3 — Board least-privilege and separation of duties (Requirement 2.5)
**Procedure:** `Get-RoleGroupMember` for each seat (or re-run `.\OPSCOE-ApplyStandards.ps1 -WhatIf` to
diff intent vs live), and `.\OPSCOE-Validate.ps1` (separation check).
**Pass:** each role group resolves to exactly the named members from the charter; **no** board member
holds both governance administration and an investigative role (insider risk / communication compliance
/ eDiscovery); investigative role membership is minimal and named.
**Fail:** an unexpected member, or a chair/compliance-admin account also in an investigative role →
correct membership via the matrix and re-run `-WhatIf` then `-Commit`.

## Test 4 — Naming-standard conformance (Requirement 2.6)
**Procedure:** `.\OPSCOE-Validate.ps1 -StandardsConfig .\coe-standards.json -Register .\Purview-CoE-Register-Governed.csv`
**Pass:** every governed artifact name matches the standard pattern `<Purpose> – <Capability> –
<State>` (or is on a recorded, board-accepted remediation list).
**Fail:** any non-conforming name not on the remediation list → route through intake to rename
(recreate under the standard; retiring the old artifact via change control) and re-run.

## Test 5 — Ownership and review-date coverage (Requirement 2.6)
**Procedure:** `.\OPSCOE-Validate.ps1` (ownership + review-date checks)
**Pass:** 100% of in-remit artifacts have a named owner (register or stamped `Comment`) and a review
date within the cadence window.
**Fail:** any orphaned (no owner) or overdue artifact → assign an owner / schedule review, or route to
decommission if genuinely orphaned.

## Test 6 — Simulation-first gate (Requirement 2.10, the highest-value test)
**Procedure:** `.\OPSCOE-Validate.ps1` (enforced-without-evidence check) — cross-references each
**enforced** high-impact policy (DLP, auto-labeling, retention, insider risk) against a recorded
simulation-evidence entry.
**Pass:** **zero** enforced high-impact policies lack recorded simulation/test evidence and board
approval.
**Fail:** any enforced policy with no simulation evidence → treat as a governance incident: record it,
have the owner produce/attach evidence retroactively, and add the gap to the board review. (You do not
disable a live control blindly — that itself is a change; route the remediation through intake.)

## Test 7 — Intake gate end-to-end on the pilot (Requirement 2.10)
**Procedure:** Verify `Purview CoE Pilot – Stage1` went Request → simulation → validate → board
approval, with the artifact **in simulation/test** (not enforced) and evidence recorded.
**Pass:** the pilot demonstrates the full gate; the board approval predates any possible enforcement.
**Fail:** any stage skipped (no simulation, no approval record) → the gate is not yet trustworthy;
re-run the pilot correctly before governing the estate.

## Test 8 — Register reconciles to the live tenant (drift)
**Procedure:** `.\OPSCOE-Validate.ps1` (reconciliation) — diffs the register against a fresh
`OPSCOE-Discovery.ps1` run.
**Pass:** no unregistered artifacts in the tenant and no registered artifacts missing from the tenant;
any delta is explained (new intake, approved decommission).
**Fail:** an artifact exists in the tenant but not the register (drift / out-of-band change) → route to
intake and register it; an artifact in the register is gone from the tenant → confirm approved
decommission or investigate.

## Test 9 — Scorecard produced and reconciles (Requirement 2.9)
**Procedure:** `.\OPSCOE-Register.ps1 -Register ... -Validation ...`
**Pass:** `Purview CoE Scorecard – Report` produces counts by capability, % naming-conformant, % owned,
% review-dated, enforced-without-evidence = 0, and a next-review-due list — and the totals reconcile to
the discovery count.
**Fail:** totals do not reconcile → re-run discovery/validation and rebuild before the board review.

---

## Regression / cadence checklist (run every review cycle)
- [ ] Test 1 scope/toolchain — pass
- [ ] Test 2 inventory complete — pass
- [ ] Test 3 board least-privilege + separation — pass
- [ ] Test 4 naming conformance — pass (or remediation list current)
- [ ] Test 5 ownership + review-date coverage 100%
- [ ] Test 6 simulation-first gate — **enforced-without-evidence = 0**
- [ ] Test 7 intake gate proven (pilot / latest change)
- [ ] Test 8 register reconciles (no unexplained drift)
- [ ] Test 9 scorecard produced and reconciles
- [ ] `Purview CoE Lifecycle – Review` + `Purview CoE Scorecard – Report` filed with the board
