# Testing & Validation

Run these procedures after the pilot (Stage 4) and again after org-wide expansion (Stage 6). Each has
an explicit **expected pass / fail**. The automated checks are produced by
`app-access-validation.py`; the manual checks confirm the Admin console state.

---

## Test 1 — Inventory completeness

- **Procedure:** Run `python oauth-app-inventory.py --days 180 --out app-inventory.json`. Compare the
  connected-app count to **Admin console → Security → Access and data control → API controls → App
  access control → connected apps**.
- **Expected PASS:** counts match within reporting lag; every HIGH-risk and UNKNOWN-scope app is
  accounted for in the classification.
- **FAIL:** a HIGH-risk app in the console is missing from the inventory, or an UNKNOWN scope is
  untriaged → investigate auth/scopes and re-run before proceeding.

## Test 2 — Gate A: high-risk scopes only held by Trusted apps

- **Procedure:** `python app-access-validation.py --scope <pilot-ou|org> --report validation.json` and
  read the **gate_a** result.
- **Expected PASS:** every app holding a **restricted or sensitive** scope appears on `Trusted Apps –
  Org-Wide – v1`; no Limited/unclassified app holds a sensitive/restricted scope.
- **FAIL:** a non-Trusted app holds a sensitive/restricted scope → reclassify (Trusted after vetting,
  or Blocked) and, if abusive, revoke via Stage 5b; re-run.

## Test 3 — Gate B: unverified/unconfigured apps blocked

- **Procedure:** Read **gate_b** from the validation report; then manually attempt to authorize a
  brand-new, unlisted test app as a pilot user.
- **Expected PASS:** the report shows the unconfigured-app policy set to block (or block from
  sensitive/restricted scopes); the manual authorization of a new unlisted app is **denied** (or
  denied for sensitive scopes) for the pilot user.
- **FAIL:** a new unlisted app obtains sensitive-scope access → confirm `Unverified-App Block –
  Org-Wide – Pilot` is applied to the pilot scope; correct and re-test.

## Test 4 — Gate C: Marketplace allowlist enforced

- **Procedure:** Read **gate_c** from the report; then, as a pilot user, attempt to install a
  Marketplace app that is **not** on `Marketplace Allowlist – Org-Wide – v1`.
- **Expected PASS:** the install policy is **allowlist-only** and the allowlist matches `Trusted Apps
  – Org-Wide – v1`; the non-allowlisted install is **blocked**.
- **FAIL:** a non-allowlisted Marketplace app installs → re-check the Marketplace setting scope and
  the allowlist contents.

## Test 5 — Trusted app still works (no false breakage)

- **Procedure:** As a pilot user, use a **Trusted** app that legitimately needs a sensitive scope
  (e.g. an approved backup/DLP integration).
- **Expected PASS:** the Trusted app authorizes and functions normally — governance did not break a
  vetted app.
- **FAIL:** a Trusted app is denied → confirm it is on `Trusted Apps – Org-Wide – v1` with the correct
  OAuth client ID and that its access level is **Trusted**, not Limited.

## Test 6 — Risky-grant revocation (dry-run vs apply)

- **Procedure:** `python risky-grant-revoker.py --inventory app-inventory.json --risk HIGH --dry-run`,
  review; then (after sign-off) `--apply`.
- **Expected PASS (dry-run):** the tool lists exactly the (user, app) grants it *would* revoke and
  makes **no** change. **PASS (apply):** targeted grants are revoked, an evidence log is written, and a
  re-inventory no longer shows those grants.
- **FAIL:** dry-run lists grants outside the intended risk set, or apply revokes a Trusted app → stop,
  correct the filter/classification, re-run dry-run.

## Test 7 — Vetting workflow enforced for a new app

- **Procedure:** Introduce a hypothetical new third-party app request and run it through
  `App-Vetting Workflow – Org-Wide – v1`; generate the review packet with the report generator.
- **Expected PASS:** the app is not Trusted/allowlisted until the approver signs the review packet;
  the decision is recorded and applied to the correct list.
- **FAIL:** a new app reaches Trusted/allowlist without a recorded decision → the workflow is not being
  followed; reinforce the gate.

---

**Overall exit criterion:** Gates A, B, and C all **PASS** at the target scope (pilot, then org-wide),
no Trusted app is broken (Test 5), risky grants are revoked with evidence (Test 6), and new apps are
gated by the vetting workflow (Test 7).
