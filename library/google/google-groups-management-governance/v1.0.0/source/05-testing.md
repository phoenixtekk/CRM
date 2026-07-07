# 5. Testing & Validation

Each test states **what to run**, the **expected result**, and the **pass/fail** signal. Tests map to
the gates in Section 3. Run the read-only tests any time; run write-verification tests after a change
window. Reference the named artifacts (`Pilot OU – Groups – Finance`, `sec-groups-owners@corp.example`,
etc.) from the Implementation Guide.

---

## Test 1 — Baseline captured (Gate 0)
- **Run:** `python groups_inventory_hygiene_assessment.py --domain corp.example --json > baseline-groups.json`
  and confirm the Admin-console settings from Step 0.2 are recorded.
- **Expect:** a JSON baseline with per-category counts (ORPHANED / STALE / EXTERNAL-EXPOSED /
  OVER-PERMISSIONED / NAMING-NONCONFORMANT) and the recorded rollback settings.
- **Pass:** baseline artifact + recorded settings both exist. **Fail:** either missing — do not proceed.

## Test 2 — Org-wide baseline configured (Gate 2)
- **Run:** `python groups_settings_policy_helper.py check-baseline --domain corp.example`
- **Expect:** group creation restricted, default access restrictive, **allow external members = off** at
  org default, inbound external posting restricted, and `sec-groups-owners@corp.example` exists as a
  security group.
- **Pass:** all five report OK (exit 0). **Fail:** any item non-compliant (exit 1) — fix in Stage 2
  before piloting.

## Test 3 — Naming & type conformance (Gates 3/4)
- **Run:** `python groups_naming_type_validator.py --domain corp.example --scope finance`
- **Expect:** every pilot group's display name and email prefix match `<Type> – <Scope> – <Purpose>` /
  `dl-`/`sec-`/`collab-`/`dyn-`/`ext-`, and its settings match the declared type's policy row.
- **Pass:** **zero** drift findings (exit 0). **Fail:** any nonconformant name/prefix/type (exit 1) —
  rename/re-type in Step 3.1/3.2.

## Test 4 — Membership & external-exposure policy (Gates 3/4)
- **Run:** `python groups_membership_external_policy_checker.py --domain corp.example --scope finance`
- **Expect:** no external members on any non-`ext-` group; no group with public join/post/view settings
  outside its type policy; no `sec-*` access group with over-open settings (e.g. `ALL_IN_DOMAIN_CAN_POST`).
- **Pass:** **zero** out-of-policy findings (exit 1 is used as a gate signal when findings exist).
  **Fail:** any finding — remediate in Step 3.6 (external) / 3.2 (settings).

## Test 5 — Ownership & no-orphan (Gates 3/4)
- **Run:** re-run `groups_inventory_hygiene_assessment.py --domain corp.example` filtered to the pilot
  scope; inspect ORPHANED and owner-count.
- **Expect:** every pilot group has **≥2 owners** including `sec-groups-owners@corp.example`; **zero
  ORPHANED**.
- **Pass:** no orphaned/single-owner groups in scope. **Fail:** any — fix in Step 3.5.

## Test 6 — Stale-group hygiene
- **Run:** the same assessment; inspect the STALE list for the pilot scope.
- **Expect:** no group flagged STALE (empty / no recent activity beyond the threshold) that is **not**
  already ticketed for staged retirement.
- **Pass:** stale list empty **or** every stale group has a retirement ticket. **Fail:** an untracked
  stale group — start Stage 5 retirement.

## Test 7 — Dynamic membership correctness
- **Run:** compare the computed membership of `dyn-finance-all@corp.example` against the expected set
  (e.g. the directory query for `department=Finance`).
- **Expect:** computed membership equals the expected attribute-derived set (allowing for sync latency).
- **Pass:** membership matches. **Fail:** mismatch — check the CEL query and the source attributes
  (Requirement 2.4) before retiring the static equivalent.

## Test 8 — Security-group access re-point
- **Run:** confirm access previously granted via a repurposed group now flows through the Cloud Identity
  **security group** from Step 3.3 (check a Shared Drive membership / IAM binding).
- **Expect:** access is granted **only** via the security group; the old grant is removable without loss.
- **Pass:** access verified via the security group. **Fail:** access still depends on the old group — do
  not remove it yet.

## Test 9 — Lifecycle review report generation
- **Run:** `python groups_lifecycle_review_report.py --domain corp.example --scope finance --out
  pilot-review.html`
- **Expect:** `Review Report – Finance – Pilot` listing each group with type, owner group, member count,
  external count, last-activity, and next-review date for owner attestation.
- **Pass:** report generated and owners can attest. **Fail:** report empty/errors — check API scopes
  (Requirement 2.6).

## Test 10 — Rollback rehearsal (high-impact changes)
- **Run:** in the change window, revert one representative change (re-open a setting to the Step 0.2
  value, or re-add a removed external member from the baseline record), confirm the group behaves as
  before, then re-apply the governed setting.
- **Expect:** rollback restores prior behaviour cleanly; re-apply restores the governed state.
- **Pass:** both directions work. **Fail:** rollback doesn't restore mail flow/access — investigate
  before expanding (Section 6).
